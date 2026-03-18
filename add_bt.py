import re

with open("dynamic island/ContentView.swift", "r") as f:
    text = f.read()

# Add IOBluetooth import
if "import IOBluetooth" not in text:
    text = text.replace("import SwiftUI", "import SwiftUI\nimport IOBluetooth")

bluetooth_manager_class = """
class BluetoothManager: NSObject, ObservableObject {
    @Published var newlyConnectedDevice: String? = nil
    @Published var showConnectionAlert = false
    
    // We register a callback when ANY bluetooth device connects
    override init() {
        super.init()
        IOBluetoothDevice.register(forConnectNotifications: self, selector: #selector(deviceConnected(_:device:)))
    }
    
    @objc func deviceConnected(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        // When a device connects, get its name (e.g. "Galaxy Buds Pro" or "Headphones")
        let deviceName = device.name ?? "Bluetooth Device"
        
        DispatchQueue.main.async {
            self.newlyConnectedDevice = deviceName
            self.showConnectionAlert = true
            
            // Hide the alert automatically after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                if self.newlyConnectedDevice == deviceName {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        self.showConnectionAlert = false
                    }
                }
            }
        }
    }
}
"""

if "class BluetoothManager" not in text:
    # Insert it right before ContentView
    text = text.replace("struct ContentView: View {", bluetooth_manager_class + "\nstruct ContentView: View {")

# Inject @StateObject into ContentView
if "var bluetooth = BluetoothManager()" not in text:
    text = text.replace("@StateObject private var spotify = SpotifyManager()", "@StateObject private var spotify = SpotifyManager()\n    @StateObject private var bluetooth = BluetoothManager()")


# Create the UI overlay! I'll insert it right at the top of the main ZStack.
ui_code = """
            // BLUETOOTH CONNECTION ALERT (Highest Priority)
            if bluetooth.showConnectionAlert, let deviceName = bluetooth.newlyConnectedDevice {
                HStack(spacing: 14) {
                    // Modern glowing headphone icon
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "headphones")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.blue)
                    }
                        
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connected")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.gray)
                        Text(deviceName)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .frame(height: dynamicNotchHeight + 40, alignment: .top)
                .id("bluetooth-alert")
                .zIndex(10) // Always on top
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.9)),
                    removal: .opacity.combined(with: .scale(scale: 0.9))
                ))
                
            } else """

# We need to insert this at the top of the ZStack if/else chain
text = text.replace("if showTrackPopup {", ui_code + "if showTrackPopup {", 1)

# Dynamically expand the width/height if Bluetooth is showing
text = re.sub(
    r"\.frame\(width: isExpanded \? 414 : \(showTrackPopup \? 300 : \(\(spotify\.trackName != \"No Music\" && spotify\.trackName != \"Spotify Closed\"\)",
    ".frame(width: isExpanded ? 414 : bluetooth.showConnectionAlert ? 320 : (showTrackPopup ? 300 : ((spotify.trackName != \"No Music\" && spotify.trackName != \"Spotify Closed\")",
    text
)

text = re.sub(
    r"height: isExpanded \? \(isVolumeExpanded \? 230 : 185\) : \(showTrackPopup \? dynamicNotchHeight \+ 52 : dynamicNotchHeight\)\)",
    "height: isExpanded ? (isVolumeExpanded ? 230 : 185) : (bluetooth.showConnectionAlert ? dynamicNotchHeight + 45 : (showTrackPopup ? dynamicNotchHeight + 52 : dynamicNotchHeight)))",
    text
)

with open("dynamic island/ContentView.swift", "w") as f:
    f.write(text)

