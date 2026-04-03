import AppKit
import SwiftUI

struct OnboardingRootView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack {
                    OnboardingCardView {
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
                .frame(maxWidth: .infinity, minHeight: 540, alignment: .center)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            viewModel.handleDidBecomeActive()
        }
    }
    
    private var headerTitle: String {
        switch viewModel.step {
        case .welcome:
            localizedAppString("onboarding.welcome.header", defaultValue: "Welcome to Nudge")
        case .permission:
            localizedAppString("onboarding.permission.header", defaultValue: "Accessibility permission")
        case .basicSetup:
            localizedAppString("onboarding.setup.header", defaultValue: "Set your starting defaults")
        case .completionReady:
            localizedAppString("onboarding.completion.ready.header", defaultValue: "Ready to go")
        case .completionLimited:
            localizedAppString("onboarding.completion.limited.header", defaultValue: "Limited mode")
        }
    }
    
    private var headerSubtitle: String {
        switch viewModel.step {
        case .welcome:
            localizedAppString("onboarding.welcome.subtitle", defaultValue: "Set up Nudge once, then stay in the menu bar.")
        case .permission:
            localizedAppString("onboarding.permission.subtitle", defaultValue: "Allow background input detection so Nudge can detect idle moments.")
        case .basicSetup:
            localizedAppString("onboarding.setup.subtitle", defaultValue: "Choose the defaults for your first sessions.")
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
                ttsEnabled: $viewModel.ttsEnabled,
                petPresentationMode: $viewModel.petPresentationMode
            )
        case .completionReady:
            CompletionReadyStepView(
                idleThresholdText: idleThresholdText,
                launchAtLoginText: toggleText(viewModel.launchAtLoginEnabled),
                ttsText: toggleText(viewModel.ttsEnabled),
                visualModeText: visualModeText
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
    
    private var completionReadyFooter: some View {
        OnboardingFooterView(
            primaryTitle: localizedAppString("onboarding.completion.ready.cta.finish", defaultValue: "Continue to Menu Bar"),
            primaryAction: viewModel.finish,
            secondaryTitle: nil,
            secondaryAction: nil,
            tertiaryTitle: nil,
            tertiaryAction: nil
        )
    }
    
    private var completionLimitedFooter: some View {
        OnboardingFooterView(
            primaryTitle: localizedAppString("onboarding.completion.limited.cta.finish", defaultValue: "Continue in Menu Bar"),
            primaryAction: viewModel.finish,
            secondaryTitle: localizedAppString("onboarding.completion.limited.cta.retry", defaultValue: "Set Up Permission Again"),
            secondaryAction: viewModel.retryPermission,
            tertiaryTitle: nil,
            tertiaryAction: nil
        )
    }
    
    private var idleThresholdText: String {
        if viewModel.idleThresholdSeconds < 60 {
            return "\(viewModel.idleThresholdSeconds)초"
        }
        
        let minutes = viewModel.idleThresholdSeconds / 60
        return "\(minutes)분"
    }
    
    private var visualModeText: String {
        switch viewModel.petPresentationMode {
        case .sprout:
            localizedAppString("onboarding.setup.visual_mode.sprout", defaultValue: "Sprout")
        case .minimal:
            localizedAppString("onboarding.setup.visual_mode.minimal", defaultValue: "Minimal")
        }
    }
    
    private func toggleText(_ isOn: Bool) -> String {
        isOn
            ? localizedAppString("onboarding.common.toggle.on", defaultValue: "On")
            : localizedAppString("onboarding.common.toggle.off", defaultValue: "Off")
    }
}
