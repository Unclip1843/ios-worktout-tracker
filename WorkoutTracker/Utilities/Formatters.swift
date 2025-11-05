import Foundation

func formatDuration(_ seconds: Int) -> String {
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    let s = seconds % 60
    if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
    else { return String(format: "%d:%02d", m, s) }
}

func formatWeight(_ weight: Double) -> String {
    if let formatted = weightNumberFormatter.string(from: NSNumber(value: weight)) {
        return formatted
    }
    return String(format: "%.2f", weight)
}

func formatDecimal(_ value: Double, maxFractionDigits: Int = 2) -> String {
    let formatter = decimalNumberFormatter
    formatter.maximumFractionDigits = maxFractionDigits
    if let formatted = formatter.string(from: NSNumber(value: value)) {
        return formatted
    }
    return String(format: "%.\(maxFractionDigits)f", value)
}

private let weightNumberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 2
    formatter.usesGroupingSeparator = false
    return formatter
}()

private let decimalNumberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 2
    formatter.usesGroupingSeparator = false
    return formatter
}()
