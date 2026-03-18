import re
with open("dynamic island/ContentView.swift", "r") as f:
    text = f.read()

# Fix duplicates at top
pattern = re.compile(r"import IOBluetooth.*?internal import Combine", re.DOTALL)
one_copy = """import IOBluetooth

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
         if abs(event.scrollingDeltaX) > 2.0 {
             onScroll?(event.scrollingDeltaX)
         }
         super.scrollWheel(with: event)
    }
}

internal import Combine"""
text = pattern.sub(one_copy, text)

# Fix duplicate states
state_pattern = re.compile(r"(@State private var popupCounter: Int = 0\s+@State private var manualViewMode: String = \"auto\"\s+@State private var lastSwipeTime: Date = Date\(\)\s+)+", re.DOTALL)
one_state = """@State private var popupCounter: Int = 0
    @State private var manualViewMode: String = "auto"
    @State private var lastSwipeTime: Date = Date()
"""
text = state_pattern.sub(one_state, text)

with open("dynamic island/ContentView.swift", "w") as f:
    f.write(text)

print("Duplicates cleaned.")
