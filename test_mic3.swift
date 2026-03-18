import AppKit
import CoreAudio

func anyMicActive() -> Bool {
    var propertySize: UInt32 = 0
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    
    // Get size
    var status = AudioObjectGetPropertyDataSize(UInt32(kAudioObjectSystemObject), &address, 0, nil, &propertySize)
    if status != noErr { return false }
    
    let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
    var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
    
    // Get devices
    status = AudioObjectGetPropertyData(UInt32(kAudioObjectSystemObject), &address, 0, nil, &propertySize, &deviceIDs)
    if status != noErr { return false }
    
    for deviceID in deviceIDs {
        // Check if it has input channels
        var streamInfoSize: UInt32 = 0
        var streamAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        status = AudioObjectGetPropertyDataSize(deviceID, &streamAddress, 0, nil, &streamInfoSize)
        if status != noErr || streamInfoSize == 0 { continue } // Not an input device
        
        // Check if it's running
        var isRunning: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        var runningAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        status = AudioObjectGetPropertyData(deviceID, &runningAddress, 0, nil, &size, &isRunning)
        if status == noErr && isRunning > 0 {
            return true
        }
    }
    return false
}

let apps = NSWorkspace.shared.runningApplications
let teams = apps.filter { $0.localizedName?.lowercased().contains("teams") == true }
print("Teams running: \(teams.count > 0) (\(teams.map { $0.localizedName ?? "" }.joined(separator: ", ")))")

print("Is Any Mic Active: \(anyMicActive())")