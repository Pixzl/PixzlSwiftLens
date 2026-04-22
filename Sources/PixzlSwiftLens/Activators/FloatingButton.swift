import SwiftUI

struct FloatingButton: View {
    let action: () -> Void
    @State private var dragOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        Button(action: action) {
            Image(systemName: "scope")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(.black.opacity(0.7))
                        .shadow(radius: 4)
                )
        }
        .buttonStyle(.plain)
        .offset(x: lastOffset.width + dragOffset.width,
                y: lastOffset.height + dragOffset.height)
        .gesture(
            DragGesture()
                .onChanged { dragOffset = $0.translation }
                .onEnded { _ in
                    lastOffset.width  += dragOffset.width
                    lastOffset.height += dragOffset.height
                    dragOffset = .zero
                }
        )
    }
}
