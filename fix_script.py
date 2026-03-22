import re

with open("dynamic island/ContentView.swift", "r") as f:
    text = f.read()

print("Initial length:", len(text))
print("Has IOBluetooth?", "import IOBluetooth" in text)
print("Has ContentView?", "struct ContentView: View {" in text)

# ADD IOBluetooth
if "import IOBluetooth" not in text:
    text = text.replace("import SwiftUI", "import SwiftUI\nimport IOBluetooth")
    print("Replaced SwiftUI with IOBluetooth")

print("New length:", len(text))
