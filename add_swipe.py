import re

with open("dynamic island/ContentView.swift", "r") as f:
    text = f.read()

scroll_code = """import SwiftUI
import IOBluetooth

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
"""

text = re.sub(r"import SwiftUI\nimport IOBluetooth\n", scroll_code, text)

# State properties for swipe
state_code = """    @State private var popupCounter: Int = 0
    @State private var manualViewMode: String = "auto"
    @State private var lastSwipeTime: Date = Date()"""
text = text.replace("    @State private var popupCounter: Int = 0", state_code)

bt_pattern = r"(\} else if bluetooth\.showConnectionAlert)(, let deviceName = bluetooth\.newlyConnectedDevice)?( \{)"
text = re.sub(bt_pattern, r"\1 \3\n                    let deviceName = bluetooth.newlyConnectedDevice ?? \"Headphones\"", text)

swipe_modifiers = """            .background(ScrollDetector { deltaX in
                let now = Date()
                if now.timeIntervalSince(lastSwipeTime) > 0.4 {
                    lastSwipeTime = now
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isExpanded = false
                        if deltaX > 0 { // Scroll Left -> Spotify
                            bluetooth.showConnectionAlert = false
                            showTrackPopup = true
                            manualViewMode = "spotify"
                        } else {
                            showTrackPopup = false
                            bluetooth.showConnectionAlert = true
                            manualViewMode = "bluetooth"
                        }
                    }
                }
            })
            .gesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .local)
                    .onEnded { value in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isExpanded = false
                            if value.translation.width < 0 { 
                                // Drag Left -> Spotify
                                bluetooth.showConnectionAlert = false
                                showTrackPopup = true
                                manualViewMode = "spotify"
                            } else {
                                // Drag Right -> Bluetooth
                                showTrackPopup = false
                                bluetooth.showConnectionAlert = true
                                manualViewMode = "bluetooth"
                            }
                        }
                    }
            )
            .onTapGesture {
                withAnimation"""

text = text.replace("""            .onTapGesture {
                withAnimation""", swipe_modifiers)

with open("dynamic island/ContentView.swift", "w") as f:
    f.write(text)

print("SUCCESS")
