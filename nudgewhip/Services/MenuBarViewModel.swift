// MenuBarViewModel.swift
// 메뉴바 UI 상태를 관리하는 뷰모델.
//
// IdleMonitor를 래핑해 런타임/콘텐츠 상태를 뷰에 노출한다.
// 메뉴바 아이콘 선택, 카운트다운 텍스트 생성, 권한 새로고침·타이머 리셋을 제공한다.

import Foundation
import Observation
import SwiftData
import UserNotifications

@MainActor
@Observable
final class MenuBarViewModel {
    let idleMonitor: IdleMonitor
    private let modelContext: ModelContext
    private(set) var hasStarted = false
    private(set) var idleThresholdText = localizedAppString("menu.dropdown.value.unavailable", defaultValue: "Unavailable")
    private(set) var scheduleText = localizedAppString("menu.dropdown.value.schedule.off", defaultValue: "Off")
    private(set) var countdownOverlayEnabled = true
    private(set) var countdownOverlayPosition = CountdownOverlayPosition.topLeft
    private(set) var countdownOverlayVariant = CountdownOverlayVariant.mini
    private(set) var scheduleEnabled = false
    private(set) var scheduleStartTime = Calendar.current.startOfDay(for: .now).addingTimeInterval(32_400)
    private(set) var scheduleEndTime = Calendar.current.startOfDay(for: .now).addingTimeInterval(61_200)
    private(set) var whitelistCount = 0
    private(set) var todayStats = DailyStats.derive(for: [], on: .now)
    private(set) var statisticsSnapshot = StatisticsSnapshot.derive(for: [], on: .now)
    private(set) var appUsageSnapshot = AppUsageSnapshot.empty
    private(set) var activePresetName: String = ""
    private(set) var schedulePresets: [SchedulePreset] = []
    private(set) var petState: PetState?
    private var petProgressionService: PetProgressionService?
    
    init(idleMonitor: IdleMonitor? = nil) {
        self.idleMonitor = idleMonitor ?? IdleMonitor()
        self.modelContext = NudgeWhipModelContainer.shared.mainContext
    }
    
    init(idleMonitor: IdleMonitor? = nil, modelContext: ModelContext) {
        self.idleMonitor = idleMonitor ?? IdleMonitor()
        self.modelContext = modelContext
    }
    
    /// IdleMonitor의 현재 런타임 상태
    var runtimeState: NudgeWhipRuntimeState {
        idleMonitor.runtimeStateController.snapshot.runtimeState
    }
    
    /// IdleMonitor의 현재 콘텐츠 상태
    var contentState: NudgeWhipContentState {
        idleMonitor.runtimeStateController.snapshot.contentState
    }

    /// 오버레이에서 표시할 현재 임계값 텍스트
    var configuredIdleThresholdText: String {
        formatClockStyleCountdown(max(0, Int(idleMonitor.idleThreshold.rounded())))
    }

    /// 오버레이에서 표시할 현재 모니터링 상태 설명
    var overlayRuntimeStateText: String {
        switch runtimeState {
        case .limitedNoAX:
            return localizedAppString("overlay.runtime_state.limited_no_ax", defaultValue: "Accessibility required")
        case .monitoring:
            return localizedAppString("overlay.runtime_state.monitoring", defaultValue: "Monitoring input")
        case .pausedManual:
            return localizedAppString("overlay.runtime_state.paused_manual", defaultValue: "Paused manually")
        case .pausedWhitelist:
            return localizedAppString("overlay.runtime_state.paused_whitelist", defaultValue: "Whitelisted app")
        case .alerting:
            return localizedAppString("overlay.runtime_state.alerting", defaultValue: "Idle detected")
        case .pausedSchedule:
            return localizedAppString("overlay.runtime_state.paused_schedule", defaultValue: "Outside schedule")
        case .suspendedSleepOrLock:
            return localizedAppString("overlay.runtime_state.suspended", defaultValue: "System suspended")
        }
    }

    /// 오버레이가 보여줄 카운트다운 텍스트. 1분 이상은 분 단위, 1분 미만은 초 단위로 표시
    func overlayCountdownText(now: Date = .now) -> String? {
        guard runtimeState == .monitoring, let deadline = idleMonitor.idleDeadlineAt else {
            return nil
        }

        let remaining = max(0, Int(deadline.timeIntervalSince(now).rounded()))
        if remaining < 60 {
            return "\(remaining)s"
        }

        return "\(remaining / 60)m"
    }
    
    /// 사용자가 수동 일시정지를 활성화했는지 여부
    var isManualPauseActive: Bool {
        idleMonitor.runtimeStateController.snapshot.manualPauseEnabled
    }

