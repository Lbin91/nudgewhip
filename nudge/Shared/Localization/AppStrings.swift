// AppStrings.swift
// 로컬라이제이션 헬퍼 함수.
//
// NSLocalizedString로 번역된 문자열을 가져오고,
// 키와 동일하면 기본값(영어)을 반환한다.

import Foundation

/// 키로 로컬라이즈된 문자열을 조회. 번역이 없으면 defaultValue 반환
func localizedAppString(_ key: String, defaultValue: String) -> String {
    let localizedValue = NSLocalizedString(key, comment: "")
    return localizedValue == key ? defaultValue : localizedValue
}
