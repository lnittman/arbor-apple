import SwiftUI
import PhosphorSwift

struct RulesSelectionView: View {
    @Binding var isShowing: Bool
    @State private var searchText = ""
    @State private var includeGlobalRules = true
    @State private var rules: [Rule] = [
        Rule(name: "normal", description: "default responses from assistant"),
        Rule(name: "concise", description: "shorter responses & more messages"),
        Rule(name: "explanatory", description: "educational responses for learning"),
        Rule(name: "formal", description: "clear and well-structured responses")
    ]
    @Environment(\.colorScheme) private var colorScheme
    
    var filteredRules: [Rule] {
        if searchText.isEmpty {
            return rules
        } else {
            return rules.filter { $0.name.localizedCaseInsensitiveContains(searchText) || 
                                $0.description.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var selectedRulesCount: Int {
        rules.filter { $0.isSelected }.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Navigation header
            RulesHeaderView(isShowing: $isShowing)
            
            // Global rules toggle
            GlobalRulesToggleView(includeGlobalRules: $includeGlobalRules)
            
            // Search bar
            RulesSearchBarView(searchText: $searchText)
            
            // Rules list
            RulesListView(rules: $rules, filteredRules: filteredRules, searchText: searchText)
        }
        .background(Theme.background(scheme: colorScheme))
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    RulesSelectionView(isShowing: .constant(true))
        .background(Color(.systemBackground))
} 
