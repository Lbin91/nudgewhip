// UserSettings.swift
// 사용자 설정을 저장하는 SwiftData 모델.
//
// 유휴 임계값, 알림 설정, Pro 잠금 해제 등을 관리한다.
// preferredLocaleIdentifier로 로컬라이즈 언어 설정도 보관한다.

import Foundation
import SwiftData

enum SoundTheme: String, Codable, CaseIterable, Sendable {
    case normal
    case whip
}

enum CountdownOverlayPosition: String, Codable, CaseIterable, Sendable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

enum CountdownOverlayVariant: String, Codable, CaseIterable, Sendable {
    case standard
    case mini
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
    var soundThemeRawValue: String
    var countdownOverlayEnabled: Bool
    var countdownOverlayPositionRawValue: String?
    var countdownOverlayVariantRawValue: String?
    var scheduleEnabled: Bool
    var scheduleStartSecondsFromMidnight: Int
    var scheduleEndSecondsFromMidnight: Int
    var languageDefaultMigrationCompleted: Bool
    var createdAt: Date
    var updatedAt: Date
    
    /// 사운드 테마 설정 변환
    var soundTheme: SoundTheme {
        get { SoundTheme(rawValue: soundThemeRawValue) ?? .whip }
        set { soundThemeRawValue = newValue.rawValue }
    }

    var countdownOverlayPosition: CountdownOverlayPosition {
        get { CountdownOverlayPosition(rawValue: countdownOverlayPositionRawValue ?? "") ?? .topLeft }
        set { countdownOverlayPositionRawValue = newValue.rawValue }
    }

    var countdownOverlayVariant: CountdownOverlayVariant {
        get { CountdownOverlayVariant(rawValue: countdownOverlayVariantRawValue ?? "") ?? .standard }
        set { countdownOverlayVariantRawValue = newValue.rawValue }
    }
    
    /// 모든 설정값의 기본값을 제공하는 이니셜라이저
    init(
        idleThresholdSeconds: Int = 180,
        gentleAlertLeadSeconds: Int = 30,
        strongAlertLeadSeconds: Int = 60,
        alertsPerHourLimit: Int = 6,
        notificationNudgePerHourLimit: Int = 2,
        breakSuggestionEnabled: Bool = true,
        proUnlocked: Bool = false,
        preferredLocaleIdentifier: String? = nil,
        soundTheme: SoundTheme = .whip,
        countdownOverlayEnabled: Bool = true,
        countdownOverlayPosition: CountdownOverlayPosition = .topLeft,
        countdownOverlayVariant: CountdownOverlayVariant = .mini,
        scheduleEnabled: Bool = false,
        scheduleStartSecondsFromMidnight: Int = 32400,
        scheduleEndSecondsFromMidnight: Int = 61200,
        languageDefaultMigrationCompleted: Bool = true,
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
        self.soundThemeRawValue = soundTheme.rawValue
        self.countdownOverlayEnabled = countdownOverlayEnabled
        self.countdownOverlayPositionRawValue = countdownOverlayPosition.rawValue
        self.countdownOverlayVariantRawValue = countdownOverlayVariant.rawValue
        self.scheduleEnabled = scheduleEnabled
        self.scheduleStartSecondsFromMidnight = scheduleStartSecondsFromMidnight
        self.scheduleEndSecondsFromMidnight = scheduleEndSecondsFromMidnight
        self.languageDefaultMigrationCompleted = languageDefaultMigrationCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
