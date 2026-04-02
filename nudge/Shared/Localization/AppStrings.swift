import Foundation

func localizedAppString(_ key: String, defaultValue: String) -> String {
    let localizedValue = NSLocalizedString(key, comment: "")
    return localizedValue == key ? defaultValue : localizedValue
}
