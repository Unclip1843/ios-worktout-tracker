import Foundation

extension Date {
    var dayOnly: Date { Calendar.current.startOfDay(for: self) }
    func addingDays(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: n, to: self) ?? self
    }

    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        let start = calendar.date(from: components) ?? self
        return calendar.startOfDay(for: start)
    }

    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        let start = calendar.date(from: components) ?? self
        return calendar.startOfDay(for: start)
    }

    var startOfYear: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self)
        let start = calendar.date(from: components) ?? self
        return calendar.startOfDay(for: start)
    }

    func addingWeeks(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: n, to: self) ?? self
    }

    func addingMonths(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: n, to: self) ?? self
    }

    func addingYears(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: n, to: self) ?? self
    }
}
