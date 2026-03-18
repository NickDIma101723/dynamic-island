import re
with open("dynamic island/ContentView.swift", "r") as f:
    text = f.read()

# Add an onAppear to register global NSEvent monitor
on_appear_code = """            )
            .onAppear {
                NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                    if isHovering {
                        if abs(event.scrollingDeltaX) > 2.0 {
                            let now = Date()
                            if now.timeIntervalSince(lastSwipeTime) > 0.4 {
                                DispatchQueue.main.async {
                                    lastSwipeTime = now
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        isExpanded = false
                                        if event.scrollingDeltaX > 0 { // Swipe Left -> Spotify
                                            bluetooth.showConnectionAlert = false
                                            showTrackPopup = true
                                            manualViewMode = "spotify"
                                        } else { // Swipe Right -> Bluetooth
                                            showTrackPopup = false
                                            bluetooth.showConnectionAlert = true
                                            manualViewMode = "bluetooth"
                                        }
                                    }
                                }
                            }
                            return nil // Consume event
                        }
                    }
                    return event
                }
            }
"""

text = text.replace("            )\n            .onTapGesture {", on_appear_code + "            .onTapGesture {")

# ensure spotify popup rendering runs when manualViewMode is swiped to 'spotify' over riding default tracking check
popup_cond = r"\} else if showTrackPopup && spotify\.trackName \!= \"No Music\" && spotify\.trackName \!= \"Spotify Closed\" \{"
new_popup_cond = "} else if (showTrackPopup && spotify.trackName != \"No Music\" && spotify.trackName != \"Spotify Closed\") || (showTrackPopup && manualViewMode == \"spotify\") {"
text = re.sub(popup_cond, new_popup_cond, text)

# ensure the overall window size stays correctly sized when 'spotify' forces pop up
frame_cond = r"showTrackPopup \? dynamicNotchHeight \+ 52 : dynamicNotchHeight"
new_frame_cond = "(showTrackPopup || manualViewMode == \"spotify\") ? dynamicNotchHeight + 52 : dynamicNotchHeight"
text = re.sub(frame_cond, new_frame_cond, text)

with open("dynamic island/ContentView.swift", "w") as f:
    f.write(text)
print("done")
