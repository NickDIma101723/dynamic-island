import Foundation
import IOBluetooth

let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] ?? []
for device in devices {
    print(device.name ?? "Unknown", device.isPaired())
    if device.isConnected() {
        print("Connected!")
    }
}
