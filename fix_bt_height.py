import re
with open("dynamic island/ContentView.swift", "r") as f:
    text = f.read()

# Fix height constraint to support bluetooth
if "bluetooth.showConnectionAlert" not in text[text.find("height: isExpanded"):text.find("height: isExpanded")+200]:
    text = text.replace(
        "height: isExpanded ? (isVolumeExpanded ? 230 : 185) : (showTrackPopup ? dynamicNotchHeight + 52 : dynamicNotchHeight))",
        "height: isExpanded ? (isVolumeExpanded ? 230 : 185) : (bluetooth.showConnectionAlert ? dynamicNotchHeight + 66 : (showTrackPopup ? dynamicNotchHeight + 52 : dynamicNotchHeight)))"
    )

with open("dynamic island/ContentView.swift", "w") as f:
    f.write(text)
print("done")