    var shouldShowBreakSuggestion: Bool {
        idleMonitor.shouldSuggestBreak
    }

    var breakSuggestionTitleText: String {
        localizedAppString("menu.break_suggestion.title", defaultValue: "Frequent interruptions noticed")
    }

    var breakSuggestionBodyText: String {
        localizedAppString(
            "menu.break_suggestion.body",
            defaultValue: "You keep pausing. Want to take a breather or adjust sensitivity?"
        )
    }
    
    /// 런타임 상태에 대응하는 SF Symbol 이름
    var systemImageName: String {
        switch runtimeState {
        case .limitedNoAX:
            return "hand.raised.slash"
        case .monitoring:
            return "eye.circle"
        case .pausedManual:
            return "pause.circle"
        case .pausedWhitelist:
            return "checkmark.circle"
        case .alerting:
            return "exclamationmark.circle"
        case .pausedSchedule:
            return "clock.badge"
        case .suspendedSleepOrLock:
            return "moon.zzz"
        }
    }
    
    /// 접근성 권한이 없을 때 CTA 표시 여부
    var shouldShowPermissionCTA: Bool {
        runtimeState == .limitedNoAX
    }
    
    /// 최초 1회만 실행. 권한 확인 후 모니터링 시작
    func startIfNeeded(at date: Date = .now) {
        guard !hasStarted else { return }
        hasStarted = true
        
        if idleMonitor.permissionManager.accessibilityPermissionState == .unknown {
            idleMonitor.start(at: date)
        } else {
            idleMonitor.setAccessibilityPermission(idleMonitor.permissionManager.accessibilityPermissionState, at: date)
        }
        
        if runtimeState == .monitoring, idleMonitor.lastInputAt == nil {
            idleMonitor.recordInput(at: date)
        }

        seedPresetsIfNeeded()
        loadSchedulePresets()
        initializePetService()
    }
    
    /// 권한 새로고침 후 필요 시 모니터링 시작
    func refreshPermission(at date: Date = .now) {
        idleMonitor.refreshPermission(at: date)
        
        if runtimeState == .monitoring, idleMonitor.lastInputAt == nil {
            idleMonitor.recordInput(at: date)
        }
    }
    
    /// 시스템 프롬프트와 함께 권한 요청
    func requestAccessibilityPermission(at date: Date = .now) {
        refreshPermission(promptIfNeeded: true, at: date)
    }
    
    @discardableResult
    /// 시스템 환경설정 접근성 패널 열기
    func openAccessibilitySettings() -> Bool {
        idleMonitor.permissionManager.openAccessibilitySettings()
    }
    
    /// 유휴 타이머 수동 리셋
    func resetIdleTimer(at date: Date = .now) {
        idleMonitor.recordInput(at: date)
    }
    
    /// 메뉴바 드롭다운 표시 상태를 idle monitor에 전달
    func setMenuPresentationActive(_ active: Bool) {
        idleMonitor.setMenuPresentationActive(active)
    }
    
    /// 사용자가 다시 켤 때까지 수동 일시정지
    func pauseUntilResumed(at date: Date = .now) {
        idleMonitor.setManualPause(true, at: date)
    }
    
    /// 지정된 분 수만큼 수동 일시정지
    func pauseForMinutes(_ minutes: Int, at date: Date = .now) {
        idleMonitor.setManualPause(true, until: date.addingTimeInterval(TimeInterval(minutes * 60)), at: date)
    }
    
    /// 수동 일시정지 해제
    func resumeFromManualPause(at date: Date = .now) {
        idleMonitor.setManualPause(false, at: date)
    }

    func relaxBreakSuggestionSensitivity(at date: Date = .now) {
        guard let settings = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first else { return }

        settings.idleThresholdSeconds = min(settings.idleThresholdSeconds + 60, 900)
        settings.updatedAt = date
        try? modelContext.save()

        idleMonitor.acknowledgeBreakSuggestion()
        apply(settings: settings, at: date)
    }

    func softenBreakSuggestionAlerts(at date: Date = .now) {
        guard let settings = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first else { return }

        settings.alertsPerHourLimit = max(1, settings.alertsPerHourLimit - 1)
        settings.notificationNudgePerHourLimit = max(1, settings.notificationNudgePerHourLimit - 1)
        settings.updatedAt = date
        try? modelContext.save()

        idleMonitor.acknowledgeBreakSuggestion()
        apply(settings: settings, at: date)
    }

    func acknowledgeBreakSuggestion() {
        idleMonitor.acknowledgeBreakSuggestion()
    }
    
