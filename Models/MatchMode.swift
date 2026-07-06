import Foundation

enum MatchMode: String, CaseIterable, Identifiable {
    case and = "AND"
    case or = "OR"

    var id: String { rawValue }
}
