with open("dynamic island/ContentView.swift", "r") as f:
    text = f.read()

bad_str = """.frame(height: dynamicNotchHeight, alignment: .bottom)
                    .id("teams-active-view")
                    .id("teams-active-view")
                    .zIndex(3)
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))))"""

good_str = """.frame(height: dynamicNotchHeight, alignment: .bottom)
                    .id("teams-active-view")
                    .zIndex(3)
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))"""

text = text.replace(bad_str, good_str)
with open("dynamic island/ContentView.swift", "w") as f:
    f.write(text)
print("Done!")
