import AppKit
import SwiftUI

struct OnboardingRootView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onPreferredContentHeightChange: (CGFloat) -> Void
    @State private var measuredContentHeight: CGFloat = 0
    
    init(viewModel: OnboardingViewModel, onPreferredContentHeightChange: @escaping (CGFloat) -> Void) {
        self.viewModel = viewModel
        self.onPreferredContentHeightChange = onPreferredContentHeightChange
    }
    
    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
            
            content
                .padding(.horizontal, 28)
                .padding(.vertical, 32)
                .frame(width: OnboardingWindowMetrics.contentWidth, alignment: .leading)
                .background(contentHeightReader)
        }
        .fixedSize(horizontal: false, vertical: true)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            viewModel.handleDidBecomeActive()
        }
        .onAppear {
            notifyPreferredContentHeight()
            // SwiftUI's first layout pass can under-measure the onboarding content.
            // Re-check on the next run loop so the window expands to the settled size
            // before the user has to interact with it.
            DispatchQueue.main.async {
                notifyPreferredContentHeight()
            }
        }
        .onChange(of: viewModel.step) { _, _ in
            notifyPreferredContentHeight()
            // Step transitions can change both the preferred baseline and the measured
            // content size in separate layout passes, so we intentionally request a
            // second update after the view tree settles.
            DispatchQueue.main.async {
                notifyPreferredContentHeight()
            }
        }
        .onChange(of: viewModel.permissionState) { _, _ in
            notifyPreferredContentHeight()
            // Permission banners can appear/disappear asynchronously after AppKit
            // notifies the app, so mirror the delayed re-measure here as well.
            DispatchQueue.main.async {
                notifyPreferredContentHeight()
            }
        }
        .onPreferenceChange(OnboardingContentHeightPreferenceKey.self) { measuredHeight in
            guard measuredHeight > 0 else { return }
            measuredContentHeight = measuredHeight
            notifyPreferredContentHeight()
        }
    }

    private func notifyPreferredContentHeight() {
        onPreferredContentHeightChange(max(viewModel.preferredContentHeight, measuredContentHeight))
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            OnboardingHeaderView(
                title: headerTitle,
                subtitle: headerSubtitle,
                progressText: viewModel.progressText,
                showsBackButton: viewModel.showsBackButton,
                backAction: viewModel.goBack
            )
            
            currentStepView
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            
            footerView
        }
    }
    
    private var contentHeightReader: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(key: OnboardingContentHeightPreferenceKey.self, value: proxy.size.height)
        }
    }
    
    private var headerTitle: String {
        switch viewModel.step {
        case .welcome:
            localizedAppString("onboarding.welcome.header", defaultValue: "Welcome to NudgeWhip")
        case .permission:
            localizedAppString("onboarding.permission.header", defaultValue: "Accessibility permission")
        case .basicSetup:
            localizedAppString("onboarding.setup.header", defaultValue: "Set your starting defaults")
        case .scheduleSetup:
            localizedAppString("onboarding.schedule.header", defaultValue: "Choose your monitoring hours")
        case .completionReady:
            localizedAppString("onboarding.completion.ready.header", defaultValue: "Ready to go")
        case .completionLimited:
            localizedAppString("onboarding.completion.limited.header", defaultValue: "Limited mode")
        }
    }
    
    private var headerSubtitle: String {
        switch viewModel.step {
        case .welcome:
            localizedAppString("onboarding.welcome.subtitle", defaultValue: "Set up NudgeWhip once, then stay in the menu bar.")
        case .permission:
            viewModel.permissionState == .granted
                ? localizedAppString("onboarding.permission.subtitle.granted", defaultValue: "Permission is already granted. Continue to finish your first-run setup.")
                : localizedAppString("onboarding.permission.subtitle", defaultValue: "Allow background input detection so NudgeWhip can detect idle moments.")
        case .basicSetup:
            localizedAppString("onboarding.setup.subtitle", defaultValue: "Choose the defaults for your first sessions.")
        case .scheduleSetup:
            localizedAppString("onboarding.schedule.subtitle", defaultValue: "Set the hours when NudgeWhip should actively monitor and nudge.")
        case .completionReady:
            localizedAppString("onboarding.completion.ready.subtitle", defaultValue: "Your first-run setup is complete.")
        case .completionLimited:
            localizedAppString("onboarding.completion.limited.subtitle", defaultValue: "You can continue now and grant permission later.")
        }
    }
    
    @ViewBuilder
    private var currentStepView: some View {
        switch viewModel.step {
        case .welcome:
            WelcomeStepView()
        case .permission:
            PermissionStepView(permissionState: viewModel.permissionState)
        case .basicSetup:
            BasicSetupStepView(
                idleThresholdSeconds: $viewModel.idleThresholdSeconds,
                launchAtLoginEnabled: $viewModel.launchAtLoginEnabled,
                countdownOverlayEnabled: $viewModel.countdownOverlayEnabled,
                preferredLanguage: $viewModel.preferredLanguage
            )
        case .scheduleSetup:
            ScheduleSetupStepView(
                scheduleEnabled: $viewModel.scheduleEnabled,
                scheduleStartTime: Binding(
                    get: { dateFromSeconds(viewModel.scheduleStartSecondsFromMidnight) },
                    set: { viewModel.scheduleStartSecondsFromMidnight = secondsFromMidnight(for: $0) }
                ),
                scheduleEndTime: Binding(
                    get: { dateFromSeconds(viewModel.scheduleEndSecondsFromMidnight) },
                    set: { viewModel.scheduleEndSecondsFromMidnight = secondsFromMidnight(for: $0) }
                )
            )
        case .completionReady:
            CompletionReadyStepView(
                idleThresholdText: idleThresholdText,
                scheduleText: scheduleText,
                launchAtLoginText: toggleText(viewModel.launchAtLoginEnabled),
                overlayText: toggleText(viewModel.countdownOverlayEnabled),
                languageText: viewModel.preferredLanguage.displayName
            )
        case .completionLimited:
            CompletionLimitedStepView()
        }
    }
    
    @ViewBuilder
    private var footerView: some View {
        switch viewModel.step {
        case .welcome:
            welcomeFooter
        case .permission:
            permissionFooter
        case .basicSetup:
            basicSetupFooter
        case .scheduleSetup:
            scheduleSetupFooter
        case .completionReady:
            completionReadyFooter
        case .completionLimited:
            completionLimitedFooter
        }
    }
    
    private var welcomeFooter: some View {
        OnboardingFooterView(
            primaryTitle: localizedAppString("onboarding.welcome.cta.continue", defaultValue: "Get Started"),
            primaryAction: viewModel.continueFromWelcome,
            secondaryTitle: nil,
            secondaryAction: nil,
            tertiaryTitle: nil,
            tertiaryAction: nil
        )
    }
    
    private var permissionFooter: some View {
        let isGranted = viewModel.permissionState == .granted
        
        if isGranted {
            return AnyView(
                OnboardingFooterView(
                    primaryTitle: localizedAppString("onboarding.setup.cta.continue", defaultValue: "Continue"),
                    primaryAction: viewModel.continueFromPermission,
                    secondaryTitle: nil,
                    secondaryAction: nil,
                    tertiaryTitle: nil,
                    tertiaryAction: nil
                )
            )
        } else {
            return AnyView(
                OnboardingFooterView(
                    primaryTitle: localizedAppString("onboarding.permission.cta.request", defaultValue: "Request Access"),
                    primaryAction: viewModel.requestPermission,
                    secondaryTitle: localizedAppString("onboarding.permission.cta.open_settings", defaultValue: "Open Settings"),
                    secondaryAction: { _ = viewModel.openAccessibilitySettings() },
                    tertiaryTitle: localizedAppString("onboarding.permission.cta.later", defaultValue: "Set Up Later"),
                    tertiaryAction: viewModel.setUpLater
                )
            )
        }
    }
    
    private var basicSetupFooter: some View {
        OnboardingFooterView(
            primaryTitle: localizedAppString("onboarding.setup.cta.continue", defaultValue: "Continue"),
            primaryAction: viewModel.continueFromBasicSetup,
            secondaryTitle: nil,
            secondaryAction: nil,
            tertiaryTitle: nil,
            tertiaryAction: nil
        )
    }
    
    private var scheduleSetupFooter: some View {
        OnboardingFooterView(
            primaryTitle: localizedAppString("onboarding.schedule.cta.continue", defaultValue: "Continue"),
            primaryAction: viewModel.continueFromScheduleSetup,
            secondaryTitle: nil,
            secondaryAction: nil,
            tertiaryTitle: nil,
            tertiaryAction: nil
        )
    }
    
    private var completionReadyFooter: some View {
        OnboardingFooterView(
            primaryTitle: localizedAppString("onboarding.completion.ready.cta.finish", defaultValue: "Start in Menu Bar"),
            primaryAction: viewModel.finish,
            secondaryTitle: nil,
            secondaryAction: nil,
            tertiaryTitle: nil,
            tertiaryAction: nil
        )
    }
    
    private var completionLimitedFooter: some View {
        OnboardingFooterView(
            primaryTitle: localizedAppString("onboarding.completion.limited.cta.finish", defaultValue: "Continue in Limited Mode"),
            primaryAction: viewModel.finish,
            secondaryTitle: localizedAppString("onboarding.completion.limited.cta.retry", defaultValue: "Open System Settings"),
            secondaryAction: { _ = viewModel.openAccessibilitySettings() },
            tertiaryTitle: nil,
            tertiaryAction: nil
        )
    }
    
    private var idleThresholdText: String {
        return localizedDurationString(TimeInterval(viewModel.idleThresholdSeconds))
            ?? "\(viewModel.idleThresholdSeconds)s"
    }
    
    private var scheduleText: String {
        guard viewModel.scheduleEnabled else {
            return localizedAppString("menu.dropdown.value.schedule.off", defaultValue: "Off")
        }
        return "\(formattedClock(dateFromSeconds(viewModel.scheduleStartSecondsFromMidnight))) - \(formattedClock(dateFromSeconds(viewModel.scheduleEndSecondsFromMidnight)))"
    }
    private func toggleText(_ isOn: Bool) -> String {
        isOn
            ? localizedAppString("onboarding.common.toggle.on", defaultValue: "On")
            : localizedAppString("onboarding.common.toggle.off", defaultValue: "Off")
    }
    
    private func dateFromSeconds(_ seconds: Int) -> Date {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return startOfDay.addingTimeInterval(TimeInterval(seconds))
    }
    
    private func secondsFromMidnight(for date: Date) -> Int {
        let calendar = Calendar.current
        return calendar.component(.hour, from: date) * 3600
            + calendar.component(.minute, from: date) * 60
    }
    
    private func formattedClock(_ date: Date) -> String {
        localizedClockString(date)
    }
}

private struct OnboardingContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
