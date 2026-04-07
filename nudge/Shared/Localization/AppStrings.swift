// AppStrings.swift
// 로컬라이제이션 헬퍼 함수.
//
// NSLocalizedString로 번역된 문자열을 가져오고,
// 키와 동일하면 기본값(영어)을 반환한다.

import Foundation
import Observation

enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case english = "en"
    case korean = "ko"

    static func resolve(
        _ identifier: String?,
        preferredLanguages: [String] = Locale.preferredLanguages
    ) -> AppLanguage {
        let resolvedIdentifier = identifier ?? preferredLanguages.first
        guard let resolvedIdentifier else { return .english }

        let normalized = resolvedIdentifier.lowercased()
        if normalized.hasPrefix("ko") {
            return .korean
        }
        return .english
    }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .korean:
            return "한국어"
        }
    }
}

@Observable
final class AppLanguageStore {
    static let shared = AppLanguageStore()

    private(set) var preferredLocaleIdentifier = AppLanguage.resolve(nil).rawValue

    func apply(preferredLocaleIdentifier: String?) {
        self.preferredLocaleIdentifier = AppLanguage.resolve(preferredLocaleIdentifier).rawValue
    }

    func refresh(from settings: UserSettings?) {
        apply(preferredLocaleIdentifier: settings?.preferredLocaleIdentifier)
    }
}

/// 키로 로컬라이즈된 문자열을 조회. 번역이 없으면 defaultValue 반환
func localizedAppString(_ key: String, defaultValue: String) -> String {
    let localeIdentifier = AppLanguageStore.shared.preferredLocaleIdentifier
    let localizedValue = localizedAppStringValue(key, defaultValue: defaultValue, localeIdentifier: localeIdentifier)
    return localizedValue == key ? defaultValue : localizedValue
}

private func localizedAppStringValue(_ key: String, defaultValue: String, localeIdentifier: String) -> String {
    if let localizedBundle = bundle(for: localeIdentifier) {
        let localizedValue = localizedBundle.localizedString(forKey: key, value: defaultValue, table: nil)
        if localizedValue != key {
            return localizedValue
        }
    }

    if localeIdentifier != AppLanguage.english.rawValue, let englishBundle = bundle(for: AppLanguage.english.rawValue) {
        let localizedValue = englishBundle.localizedString(forKey: key, value: defaultValue, table: nil)
        if localizedValue != key {
            return localizedValue
        }
    }

    let localizedValue = Bundle.main.localizedString(forKey: key, value: defaultValue, table: nil)
    return localizedValue == key ? defaultValue : localizedValue
}

private func bundle(for localeIdentifier: String) -> Bundle? {
    if let path = Bundle.main.path(forResource: localeIdentifier, ofType: "lproj") {
        return Bundle(path: path)
    }

    let languageCode = localeIdentifier.split(separator: "-").first.map(String.init) ?? localeIdentifier
    if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj") {
        return Bundle(path: path)
    }

    return nil
}