    /// 내부: 프롬프트 옵션과 함께 권한 새로고침
    private func refreshPermission(promptIfNeeded: Bool, at date: Date) {
        idleMonitor.refreshPermission(promptIfNeeded: promptIfNeeded, at: date)
        
        if runtimeState == .monitoring, idleMonitor.lastInputAt == nil {
            idleMonitor.recordInput(at: date)
        }
    }
    
    /// 모니터링 중 다음 유휴 체크까지 카운트다운 문자열 반환
    func countdownText(now: Date = .now) -> String? {
        guard runtimeState == .monitoring, let deadline = idleMonitor.idleDeadlineAt else {
            return nil
        }

        let remaining = max(0, Int(deadline.timeIntervalSince(now).rounded()))
        return formatClockStyleCountdown(remaining)
    }
    
    /// SwiftData에 저장된 사용자 설정을 runtime monitor에 반영
    func apply(settings: UserSettings, at date: Date = .now) {
        idleMonitor.applySettings(settings, at: date)
        refreshMenuSnapshot(now: date)
    }
    
    /// SwiftData에 저장된 whitelist 앱 목록을 runtime monitor에 반영
    func apply(whitelistApps: [WhitelistApp], at date: Date = .now) {
        idleMonitor.applyWhitelistApps(whitelistApps, at: date)
        refreshMenuSnapshot(now: date)
    }
    
    func refreshMenuSnapshot(now: Date = .now) {
        let settings = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first
        let whitelistApps = (try? modelContext.fetch(FetchDescriptor<WhitelistApp>())) ?? []
        let focusSessions = (try? modelContext.fetch(FetchDescriptor<FocusSession>())) ?? []
        
        todayStats = DailyStats.derive(for: focusSessions, on: now)
        statisticsSnapshot = StatisticsSnapshot.derive(for: focusSessions, on: now)
        appUsageSnapshot = AppUsageSnapshot.derive(for: focusSessions, on: now)
        whitelistCount = whitelistApps.count
        
        if let settings {
            idleMonitor.applySettings(settings, at: now)
        }
        applyMenuSettingsSnapshot(settings)
        idleMonitor.applyWhitelistApps(whitelistApps, at: now)
    }
    
    func updateScheduleEnabled(_ enabled: Bool, at date: Date = .now) {
        guard let settings = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first else { return }
        settings.scheduleEnabled = enabled
        settings.updatedAt = date
        try? modelContext.save()
        apply(settings: settings, at: date)
    }

    func updateCountdownOverlayEnabled(_ enabled: Bool, at date: Date = .now) {
        guard let settings = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first else { return }
        settings.countdownOverlayEnabled = enabled
        settings.updatedAt = date
        try? modelContext.save()
        apply(settings: settings, at: date)
    }

    func updateCountdownOverlayPosition(_ position: CountdownOverlayPosition, at date: Date = .now) {
        guard let settings = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first else { return }
        settings.countdownOverlayPosition = position
        settings.updatedAt = date
        try? modelContext.save()
        apply(settings: settings, at: date)
    }

    func updateCountdownOverlayVariant(_ variant: CountdownOverlayVariant, at date: Date = .now) {
        guard let settings = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first else { return }
        settings.countdownOverlayVariant = variant
        settings.updatedAt = date
        try? modelContext.save()
        apply(settings: settings, at: date)
    }
    
    func updateScheduleStartTime(_ dateValue: Date, at date: Date = .now) {
        guard let settings = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first else { return }
        let candidate = secondsFromMidnight(for: dateValue)
        guard candidate != settings.scheduleEndSecondsFromMidnight else { return }
        settings.scheduleStartSecondsFromMidnight = candidate
        settings.updatedAt = date
        try? modelContext.save()
        apply(settings: settings, at: date)
    }
    
    func updateScheduleEndTime(_ dateValue: Date, at date: Date = .now) {
        guard let settings = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first else { return }
        let candidate = secondsFromMidnight(for: dateValue)
        guard candidate != settings.scheduleStartSecondsFromMidnight else { return }
        settings.scheduleEndSecondsFromMidnight = candidate
        settings.updatedAt = date
        try? modelContext.save()
        apply(settings: settings, at: date)
    }
    
