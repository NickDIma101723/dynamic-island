import Foundation
import IOBluetooth

let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] ?? []
for device in devices {
    print("Device: \(device.name ?? "Unnamed")")
    print(device.batteryInfo())
}
