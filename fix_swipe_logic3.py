import re
with open("dynamic island/ContentView.swift", "r") as f:
    text = f.read()

# Fix handleScroll logic to not set showTrackPopup = true on Swipe Right
old_swipe_right = """                                        } else { // Swipe Right -> Spotify
                                            bluetooth.showConnectionAlert = false
                                            showTrackPopup = true
                                            manualViewMode = "spotify"
                                        }"""
new_swipe_right = """                                        } else { // Swipe Right -> Spotify
                                            bluetooth.showConnectionAlert = false
                                            manualViewMode = "spotify"
                                        }"""
text = text.replace(old_swipe_right, new_swipe_right)

with open("dynamic island/ContentView.swift", "w") as f:
    f.write(text)
print("fixed swipe right logic")
