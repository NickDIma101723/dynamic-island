import Foundation
import CoreAudio

func isAnyMicRunning() -> Bool {
    var defaultInputDeviceID: AudioDeviceID = 0
    var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultInputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    
    AudioObjectGetPropertyData(UInt32(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize, &defaultInputDeviceID)
    
    var isRunning: UInt32 = 0
    propertySize = UInt32(MemoryLayout<UInt32>.size)
    propertyAddress.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere
    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal
    
    AudioObjectGetPropertyData(defaultInputDeviceID, &propertyAddress, 0, nil, &propertySize, &isRunning)
    return isRunning > 0
}

print(isAnyMicRunning())
