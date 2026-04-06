// MenuBarViewModel.swift
// 메뉴바 UI 상태를 관리하는 뷰모델.
//
// IdleMonitor를 래핑해 런타임/콘텐츠 상태를 뷰에 노출한다.
// 메뉴바 아이콘 선택, 카운트다운 텍스트 생성, 권한 새로고침·타이머 리셋을 제공한다.

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class MenuBarViewModel {
    let idleMonitor: IdleMonitor
    private let modelContext: ModelContext
    private(set) var hasStarted = false
    private(set) var idleThresholdText = localizedAppString("menu.dropdown.value.unavailable", defaultValue: "Unavailable")
    private(set) var petPresentationText = localizedAppString("menu.dropdown.value.unavailable", defaultValue: "Unavailable")
    private(set) var scheduleText = localizedAppString("menu.dropdown.value.schedule.off", defaultValue: "Off")
    private(set) var countdownOverlayEnabled = true
    private(set) var scheduleEnabled = false
    private(set) var scheduleStartTime = Calendar.current.startOfDay(for: .now).addingTimeInterval(32_400)
    private(set) var scheduleEndTime = Calendar.current.startOfDay(for: .now).addingTimeInterval(61_200)
    private(set) var whitelistCount = 0
    private(set) var petHatchStage = PetHatchStage.hatched
    private(set) var petCharacter: PetCharacterType? = .partyMask
    private(set) var petEmotion = PetEmotion.sleep
    private(set) var petHatchStageText = localizedAppString("menu.dropdown.value.pet_stage.hatched", defaultValue: "Hatched")
    private(set) var petCharacterText = localizedAppString("menu.dropdown.value.pet_character.party_mask", defaultValue: "Cowboy")
    private(set) var petEmotionText = localizedAppString("menu.dropdown.value.none", defaultValue: "None")
    private(set) var todayStats = DailyStats.derive(for: [], on: .now)
    
    init(idleMonitor: IdleMonitor? = nil) {
        self.idleMonitor = idleMonitor ?? IdleMonitor()
        self.modelContext = NudgeModelContainer.shared.mainContext
    }
    
    init(idleMonitor: IdleMonitor? = nil, modelContext: ModelContext) {
        self.idleMonitor = idleMonitor ?? IdleMonitor()
        self.modelContext = modelContext
    }
    
    /// IdleMonitor의 현재 런타임 상태
    var runtimeState: NudgeRuntimeState {
        idleMonitor.runtimeStateController.snapshot.runtimeState
    }
    
    /// IdleMonitor의 현재 콘텐츠 상태
    var contentState: NudgeContentState {
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
            return "Accessibility required"
        case .monitoring:
            return "Monitoring input"
        case .pausedManual:
            return "Paused manually"
        case .pausedWhitelist:
            return "Whitelisted app"
        case .alerting:
            return "Idle detected"
        case .pausedSchedule:
            return "Outside schedule"
        case .suspendedSleepOrLock:
            return "System suspended"
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
        let petState = try? modelContext.fetch(FetchDescriptor<PetState>()).first
        let whitelistApps = (try? modelContext.fetch(FetchDescriptor<WhitelistApp>())) ?? []
        let focusSessions = (try? modelContext.fetch(FetchDescriptor<FocusSession>())) ?? []
        
        todayStats = DailyStats.derive(for: focusSessions, on: now)
        whitelistCount = whitelistApps.count
        
        if let settings {
            idleMonitor.applySettings(settings, at: now)
        }
        applyMenuSettingsSnapshot(settings)
        applyPetSnapshot(petState)
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
            petPresentationText = localizedAppString("menu.dropdown.value.unavailable", defaultValue: "Unavailable")
            scheduleText = localizedAppString("menu.dropdown.value.schedule.off", defaultValue: "Off")
            countdownOverlayEnabled = true
            scheduleEnabled = false
            return
        }
        
        idleThresholdText = formattedDuration(TimeInterval(settings.idleThresholdSeconds))
        petPresentationText = settings.petPresentationMode == .sprout
            ? localizedAppString("menu.dropdown.value.pet_mode.sprout", defaultValue: "Sprout")
            : localizedAppString("menu.dropdown.value.pet_mode.minimal", defaultValue: "Minimal")
        
        countdownOverlayEnabled = settings.countdownOverlayEnabled
        scheduleEnabled = settings.scheduleEnabled
        scheduleStartTime = dateFromSeconds(settings.scheduleStartSecondsFromMidnight)
        scheduleEndTime = dateFromSeconds(settings.scheduleEndSecondsFromMidnight)
        
        if settings.scheduleEnabled {
            scheduleText = "\(formattedClock(scheduleStartTime)) - \(formattedClock(scheduleEndTime))"
        } else {
            scheduleText = localizedAppString("menu.dropdown.value.schedule.off", defaultValue: "Off")
        }
    }
    
    private func applyPetSnapshot(_ petState: PetState?) {
        guard let petState else {
            petHatchStage = .hatched
            petCharacter = .partyMask
            petEmotion = .sleep
            petHatchStageText = localizedAppString("menu.dropdown.value.pet_stage.hatched", defaultValue: "Hatched")
            petCharacterText = localizedAppString("menu.dropdown.value.pet_character.party_mask", defaultValue: "Cowboy")
            petEmotionText = localizedAppString("menu.dropdown.value.pet_emotion.sleep", defaultValue: "Sleep")
            return
        }

        petHatchStage = petState.hatchStage
        petCharacter = petState.characterType
        petEmotion = petState.emotion
        
        switch petState.hatchStage {
        case .egg:
            petHatchStageText = localizedAppString("menu.dropdown.value.pet_stage.egg", defaultValue: "Egg")
        case .cracking:
            petHatchStageText = localizedAppString("menu.dropdown.value.pet_stage.cracking", defaultValue: "Cracking")
        case .hatched:
            petHatchStageText = localizedAppString("menu.dropdown.value.pet_stage.hatched", defaultValue: "Hatched")
        }
        switch petState.characterType {
        case .partyMask:
            petCharacterText = localizedAppString("menu.dropdown.value.pet_character.party_mask", defaultValue: "Ringmaster")
        case .cowboy:
            petCharacterText = localizedAppString("menu.dropdown.value.pet_character.cowboy", defaultValue: "Cowboy")
        case .devil:
            petCharacterText = localizedAppString("menu.dropdown.value.pet_character.devil", defaultValue: "Little Devil")
        case .catwoman:
            petCharacterText = localizedAppString("menu.dropdown.value.pet_character.catwoman", defaultValue: "Catwoman")
        case .rat:
            petCharacterText = localizedAppString("menu.dropdown.value.pet_character.rat", defaultValue: "Rat")
        case .ox:
            petCharacterText = localizedAppString("menu.dropdown.value.pet_character.ox", defaultValue: "Ox")
        case .tiger:
            petCharacterText = localizedAppString("menu.dropdown.value.pet_character.tiger", defaultValue: "Tiger")
        case .rabbit:
            petCharacterText = localizedAppString("menu.dropdown.value.pet_character.rabbit", defaultValue: "Rabbit")
        }
        
        switch petState.emotion {
        case .happy:
            petEmotionText = localizedAppString("menu.dropdown.value.pet_emotion.happy", defaultValue: "Happy")
        case .cheer:
            petEmotionText = localizedAppString("menu.dropdown.value.pet_emotion.cheer", defaultValue: "Cheer")
        case .sleep:
            petEmotionText = localizedAppString("menu.dropdown.value.pet_emotion.sleep", defaultValue: "Sleep")
        case .concern:
            petEmotionText = localizedAppString("menu.dropdown.value.pet_emotion.concern", defaultValue: "Concern")
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
}