    private func applyMenuSettingsSnapshot(_ settings: UserSettings?) {
        guard let settings else {
            idleThresholdText = localizedAppString("menu.dropdown.value.unavailable", defaultValue: "Unavailable")
            scheduleText = localizedAppString("menu.dropdown.value.schedule.off", defaultValue: "Off")
            countdownOverlayEnabled = true
            countdownOverlayPosition = .topLeft
            countdownOverlayVariant = .mini
            scheduleEnabled = false
            return
        }
        
        idleThresholdText = formattedDuration(TimeInterval(settings.idleThresholdSeconds))
        countdownOverlayEnabled = settings.countdownOverlayEnabled
        countdownOverlayPosition = settings.countdownOverlayPosition
        countdownOverlayVariant = settings.countdownOverlayVariant
        scheduleEnabled = settings.scheduleEnabled
        scheduleStartTime = dateFromSeconds(settings.scheduleStartSecondsFromMidnight)
        scheduleEndTime = dateFromSeconds(settings.scheduleEndSecondsFromMidnight)
        
        if settings.scheduleEnabled {
            scheduleText = "\(formattedClock(scheduleStartTime)) - \(formattedClock(scheduleEndTime))"
        } else {
            scheduleText = localizedAppString("menu.dropdown.value.schedule.off", defaultValue: "Off")
        }
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        return localizedDurationString(duration)
            ?? localizedAppString("menu.dropdown.value.unavailable", defaultValue: "Unavailable")
    }
    
    private func formattedClock(_ date: Date) -> String {
        localizedClockString(date)
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

    private func formatClockStyleCountdown(_ remaining: Int) -> String {
        let hours = remaining / 3_600
        let minutes = (remaining % 3_600) / 60
        let seconds = remaining % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }

    func loadSchedulePresets() {
        let descriptor = FetchDescriptor<SchedulePreset>(sortBy: [SortDescriptor(\.sortOrder)])
        schedulePresets = (try? modelContext.fetch(descriptor)) ?? []

        let activePreset = schedulePresets.first { $0.isActivePreset }
        activePresetName = activePreset?.name
            ?? localizedAppString("preset.schedule.custom", defaultValue: "Custom schedule")
    }

    func activatePreset(_ preset: SchedulePreset, at date: Date = .now) {
        for p in schedulePresets {
            p.isActivePreset = false
        }
        preset.isActivePreset = true
        preset.updatedAt = date

        guard let settings = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first else { return }
        settings.activePresetID = preset.id
        settings.scheduleStartSecondsFromMidnight = preset.startSecondsFromMidnight
        settings.scheduleEndSecondsFromMidnight = preset.endSecondsFromMidnight
        settings.scheduleEnabled = true
        settings.updatedAt = date
        try? modelContext.save()

        loadSchedulePresets()
        apply(settings: settings, at: date)
    }

    func createCustomPreset(name: String, start: Int, end: Int, weekdayOnly: Bool, at date: Date = .now) {
        let newPreset = SchedulePreset(
            name: name,
            startSecondsFromMidnight: start,
            endSecondsFromMidnight: end,
            isWeekdayOnly: weekdayOnly,
            isBuiltIn: false,
            sortOrder: schedulePresets.count
        )
        modelContext.insert(newPreset)
        try? modelContext.save()
        loadSchedulePresets()
    }

    func deletePreset(_ preset: SchedulePreset, at date: Date = .now) {
        guard !preset.isBuiltIn else { return }

        if preset.isActivePreset {
            guard let settings = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first else { return }
            settings.activePresetID = nil
            settings.updatedAt = date
            try? modelContext.save()
        }

        modelContext.delete(preset)
        try? modelContext.save()
        loadSchedulePresets()
    }

    private func seedPresetsIfNeeded() {
        let descriptor = FetchDescriptor<SchedulePreset>(predicate: #Predicate { $0.isBuiltIn })
        let builtIns = (try? modelContext.fetch(descriptor)) ?? []
        guard builtIns.isEmpty else { return }

        let settings = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first
        let existingEnabled = settings?.scheduleEnabled ?? false
        let existingStart = settings?.scheduleStartSecondsFromMidnight ?? 32400
        let existingEnd = settings?.scheduleEndSecondsFromMidnight ?? 61200

        SchedulePreset.seedBuiltInPresets(
            modelContext: modelContext,
            existingSchedule: (existingEnabled, existingStart, existingEnd)
        )
    }

    private func initializePetService() {
        let petService = PetProgressionService(modelContext: modelContext)
        self.petProgressionService = petService
        self.petState = petService.fetchPetState()
        petService.onStageUp = { [weak self] newStage in
            self?.petState = petService.fetchPetState()

            let petName = self?.petState?.name ?? "Whip"
            let stageName = newStage.displayName
            let content = UNMutableNotificationContent()
            content.title = localizedAppString(
                "pet.notification.level_up.title",
                defaultValue: "Level Up!"
            )
            content.body = localizedAppString(
                "pet.notification.level_up",
                defaultValue: "\(petName) reached \(stageName)!"
            )
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "pet.levelup.\(newStage.rawValue)",
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request)
        }
        idleMonitor.sessionTracker?.setPetProgressionService(petService)
        petService.checkDailyActiveBonus()
        self.petState = petService.fetchPetState()
    }
}
