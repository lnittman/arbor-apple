import SwiftUI
import PhosphorSwift

struct CreateRuleView: View {
    @Binding var isShowing: Bool
    let onSave: (Rule?) -> Void
    
    @State private var ruleName: String = ""
    @State private var ruleDescription: String = ""
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Rule name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rule name")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.foreground(scheme: colorScheme))
                    
                    TextField("Name", text: $ruleName)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.card(scheme: colorScheme))
                        )
                }
                
                // Rule description input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.foreground(scheme: colorScheme))
                    
                    TextField("Description", text: $ruleDescription)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.card(scheme: colorScheme))
                        )
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitle("Create New Rule", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {
                    isShowing = false
                    onSave(nil)
                }) {
                    Text("Cancel")
                },
                trailing: Button(action: {
                    let newRule = Rule(name: ruleName, description: ruleDescription)
                    isShowing = false
                    onSave(newRule)
                }) {
                    Text("Save")
                }
                .disabled(ruleName.isEmpty)
            )
            .background(Theme.background(scheme: colorScheme))
        }
    }
}

#Preview {
    CreateRuleView(isShowing: .constant(true), onSave: { _ in })
} 
