import Foundation

func appDisplayLocale() -> Locale {
    Locale(identifier: AppLanguageStore.shared.preferredLocaleIdentifier)
}

private enum AppFormatterCache {
    static var percentByLocaleIdentifier: [String: NumberFormatter] = [:]
    static var weekdayByLocaleIdentifier: [String: DateFormatter] = [:]
    static var clockByLocaleIdentifier: [String: DateFormatter] = [:]
}

func localizedDurationString(_ duration: TimeInterval) -> String? {
    let formatter = DateComponentsFormatter()
    var calendar = Calendar.current
    calendar.locale = appDisplayLocale()
    formatter.calendar = calendar
    formatter.allowedUnits = duration >= 3600 ? [.hour, .minute] : [.minute, .second]
    formatter.unitsStyle = .abbreviated
    formatter.zeroFormattingBehavior = [.pad]
    return formatter.string(from: max(duration, 0))
}

func localizedClockString(_ date: Date) -> String {
    let locale = appDisplayLocale()
    let localeIdentifier = locale.identifier
    let formatter = AppFormatterCache.clockByLocaleIdentifier[localeIdentifier] ?? {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        AppFormatterCache.clockByLocaleIdentifier[localeIdentifier] = formatter
        return formatter
    }()
    formatter.locale = locale
    return formatter.string(from: date)
}

func localizedPercentString(_ value: Double) -> String {
    let locale = appDisplayLocale()
    let localeIdentifier = locale.identifier
    let formatter = AppFormatterCache.percentByLocaleIdentifier[localeIdentifier] ?? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        formatter.locale = locale
        AppFormatterCache.percentByLocaleIdentifier[localeIdentifier] = formatter
        return formatter
    }()
    formatter.locale = locale
    return formatter.string(from: NSNumber(value: max(0, min(1, value))))
        ?? "\(Int((max(0, min(1, value)) * 100).rounded()))%"
}

func localizedWeekdayLabel(for date: Date) -> String {
    let locale = appDisplayLocale()
    let localeIdentifier = locale.identifier
    let formatter = AppFormatterCache.weekdayByLocaleIdentifier[localeIdentifier] ?? {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        AppFormatterCache.weekdayByLocaleIdentifier[localeIdentifier] = formatter
        return formatter
    }()
    formatter.locale = locale
    return formatter.string(from: date)
}
