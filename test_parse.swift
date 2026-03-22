import Foundation

func getBattery(deviceName: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
    process.arguments = ["SPBluetoothDataType"]
    
    let pipe = Pipe()
    process.standardOutput = pipe
    
    do {
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        print("Output string length: \(output.count)")
    } catch {
        print("Error")
    }
}
getBattery(deviceName: "test")
