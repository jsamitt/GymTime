import SwiftUI

/// Drop-in swipe-to-reveal-delete row that works inside a VStack (no need for
/// a List). Horizontal drag past a threshold exposes a red Delete button; tap
/// the button to invoke `onDelete` (the caller is responsible for presenting
/// a confirmation dialog). Tap the card itself to invoke `onTap`.
///
/// Crucially, the card is NOT wrapped in a SwiftUI Button — Button eagerly
/// grabs the touch and prevents the DragGesture from firing for horizontal
/// swipes. Instead we attach a `TapGesture` at the ZStack level, which
/// composes cleanly with the DragGesture: vertical scroll still works (parent
/// scroll view wins), horizontal drag on the row triggers the swipe, and a
/// plain tap triggers `onTap`.
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
            // Red "Delete" action revealed beneath the card.
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

            // Foreground card content. Uses a plain view + tap gesture so
            // the simultaneous drag gesture below can win when the finger
            // moves horizontally.
            content()
                .contentShape(Rectangle())
                .background(GT.bg)
                .offset(x: offset)
                .onTapGesture {
                    if committed {
                        withAnimation(.spring(duration: 0.25)) {
                            offset = 0
                            committed = false
                        }
                    } else {
                        onTap()
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 12, coordinateSpace: .local)
                        .onChanged { v in
                            // Only steal the touch for mostly-horizontal drags so
                            // vertical scrolling in the parent still works.
                            let h = v.translation.width
                            let vY = v.translation.height
                            guard abs(h) > abs(vY) else { return }
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

/// Convenience wrapper for HistoryView's session rows. Kept as a thin alias
/// so calls in HistoryView don't need to pass unrelated type parameters.
struct SessionSwipeRow<Content: View>: View {
    let session: Session
    let onTap: () -> Void
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        SwipeToDeleteRow(onTap: onTap, onDelete: onDelete, content: content)
    }
}
