import Foundation
import SwiftData

enum PetPresentationMode: String, Codable, CaseIterable, Sendable {
    case sprout
    case minimal
}

@Model
final class UserSettings {
    var idleThresholdSeconds: Int
    var gentleAlertLeadSeconds: Int
    var strongAlertLeadSeconds: Int
    var ttsLeadSeconds: Int
    var alertsPerHourLimit: Int
    var ttsPerHourLimit: Int
    var ttsEnabled: Bool
    var breakSuggestionEnabled: Bool
    var proUnlocked: Bool
    var preferredLocaleIdentifier: String?
    var petPresentationRawValue: String
    var createdAt: Date
    var updatedAt: Date
    
    var petPresentationMode: PetPresentationMode {
        get { PetPresentationMode(rawValue: petPresentationRawValue) ?? .sprout }
        set { petPresentationRawValue = newValue.rawValue }
    }
    
    init(
        idleThresholdSeconds: Int = 300,
        gentleAlertLeadSeconds: Int = 30,
        strongAlertLeadSeconds: Int = 60,
        ttsLeadSeconds: Int = 90,
        alertsPerHourLimit: Int = 6,
        ttsPerHourLimit: Int = 2,
        ttsEnabled: Bool = true,
        breakSuggestionEnabled: Bool = true,
        proUnlocked: Bool = false,
        preferredLocaleIdentifier: String? = nil,
        petPresentationMode: PetPresentationMode = .sprout,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.idleThresholdSeconds = idleThresholdSeconds
        self.gentleAlertLeadSeconds = gentleAlertLeadSeconds
        self.strongAlertLeadSeconds = strongAlertLeadSeconds
        self.ttsLeadSeconds = ttsLeadSeconds
        self.alertsPerHourLimit = alertsPerHourLimit
        self.ttsPerHourLimit = ttsPerHourLimit
        self.ttsEnabled = ttsEnabled
        self.breakSuggestionEnabled = breakSuggestionEnabled
        self.proUnlocked = proUnlocked
        self.preferredLocaleIdentifier = preferredLocaleIdentifier
        self.petPresentationRawValue = petPresentationMode.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
