import sys

with open("dynamic island/ContentView.swift", "r") as f:
    text = f.read()

import re

# We will regex replace the entire MicMonitor class and replace it with our new class block
# We know `class MicMonitor: ObservableObject {` is start, and it stops right before `struct LiquidNotchShape: Shape {`
# Or better yet, I'll split by line numbers: get 1 to 10 inclusive, our new block, then line 142 to EOF.

with open("dynamic island/ContentView.swift", "r") as f:
    lines = f.readlines()
    
part1 = lines[:10]
part2 = lines[141:]

with open("new_micmonitor.swift", "r") as f:
    new_micmonitor = f.read()

with open("dynamic island/ContentView.swift", "w") as f:
    f.writelines(part1)
    f.write(new_micmonitor)
    f.write("\n")
    f.writelines(part2)

print("Swapped MicMonitor successfully!")
