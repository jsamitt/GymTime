import SwiftUI

/// Drop-in swipe-to-reveal-delete row that works inside a VStack (no need for
/// a List). Horizontal drag past a threshold exposes a red Delete button; tap
/// the button to invoke `onDelete` (the caller is responsible for presenting
/// a confirmation dialog). Tap the card itself to invoke `onTap`.
///
/// Use this wherever a swipe gesture is expected but the surrounding layout
/// is a custom card-based VStack rather than a `List`.
struct SwipeToDeleteRow<Content: View>: View {
    let onTap: () -> Void
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var committed: Bool = false

    private let revealWidth: CGFloat = 88
    private let deleteThreshold: CGFloat = 44

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete action background (revealed beneath the card)
            HStack {
                Spacer()
                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        offset = 0
                        committed = false
                    }
                    onDelete()
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Delete")
                            .font(.gtMono(10, weight: .semibold))
                            .tracking(1.0)
                    }
                    .foregroundColor(.white)
                    .frame(width: revealWidth)
                    .frame(maxHeight: .infinity)
                    .background(Color(.systemRed))
                }
                .buttonStyle(.plain)
                .opacity(-offset > 4 ? 1 : 0)
            }
            .clipShape(RoundedRectangle(cornerRadius: GT.rMd))

            Button(action: {
                if committed {
                    withAnimation(.spring(duration: 0.25)) {
                        offset = 0
                        committed = false
                    }
                } else {
                    onTap()
                }
            }) {
                content()
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(GT.bg) // covers the red background when offset is 0
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { v in
                        let h = v.translation.width
                        if h < 0 {
                            offset = max(h, -revealWidth * 1.2)
                        } else if committed {
                            offset = min(0, -revealWidth + h)
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(duration: 0.25)) {
                            if offset < -deleteThreshold {
                                offset = -revealWidth
                                committed = true
                            } else {
                                offset = 0
                                committed = false
                            }
                        }
                    }
            )
        }
    }
}

/// Convenience wrapper for HistoryView's session rows.
struct SessionSwipeRow<Content: View>: View {
    let session: Session
    let onTap: () -> Void
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        SwipeToDeleteRow(onTap: onTap, onDelete: onDelete, content: content)
    }
}
