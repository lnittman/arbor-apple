import Foundation

struct Rule: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    var isSelected: Bool = false
} 