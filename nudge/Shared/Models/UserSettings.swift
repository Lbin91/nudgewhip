// UserSettings.swift
// 사용자 설정을 저장하는 SwiftData 모델.
//
// 유휴 임계값, 알림 설정, Pro 잠금 해제, 펫 표시 모드 등을 관리한다.
// preferredLocaleIdentifier로 로컬라이즈 언어 설정도 보관한다.

import Foundation
import SwiftData

enum PetPresentationMode: String, Codable, CaseIterable, Sendable {
    case sprout
    case minimal
}

enum SoundTheme: String, Codable, CaseIterable, Sendable {
    case normal
    case whip
}

@Model
final class UserSettings {
    var idleThresholdSeconds: Int
    var gentleAlertLeadSeconds: Int
    var strongAlertLeadSeconds: Int
    var alertsPerHourLimit: Int
    var notificationNudgePerHourLimit: Int
    var breakSuggestionEnabled: Bool
    var proUnlocked: Bool
    var preferredLocaleIdentifier: String?
    var petPresentationRawValue: String
    var soundThemeRawValue: String
    var countdownOverlayEnabled: Bool
    var scheduleEnabled: Bool
    var scheduleStartSecondsFromMidnight: Int
    var scheduleEndSecondsFromMidnight: Int
    var createdAt: Date
    var updatedAt: Date
    
    /// 로우 밸류와 편의 enum(PetPresentationMode) 간 변환
    var petPresentationMode: PetPresentationMode {
        get { PetPresentationMode(rawValue: petPresentationRawValue) ?? .sprout }
        set { petPresentationRawValue = newValue.rawValue }
    }

    /// 사운드 테마 설정 변환
    var soundTheme: SoundTheme {
        get { SoundTheme(rawValue: soundThemeRawValue) ?? .normal }
        set { soundThemeRawValue = newValue.rawValue }
    }
    
    /// 모든 설정값의 기본값을 제공하는 이니셜라이저
    init(
        idleThresholdSeconds: Int = 300,
        gentleAlertLeadSeconds: Int = 30,
        strongAlertLeadSeconds: Int = 60,
        alertsPerHourLimit: Int = 6,
        notificationNudgePerHourLimit: Int = 2,
        breakSuggestionEnabled: Bool = true,
        proUnlocked: Bool = false,
        preferredLocaleIdentifier: String? = AppLanguage.english.rawValue,
        petPresentationMode: PetPresentationMode = .sprout,
        soundTheme: SoundTheme = .normal,
        countdownOverlayEnabled: Bool = true,
        scheduleEnabled: Bool = false,
        scheduleStartSecondsFromMidnight: Int = 32400,
        scheduleEndSecondsFromMidnight: Int = 61200,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.idleThresholdSeconds = idleThresholdSeconds
        self.gentleAlertLeadSeconds = gentleAlertLeadSeconds
        self.strongAlertLeadSeconds = strongAlertLeadSeconds
        self.alertsPerHourLimit = alertsPerHourLimit
        self.notificationNudgePerHourLimit = notificationNudgePerHourLimit
        self.breakSuggestionEnabled = breakSuggestionEnabled
        self.proUnlocked = proUnlocked
        self.preferredLocaleIdentifier = preferredLocaleIdentifier
        self.petPresentationRawValue = petPresentationMode.rawValue
        self.soundThemeRawValue = soundTheme.rawValue
        self.countdownOverlayEnabled = countdownOverlayEnabled
        self.scheduleEnabled = scheduleEnabled
        self.scheduleStartSecondsFromMidnight = scheduleStartSecondsFromMidnight
        self.scheduleEndSecondsFromMidnight = scheduleEndSecondsFromMidnight
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
