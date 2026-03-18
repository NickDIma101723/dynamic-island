import SwiftUI

struct ScrollDetector: NSViewRepresentable {
    var onScroll: (CGFloat) -> Void
    func makeNSView(context: Context) -> NSView {
         let view = ScrollHostView()
         view.onScroll = onScroll
         return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class ScrollHostView: NSView {
    var onScroll: ((CGFloat) -> Void)?
    override func scrollWheel(with event: NSEvent) {
         if abs(event.scrollingDeltaX) > 1.5 {
             onScroll?(event.scrollingDeltaX)
         }
         super.scrollWheel(with: event)
    }
}
