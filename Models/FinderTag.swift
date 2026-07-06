import Foundation

struct FinderTag: Identifiable, Hashable {
    let name: String
    var colorIndex: Int?
    var fileCount: Int

    var id: String { name }
}
