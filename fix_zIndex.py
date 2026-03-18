import re

with open("dynamic island/ContentView.swift", "r") as f:
    text = f.read()

# We need to find the specific chunk for Teams and change its `.transition` and `.zIndex`
# and add an ID.

pattern = re.compile(
    r'(\}\s*else if micMonitor\.isTeamsRunning\s*\{\n\s*//[^\n]*\n\s*HStack\s*\{.*?)(\.zIndex\([0-9]+\)\n\s*\.transition\([^)]+\))',
    re.DOTALL
)

match = pattern.search(text)
if match:
    replacement = match.group(1) + '.id("teams-active-view")\n                    .zIndex(3)\n                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))'
    new_text = text[:match.start()] + replacement + text[match.end():]
    with open("dynamic island/ContentView.swift", "w") as f:
        f.write(new_text)
    print("Fixed!")
else:
    print("Not found.")

