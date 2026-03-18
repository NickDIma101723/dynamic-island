import re
with open("dynamic island/ContentView.swift", "r") as f:
    text = f.read()

# REVERT the huge popup logic if it is present
popup_cond = r"\} else if \(showTrackPopup && spotify\.trackName \!= \"No Music\" && spotify\.trackName \!= \"Spotify Closed\"\) \|\| \(showTrackPopup && manualViewMode == \"spotify\"\) \{"
orig_popup_cond = "} else if showTrackPopup && spotify.trackName != \"No Music\" && spotify.trackName != \"Spotify Closed\" {"
text = re.sub(popup_cond, orig_popup_cond, text)

frame_cond = r"\(showTrackPopup \|\| manualViewMode == \"spotify\"\) \? dynamicNotchHeight \+ 52 : dynamicNotchHeight"
orig_frame_cond = "(showTrackPopup) ? dynamicNotchHeight + 52 : dynamicNotchHeight"
text = re.sub(frame_cond, orig_frame_cond, text)

with open("dynamic island/ContentView.swift", "w") as f:
    f.write(text)
print("reverted popup overrides")
