import re

with open("dynamic island/ContentView.swift", "r") as f:
    text = f.read()

swipe_modifiers = """            .background(ScrollDetector { deltaX in
                let now = Date()
                if now.timeIntervalSince(lastSwipeTime) > 0.4 {
                    lastSwipeTime = now
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isExpanded = false
                        if deltaX > 0 { // Drag Left -> Spotify
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
            .onTapGesture {"""

if ".background(ScrollDetector" not in text:
    text = text.replace("            .onTapGesture {", swipe_modifiers)

with open("dynamic island/ContentView.swift", "w") as f:
    f.write(text)
print("Swipe injected")
