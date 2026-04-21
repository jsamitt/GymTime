import SwiftUI

/// Reusable numpad entry sheet. Opens with the initial value pre-filled and
/// calls `onCommit(text)` with the raw text on Save. Caller is responsible for
/// parsing and applying the value.
struct NumberTypeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let unit: String?
    let isDecimal: Bool
    let initial: String
    let onCommit: (String) -> Void

    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            GT.bg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(title.uppercased())
                        .gtMonoCaption(size: 11, tracking: 1.5)
                    Spacer()
                    Button { dismiss() } label: {
                        Text("Cancel")
                            .font(.gtBody(14))
                            .foregroundColor(GT.ink3)
                    }
                    .buttonStyle(.plain)
                }

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    TextField("", text: $text)
                        .font(.gtDisplay(64, weight: .semibold))
                        .tracking(-2)
                        .foregroundColor(GT.ink)
                        .keyboardType(isDecimal ? .decimalPad : .numberPad)
                        .textFieldStyle(.plain)
                        .focused($focused)
                        .onSubmit(commit)
                    if let unit {
                        Text(unit)
                            .font(.gtMono(20))
                            .foregroundColor(GT.ink3)
                    }
                }
                .padding(.vertical, 10)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(GT.line2).frame(height: 1)
                }

                Button(action: commit) {
                    Text("Save")
                        .font(.gtDisplay(16, weight: .bold))
                        .tracking(-0.2)
                        .foregroundColor(GT.limeInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Capsule().fill(GT.lime))
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
        }
        .onAppear {
            text = initial
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focused = true
            }
        }
    }

    private func commit() {
        onCommit(text)
        dismiss()
    }
}
