import Cocoa

NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { event in
    print("global scroll: \(event.scrollingDeltaX)")
}
