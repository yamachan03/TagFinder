import Foundation

enum MatchMode: String, CaseIterable, Identifiable, Codable {
    case and = "AND"
    case or = "OR"

    var id: String { rawValue }
}
