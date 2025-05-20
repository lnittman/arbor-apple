import SwiftUI
import PhosphorSwift

struct RulesListView: View {
    @Binding var rules: [Rule]
    var filteredRules: [Rule]
    var searchText: String
    @State private var showCreateRuleView = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Create New Rule item at the top
                if searchText.isEmpty {
                    Button {
                        showCreateRuleView = true
                    } label: {
                        HStack {
                            Text("Create new")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.foreground(scheme: colorScheme))
                            
                            Spacer()
                            
                            PhosphorIcon.small(Ph.caretRight.duotone, color: Theme.mutedForeground(scheme: colorScheme))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.card(scheme: colorScheme))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if filteredRules.isEmpty {
                    EmptyRulesView()
                } else {
                    ForEach(0..<filteredRules.count, id: \.self) { index in
                        let actualIndex = rules.firstIndex(where: { $0.id == filteredRules[index].id }) ?? index
                        if actualIndex < rules.count {
                            RuleRowView(rule: $rules[actualIndex])
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showCreateRuleView) {
            CreateRuleView(isShowing: $showCreateRuleView, onSave: { newRule in
                if let newRule = newRule {
                    rules.append(newRule)
                }
            })
        }
    }
}

#Preview {
    RulesListView(
        rules: .constant([
            Rule(name: "normal", description: "default responses from assistant"),
            Rule(name: "concise", description: "shorter responses & more messages")
        ]),
        filteredRules: [
            Rule(name: "normal", description: "default responses from assistant"),
            Rule(name: "concise", description: "shorter responses & more messages")
        ],
        searchText: ""
    )
} 
