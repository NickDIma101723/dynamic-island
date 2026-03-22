//
//  dynamic_islandApp.swift
//  dynamic island
//

import SwiftUI

@main
struct dynamic_islandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class DynamicIslandPanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: NSPanel!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Our invisible window canvas will be large enough to hold the fully expanded island
        // meaning we NEVER need to dynamically resize the NSPanel bounds and will never hit constraints errors.
        let canvasWidth: CGFloat = 800
        let canvasHeight: CGFloat = 300
        
        // Creating the NSPanel with the exact specifications
        panel = DynamicIslandPanel(
            contentRect: NSRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        
        // Transparent layer
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        
        // Ensure SwiftUI hosting uses a proper clear base so hovers work but clicks pass naturally!
        let hostingView = NSHostingView(rootView: ContentView())
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hostingView
        
        // Ghosting Effect OVER the Menu Bar to prevent the system from stealing your mouse hover!
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        
        // Let macOS natively handle ignoring mouse clicks on transparent NSPanel pixels! 
        // This natively solves hover trapping without complex Event loop observers.
        panel.ignoresMouseEvents = false
        
        // Pin strictly rigidly to top center
        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            let x = (screenFrame.width / 2) - (canvasWidth / 2)
            let y = screenFrame.height - canvasHeight
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        panel.makeKeyAndOrderFront(nil)
    }
}


