import Foundation

func appDisplayLocale() -> Locale {
    Locale(identifier: AppLanguageStore.shared.preferredLocaleIdentifier)
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
    let formatter = DateFormatter()
    formatter.locale = appDisplayLocale()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    return formatter.string(from: date)
}
