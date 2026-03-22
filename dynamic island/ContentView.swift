
//
//  ContentView.swift
//  dynamic island
//

import SwiftUI
import WidgetKit
import IOBluetooth
import Speech
internal import Combine

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

class GeminiManager: ObservableObject {
    @Published var responseText: String = "Hi! How can I help you?"
    @Published var isChecking: Bool = false
    @Published var isListening: Bool = false
    
    private let apiKey = "AIzaSyC0gOEcq_4UeWKPYPLRMNnvtXkVZREOt1g"
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    func ask(prompt: String) {
        if prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return }
        
        DispatchQueue.main.async {
            self.isChecking = true
            self.responseText = "Thinking..."
        }
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\\(apiKey)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isChecking = false
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = json["candidates"] as? [[String: Any]],
                   let first = candidates.first,
                   let content = first["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let firstPart = parts.first,
                   let text = firstPart["text"] as? String {
                    self.responseText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    if let data = data, let jsonStr = String(data: data, encoding: .utf8) {
                        print("Gemini API Data: \(jsonStr)")
                        // Try to parse an error message
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let errorObj = json["error"] as? [String: Any],
                           let errMsg = errorObj["message"] as? String {
                            self.responseText = "API Error: \(errMsg)"
                        } else {
                            self.responseText = "Error: Invalid response format from Model."
                        }
                    } else if let error = error {
                        print("Gemini API Network Error: \(error)")
                        self.responseText = "Network Error: \(error.localizedDescription)"
                    } else {
                        self.responseText = "Unknown Error occurred."
                    }
                }
            }
        }.resume()
    }
    
    func toggleListening(onTextUpdate: @escaping (String) -> Void, onDone: @escaping (String) -> Void) {
        if audioEngine.isRunning {
             audioEngine.stop()
             recognitionRequest?.endAudio()
             isListening = false
             return
         }
         
         SFSpeechRecognizer.requestAuthorization { authStatus in
             DispatchQueue.main.async {
                 if authStatus == .authorized {
                     self.startListening(onTextUpdate: onTextUpdate, onDone: onDone)
                 } else {
                     self.responseText = "Speech recognition access denied."
                 }
             }
         }
    }
    
    private func startListening(onTextUpdate: @escaping (String) -> Void, onDone: @escaping (String) -> Void) {
        recognitionTask?.cancel()
        self.recognitionTask = nil
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
        
        isListening = true
        var finalString = ""
        
        self.responseText = "Listening..."
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            if let result = result {
                finalString = result.bestTranscription.formattedString
                onTextUpdate(finalString)
                isFinal = result.isFinal
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.isListening = false
                if !finalString.isEmpty && error == nil {
                    onDone(finalString)
                }
            }
        }
    }
}

struct ScrollDetector: NSViewRepresentable {
    var onScroll: (CGFloat) -> Void
    func makeNSView(context: Context) -> NSView {
         let view = ScrollHostView()
         view.onScroll = onScroll
         return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class ScrollHostView: NSView {
    var onScroll: ((CGFloat) -> Void)?
    override func scrollWheel(with event: NSEvent) {
         if abs(event.scrollingDeltaX) > 2.0 {
             onScroll?(event.scrollingDeltaX)
         }
         super.scrollWheel(with: event)
    }
}

class BluetoothManager: NSObject, ObservableObject {
    @Published var newlyConnectedDevice: String? = nil
    @Published var showConnectionAlert = false
    
    @Published var batteryLeft: Int? = nil
    @Published var batteryRight: Int? = nil
    @Published var batteryCase: Int? = nil
    @Published var batterySingle: Int? = nil
    
    var hasConnectedDevice: Bool {
        if let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
            return devices.contains(where: { $0.isConnected() })
        }
        return false
    }
    
    override init() {
        super.init()
        IOBluetoothDevice.register(forConnectNotifications: self, selector: #selector(deviceConnected(_:device:)))
    }
    
    func checkLatestConnectedDevice() {
        if let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
            if let connected = devices.first(where: { $0.isConnected() }) {
                let name = connected.name ?? "Headphones"
                DispatchQueue.main.async {
                    self.newlyConnectedDevice = name
                }
                DispatchQueue.global(qos: .userInitiated).async {
                    self.fetchBatteryLevels(for: name)
                }
            }
        }
    }
    
    @objc func deviceConnected(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        let deviceName = device.name ?? "Bluetooth Device"
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.fetchBatteryLevels(for: deviceName)
            
            DispatchQueue.main.async {
                self.newlyConnectedDevice = deviceName
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    self.showConnectionAlert = true
                }
                
                // Hide the alert automatically after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    if self.newlyConnectedDevice == deviceName {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            self.showConnectionAlert = false
                        }
                    }
                }
            }
        }
    }
    
    private func fetchBatteryLevels(for name: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPBluetoothDataType"]
        let pipe = Pipe()
        process.standardOutput = pipe
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                parseBattery(from: output, targetDevice: name)
            }
        } catch {
            print("Failed to query battery")
        }
    }
    
    private func parseBattery(from output: String, targetDevice: String) {
        var foundDevice = false
        var bLeft: Int? = nil
        var bRight: Int? = nil
        var bCase: Int? = nil
        var bSingle: Int? = nil
        
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).hasSuffix(":") {
                // If we hit a new device block, check if we're already parsing the target
                if foundDevice { break }
                let blockName = line.replacingOccurrences(of: ":", with: "").trimmingCharacters(in: .whitespaces)
                if blockName == targetDevice {
                    foundDevice = true
                }
                continue
            }
            
            if foundDevice {
                let lowerLine = line.lowercased()
                if lowerLine.contains("battery level left:") || lowerLine.contains("left battery level:") {
                    bLeft = extractPercentage(from: line)
                } else if lowerLine.contains("battery level right:") || lowerLine.contains("right battery level:") {
                    bRight = extractPercentage(from: line)
                } else if lowerLine.contains("battery level case:") || lowerLine.contains("case battery level:") {
                    bCase = extractPercentage(from: line)
                } else if lowerLine.contains("battery level:") || lowerLine.contains("battery:") {
                    bSingle = extractPercentage(from: line)
                }
            }
        }
        
        DispatchQueue.main.async {
            self.batteryLeft = bLeft
            self.batteryRight = bRight
            self.batteryCase = bCase
            self.batterySingle = bSingle
        }
    }
    
    private func extractPercentage(from string: String) -> Int? {
        let pattern = "(\\d+)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.count)) {
            if let range = Range(match.range(at: 1), in: string) {
                return Int(string[range])
            }
        }
        return nil
    }
}

import AVFoundation

class MicMonitor: ObservableObject {
    @Published var micLevel: CGFloat = 0.0
    @Published var isTeamsRunning: Bool = false {
        didSet {
            if isTeamsRunning && !oldValue {
                startMonitoring()
            } else if !isTeamsRunning && oldValue {
                stopMonitoring()
            }
        }
    }
    @Published var callDuration: TimeInterval = 0
    @Published var teamsIcon: NSImage? = nil

    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private var durationTimer: Timer?

    private var fileDescriptor: CInt = -1
    private var dispatchSource: DispatchSourceFileSystemObject?
    private var lastReadOffset: UInt64 = 0
    private var logFilePath: String = ""

    init() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.teams") ?? NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.teams2") {
            self.teamsIcon = NSWorkspace.shared.icon(forFile: url.path)
        }

        self.logFilePath = NSString(string: "~/Library/Application Support/Microsoft/Teams/logs.txt").expandingTildeInPath
        setupLogMonitoring()
    }

    private func setupLogMonitoring() {
        if !FileManager.default.fileExists(atPath: logFilePath) {
            print("Teams log file not found at \(logFilePath)")
        }

        fileDescriptor = open(logFilePath, O_EVTONLY)
        guard fileDescriptor != -1 else { return }

        if let attrs = try? FileManager.default.attributesOfItem(atPath: logFilePath),
           let size = attrs[.size] as? UInt64 {
            lastReadOffset = size
        }

        dispatchSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write],
            queue: DispatchQueue.global(qos: .background)
        )

        dispatchSource?.setEventHandler { [weak self] in
            self?.readNewLogEntries()
        }

        dispatchSource?.setCancelHandler { [weak self] in
            guard let self = self else { return }
            close(self.fileDescriptor)
            self.fileDescriptor = -1
        }

        dispatchSource?.resume()
    }

    private func readNewLogEntries() {
        guard let fileHandle = FileHandle(forReadingAtPath: logFilePath) else { return }
        defer { try? fileHandle.close() }

        do {
            try fileHandle.seek(toOffset: lastReadOffset)
            let newData = fileHandle.readDataToEndOfFile()

            if let attrs = try? FileManager.default.attributesOfItem(atPath: logFilePath),
               let size = attrs[.size] as? UInt64 {
                lastReadOffset = size
            }

            guard let newText = String(data: newData, encoding: .utf8) else { return }

            let lines = newText.components(separatedBy: .newlines)
            for line in lines {
                if line.contains("eventData: s::;m::1;a::1") || line.contains("state changed to Active") {
                    DispatchQueue.main.async { if !self.isTeamsRunning { self.isTeamsRunning = true } }
                } else if line.contains("eventData: s::;m::0;a::0") || line.contains("state changed to Ended") {
                    DispatchQueue.main.async { if self.isTeamsRunning { self.isTeamsRunning = false } }
                }
            }
        } catch {}
    }

    private func startMonitoring() {
        self.callDuration = 0
        self.durationTimer?.invalidate()
        self.durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.callDuration += 1 }
        }

        let url = URL(fileURLWithPath: "/dev/null")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            levelTimer?.invalidate()
            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                guard let self = self, let recorder = self.audioRecorder else { return }
                recorder.updateMeters()
                let power = recorder.averagePower(forChannel: 0)
                let level = max(0.0, CGFloat(power + 45) / 45.0) 

                DispatchQueue.main.async {
                    self.micLevel = level
                }
            }
        } catch {
            print("Microphone error: \(error.localizedDescription)")
        }
    }

    private func stopMonitoring() {
        levelTimer?.invalidate()
        durationTimer?.invalidate()
        audioRecorder?.stop()
        audioRecorder = nil
        micLevel = 0.0
    }

    deinit {
        dispatchSource?.cancel()
    }
}

// Ensure we use a custom shape to create the organic "fillet" curves at the top that perfectly match the hardware notch.
struct LiquidNotchShape: Shape {
    var bottomRadius: CGFloat
    // The inverse radius curve merging into the bezel
    var topFillet: CGFloat
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(bottomRadius, topFillet) }
        set {
            bottomRadius = newValue.first
            topFillet = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let r = bottomRadius
        let f = topFillet
        
        // Start top-left
        path.move(to: CGPoint(x: 0, y: 0))
        // Concave curve connecting top bezel to vertical edge
        path.addQuadCurve(to: CGPoint(x: f, y: f), control: CGPoint(x: f, y: 0))
        
        // Left straight edge down to bottom rounding
        path.addLine(to: CGPoint(x: f, y: h - r))
        
        // Bottom-left convex curve
        path.addQuadCurve(to: CGPoint(x: f + r, y: h), control: CGPoint(x: f, y: h))
        
        // Bottom straight edge
        path.addLine(to: CGPoint(x: w - f - r, y: h))
        
        // Bottom-right convex curve
        path.addQuadCurve(to: CGPoint(x: w - f, y: h - r), control: CGPoint(x: w - f, y: h))
        
        // Right straight edge up
        path.addLine(to: CGPoint(x: w - f, y: f))
        
        // Concave curve connecting vertical edge back to top bezel
        path.addQuadCurve(to: CGPoint(x: w, y: 0), control: CGPoint(x: w - f, y: 0))
        
        // Close back across the top bezel line
        path.addLine(to: CGPoint(x: 0, y: 0))
        
        return path
    }
}

struct ContentView: View {
    @State private var isExpanded = false
    @State private var isHovering = false
    @State private var isWaveHovering = false
    @State private var dynamicNotchHeight: CGFloat = 34 // Mac notch is usually 32-34
    
    // Exact dimensions
    let baseNotchWidth: CGFloat = 208
    let notchCornerRadius: CGFloat = 12
    
    @StateObject private var spotify = SpotifyManager()
    @StateObject private var bluetooth = BluetoothManager()
    @StateObject private var micMonitor = MicMonitor()
    @StateObject private var gemini = GeminiManager()
    
    @State private var geminiPrompt: String = ""
    @FocusState private var geminiFocused: Bool
    @State private var manualViewMode: String = "auto"
    @State private var lastSwipeTime: Date = Date()
    @State private var isVolumeExpanded = false
    @State private var editingPosition: Double = 0.0
    @State private var isEditingPosition: Bool = false
    
    @State private var showTrackPopup: Bool = false
    @State private var popupCounter: Int = 0
    
    // Using a timer guarantees 0 accessibility permission alerts, no main-thread 120hz flood, and no freezing.
    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect() // 60fps tracking for perfectly smooth hover
    
    var body: some View {
        // Encase in a container that fills the entire NSPanel frame but aligns elements to the top.
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                // To blend perfectly with the hardware notch, it must be pure pitch black.
                LiquidNotchShape(
                    bottomRadius: isExpanded ? 46 : (showTrackPopup ? 26 : notchCornerRadius),
                    topFillet: isExpanded ? 24 : 12
                )
                .fill(Color.black)
                .shadow(color: Color.black.opacity(isHovering || isExpanded ? 0.35 : 0.15), radius: isHovering || isExpanded ? 12 : 6, x: 0, y: isHovering || isExpanded ? 6 : 2)
                .zIndex(0)
                
                // Show contents ONLY when clicked/expanded
                if isExpanded {
                    VStack(spacing: 0) {
                        // 1. Top Section: Art and Titles
                        HStack(alignment: .center, spacing: 14) {
                            // Album Artwork
                            if let cover = spotify.coverImage {
                                Image(nsImage: cover)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 44, height: 44)
                                    .cornerRadius(10)
                                    .id("expanded-\(spotify.flipID)")
                                    .transition(.albumFlip)
                                    .scaleEffect(spotify.isPlaying ? 1.0 : 0.8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.black.opacity(spotify.isPlaying ? 0.0 : 0.4))
                                    )
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: spotify.isPlaying)
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 44, height: 44)
                                    .id("expanded-none-\(spotify.flipID)")
                                    .transition(.albumFlip)
                                    .scaleEffect(spotify.isPlaying ? 1.0 : 0.8)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white.opacity(0.6))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.black.opacity(spotify.isPlaying ? 0.0 : 0.4))
                                    )
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: spotify.isPlaying)
                            }
                            
                            // Text Meta Data
                            VStack(alignment: .leading, spacing: 2) {
                                Text(spotify.trackName)
                                    .foregroundColor(Color.white)
                                    .font(.system(size: 14, weight: .semibold))
                                    .lineLimit(1)
                                
                                Text(spotify.artistName.isEmpty ? "Spotify" : spotify.artistName)
                                    .foregroundColor(Color(white: 0.6))
                                    .font(.system(size: 13, weight: .medium))
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            // Dynamic Waveform "Sound beat"
                            WaveformView(isPlaying: spotify.isPlaying, color: spotify.songColor)
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 8) // Moved significantly closer to the top
                        
                        // 2. Progress / Loadbar
                        HStack(spacing: 12) {
                            Text(formatTime(spotify.position))
                                .font(.system(size: 13, weight: .medium, design: .default))
                                .foregroundColor(Color(white: 0.6))
                            
                            CustomProgressBar(position: spotify.position, total: spotify.duration, onSeek: { newPos in
                                spotify.seek(to: newPos)
                            })
                            
                            Text("-" + formatTime(max(0, spotify.duration - spotify.position)))
                                .font(.system(size: 13, weight: .medium, design: .default))
                                .foregroundColor(Color(white: 0.6))
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 14) // Balanced middle padding
                        
                        // 3. Media Controls
                        HStack(spacing: 24) {
                            Button(action: { /* Toggle Shuffle */ }) {
                                Image(systemName: "shuffle")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(white: 0.5))
                            }.buttonStyle(.plain)
                            
                            Button(action: { spotify.previousTrack() }) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }.buttonStyle(.plain)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                    spotify.isPlaying.toggle() // Optimistic UI update
                                }
                                spotify.playPause()
                            }) {
                                Image(systemName: spotify.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }.buttonStyle(.plain)
                            
                            Button(action: { spotify.nextTrack() }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }.buttonStyle(.plain)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                    isVolumeExpanded.toggle()
                                }
                            }) {
                                Image(systemName: "macbook")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isVolumeExpanded ? .green : Color(white: 0.5))
                            }.buttonStyle(.plain)
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 14)
                        .padding(.bottom, isVolumeExpanded ? 10 : 24)
                        
                        // Volume Slider
                        if isVolumeExpanded {
                            HStack {
                                CustomVolumeSlider(volume: Binding(
                                    get: { spotify.volume },
                                    set: { v in spotify.volume = v }
                                ), onEditingChanged: { v in
                                    spotify.setVolume(v)
                                })
                            }
                            .padding(.horizontal, 32)
                            .padding(.bottom, 24)
                            .transition(.contentReveal)
                        }
                    }
                    .zIndex(1)
                    .transition(.contentReveal)
                } else if bluetooth.showConnectionAlert || manualViewMode == "bluetooth" {
                    let deviceName = bluetooth.newlyConnectedDevice ?? "Headphones"
                    // BLUETOOTH CONNECTION ALERT
                    HStack(spacing: 16) {
                        // Clean, minimal native-looking device icon
                        Image(systemName: deviceName.lowercased().contains("buds") ? "headphones.circle.fill" : (deviceName.lowercased().contains("airpods") ? "airpods.gen3" : "headphones"))
                            .font(.system(size: 38, weight: .regular))
                            .foregroundStyle(Color.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(deviceName)
                                .font(.system(size: 15, weight: .semibold, design: .default))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            // Real, Dynamic Battery Indicators
                            if bluetooth.batteryLeft != nil || bluetooth.batteryRight != nil || bluetooth.batteryCase != nil || bluetooth.batterySingle != nil {
                                HStack(spacing: 12) {
                                    if let bl = bluetooth.batteryLeft {
                                        HStack(spacing: 4) {
                                            Text("L")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(Color(white: 0.5))
                                            Image(systemName: bl > 20 ? "battery.100" : "battery.25")
                                                .symbolRenderingMode(.palette)
                                                .foregroundStyle(Color(white: 0.5), bl > 20 ? .green : .red)
                                                .font(.system(size: 12))
                                            Text("\(bl)%")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    if let br = bluetooth.batteryRight {
                                        HStack(spacing: 4) {
                                            Text("R")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(Color(white: 0.5))
                                            Image(systemName: br > 20 ? "battery.100" : "battery.25")
                                                .symbolRenderingMode(.palette)
                                                .foregroundStyle(Color(white: 0.5), br > 20 ? .green : .red)
                                                .font(.system(size: 12))
                                            Text("\(br)%")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    if let bc = bluetooth.batteryCase {
                                        HStack(spacing: 4) {
                                            Image(systemName: bc > 20 ? "battery.100" : "battery.25")
                                                .symbolRenderingMode(.palette)
                                                .foregroundStyle(Color(white: 0.5), bc > 20 ? .green : .red)
                                                .font(.system(size: 13))
                                            Text("Case \(bc)%")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(Color(white: 0.5))
                                        }
                                    }
                                    
                                    if bluetooth.batteryLeft == nil && bluetooth.batteryRight == nil, let bs = bluetooth.batterySingle {
                                        HStack(spacing: 4) {
                                            Image(systemName: bs > 20 ? "battery.100" : "battery.25")
                                                .symbolRenderingMode(.palette)
                                                .foregroundStyle(Color(white: 0.5), bs > 20 ? .green : .red)
                                                .font(.system(size: 13))
                                            Text("\(bs)%")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(Color.white)
                                        }
                                    }
                                }
                                .padding(.top, 2)
                            } else {
                                // Searching/Connected state fallback when battery is still fetching or not available
                                Text("Connected")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color(white: 0.6))
                                    .padding(.top, 2)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, dynamicNotchHeight + 6)
                    .frame(height: dynamicNotchHeight + 66, alignment: .top)
                    .id("bluetooth-alert")
                    .zIndex(10) // Always on top
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.9)),
                        removal: .opacity.combined(with: .scale(scale: 0.9))
                    ))
                } else if manualViewMode == "gemini" {
                    // GEMINI AI UI
                    VStack(alignment: .leading, spacing: 14) {
                        ScrollView {
                            Text(gemini.responseText)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                        .frame(maxHeight: 180)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 18))
                                .foregroundStyle(.blue, .purple)
                                .symbolRenderingMode(.palette)
                                .shadow(color: .purple.opacity(0.6), radius: 5)
                            
                            TextField("Message Gemini...", text: $geminiPrompt, onCommit: {
                                gemini.ask(prompt: geminiPrompt)
                            })
                            .focused($geminiFocused)
                            .onChange(of: manualViewMode) { oldView, newView in
                                if newView == "gemini" {
                                    if #available(macOS 14.0, *) {
                                        NSApp.activate()
                                    } else {
                                        NSApp.activate(ignoringOtherApps: true)
                                    }
                                    NSApp.windows.first?.makeKey()
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        geminiFocused = true
                                    }
                                } else {
                                    geminiFocused = false
                                }
                            }
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            
                            Button(action: {
                                gemini.toggleListening(onTextUpdate: { text in
                                    geminiPrompt = text
                                }, onDone: { text in
                                    gemini.ask(prompt: text)
                                })
                            }) {
                                Image(systemName: gemini.isListening ? "mic.fill" : "mic")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(gemini.isListening ? .red : .white.opacity(0.8))
                                    .padding(8)
                                    .background(gemini.isListening ? Color.red.opacity(0.2) : Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        Spacer(minLength: 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, dynamicNotchHeight + 10)
                    .frame(width: 360, height: dynamicNotchHeight + 168, alignment: .top)
                    .zIndex(10)
                    .transition(.contentReveal)
                } else if showTrackPopup && spotify.trackName != "No Music" && spotify.trackName != "Spotify Closed" {
                    // "Now Playing" Notification Popup
                    VStack(spacing: 0) {
                        HStack {
                            if let cover = spotify.coverImage {
                                Image(nsImage: cover)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 26, height: 26)
                                    .cornerRadius(6)
                                    .id("popup-\(spotify.flipID)")
                                    .transition(.albumFlip)
                            } else {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 26, height: 26)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.6))
                                    )
                                    .id("popup-none-\(spotify.flipID)")
                                    .transition(.albumFlip)
                            }
                            
                            Spacer()
                            
                            WaveformView(isPlaying: spotify.isPlaying, color: spotify.songColor)
                                .frame(width: 24)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .padding(.bottom, 6)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "music.note")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            MarqueeText(
                                text: "\(spotify.trackName) • \(spotify.artistName)",
                                font: .system(size: 14, weight: .medium),
                                maxWidth: 230
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                        .padding(.bottom, 14)
                    }
                    .frame(height: dynamicNotchHeight + 52, alignment: .top)
                    .zIndex(2)
                    .transition(.contentReveal)
                    
                } else if micMonitor.isTeamsRunning {
                    // Small collapsed view for Active Call (Teams)
                    HStack {
                        if let customIcon = micMonitor.teamsIcon {
                            Image(nsImage: customIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                                .cornerRadius(4)
                        } else {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 14))
                        }
                        
                        Text(formatTime(micMonitor.callDuration))
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.green)
                            .padding(.leading, 4)
                        
                        Spacer()
                        
                        // It uses the genuine microphone level amplitude!
                        CallWaveformView(micLevel: micMonitor.micLevel)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, (dynamicNotchHeight - 16) / 2) // visually center in hardware notch height
                    .frame(height: dynamicNotchHeight, alignment: .bottom)
                    .id("teams-active-view")
                    .zIndex(3)
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                } else if spotify.trackName != "No Music" && spotify.trackName != "Spotify Closed" && spotify.isPlaying {
                    // 1. HIGHEST PRIORITY: If music is ACTIVELY PLAYING, NEVER hide it.
                    // Small collapsed view with album art and waveform
                    HStack {
                        if let cover = spotify.coverImage {
                            Image(nsImage: cover)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 20, height: 20)
                                .cornerRadius(5)
                                .id("collapsed-top-\(spotify.flipID)")
                                .transition(.albumFlip)
                        } else {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.6))
                                )
                                .id("collapsed-none-top-\(spotify.flipID)")
                                .transition(.albumFlip)
                        }
                        
                        Spacer()
                        
                        ZStack {
                            if isWaveHovering {
                                Button(action: {
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                        spotify.isPlaying.toggle() // Optimistic UI update
                                    }
                                    spotify.playPause()
                                }) {
                                    Image(systemName: spotify.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundColor(spotify.songColor)
                                        .frame(width: 24, height: 24)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .transition(.opacity.combined(with: .scale))
                            } else {
                                WaveformView(isPlaying: spotify.isPlaying, color: spotify.songColor)
                                    .frame(width: 24, height: 24)
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isWaveHovering = hovering
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, (dynamicNotchHeight - 20) / 2)
                    .frame(height: dynamicNotchHeight, alignment: .bottom)
                    .zIndex(1)
                    .transition(.contentReveal)
                
                    
                } else if spotify.trackName != "No Music" && spotify.trackName != "Spotify Closed" {
                    // Small collapsed view with album art and waveform
                    HStack {
                        if let cover = spotify.coverImage {
                            Image(nsImage: cover)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 20, height: 20)
                                .cornerRadius(5)
                                .id("collapsed-\(spotify.flipID)") // Prevent weird flipping animation on track change
                                .transition(.albumFlip)
                        } else {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.6))
                                )
                                .id("collapsed-none-\(spotify.flipID)")
                                .transition(.albumFlip)
                        }
                        
                        Spacer()
                        
                        ZStack {
                            if isWaveHovering {
                                Button(action: {
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                        spotify.isPlaying.toggle() // Optimistic UI update
                                    }
                                    spotify.playPause()
                                }) {
                                    Image(systemName: spotify.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundColor(spotify.songColor)
                                        .frame(width: 24, height: 24)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .transition(.opacity.combined(with: .scale))
                            } else {
                                WaveformView(isPlaying: spotify.isPlaying, color: spotify.songColor)
                                    .frame(width: 24, height: 24)
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isWaveHovering = hovering
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, (dynamicNotchHeight - 20) / 2) // visually center in hardware notch height
                    .frame(height: dynamicNotchHeight, alignment: .bottom)
                    .zIndex(1)
                    .transition(.contentReveal)
                }
            }
            .contentShape(Rectangle())
            // Dynamic heights for expansion
            .frame(width: isExpanded ? 414 : (manualViewMode == "gemini" ? 380 : (showTrackPopup ? 300 : (micMonitor.isTeamsRunning ? 208 : ((spotify.trackName != "No Music" && spotify.trackName != "Spotify Closed") ? 276 : baseNotchWidth)))),
                   height: isExpanded ? (isVolumeExpanded ? 230 : 185) : (manualViewMode == "gemini" ? dynamicNotchHeight + 168 : ((bluetooth.showConnectionAlert || manualViewMode == "bluetooth") ? dynamicNotchHeight + 66 : (showTrackPopup ? dynamicNotchHeight + 52 : dynamicNotchHeight))))
            .scaleEffect((isHovering && !showTrackPopup && !isExpanded) ? 1.06 : 1.0, anchor: .top)
            .background(ScrollDetector { deltaX in
                let now = Date()
                if now.timeIntervalSince(lastSwipeTime) > 0.4 {
                    lastSwipeTime = now
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isExpanded = false
                        if deltaX > 0 && bluetooth.hasConnectedDevice { // Drag Left -> Bluetooth
                            bluetooth.checkLatestConnectedDevice()
                            bluetooth.showConnectionAlert = true
                            manualViewMode = "bluetooth"
                        } else if deltaX <= 0 { // Drag Right -> Spotify
                            bluetooth.showConnectionAlert = false
                            manualViewMode = "auto"
                        }
                    }
                }
            })
            .gesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .local)
                    .onEnded { value in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isExpanded = false
                            if abs(value.translation.height) > abs(value.translation.width) && abs(value.translation.height) > 10 {
                                if value.translation.height > 10 {
                                    manualViewMode = "gemini"
                                } else {
                                    manualViewMode = "auto"
                                }
                            } else if value.translation.width < 0 && bluetooth.hasConnectedDevice { 
                                bluetooth.checkLatestConnectedDevice()
                                bluetooth.showConnectionAlert = true
                                manualViewMode = "bluetooth"
                            } else if value.translation.width >= 0 {
                                bluetooth.showConnectionAlert = false
                                manualViewMode = "auto"
                            }
                        }
                    }
            )
            .onAppear {
                let handleScroll: (NSEvent) -> Void = { event in
                    if isHovering {
                        if abs(event.scrollingDeltaX) > 2.0 || abs(event.scrollingDeltaY) > 2.0 {
                            let now = Date()
                            if now.timeIntervalSince(lastSwipeTime) > 0.4 {
                                DispatchQueue.main.async {
                                    lastSwipeTime = now
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        isExpanded = false
                                        if abs(event.scrollingDeltaY) > abs(event.scrollingDeltaX) && abs(event.scrollingDeltaY) > 2.0 {
                                            if event.scrollingDeltaY > 2.0 {
                                                manualViewMode = "gemini"
                                            } else {
                                                manualViewMode = "auto"
                                            }
                                        } else if event.scrollingDeltaX > 0 && bluetooth.hasConnectedDevice { // Swipe Left -> Bluetooth
                                            bluetooth.checkLatestConnectedDevice()
                                            bluetooth.showConnectionAlert = true
                                            manualViewMode = "bluetooth"
                                        } else if event.scrollingDeltaX <= 0 { // Swipe Right -> Spotify
                                            bluetooth.showConnectionAlert = false
                                            manualViewMode = "auto"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                    handleScroll(event)
                    if isHovering && (abs(event.scrollingDeltaX) > 2.0 || abs(event.scrollingDeltaY) > 2.0) { return nil }
                    return event
                }
                
                NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { event in
                    handleScroll(event)
                }
            }
            .onTapGesture {
                if !isExpanded {
                    // Snappy, Apple-like dynamic island elastic expansion
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                        isExpanded = true
                    }
                }
            }
            
            // Provides invisible empty space to fill the rest of the NSPanel so layout remains stable
            Spacer()
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            detectNotchMetrics()
        }
        .onReceive(timer) { _ in
            checkMouseLocation()
        }
        .onChange(of: spotify.flipID, initial: false) { _, _ in
            if spotify.trackName != "No Music" && spotify.trackName != "Spotify Closed" {
                triggerPopup()
            }
        }
        .ignoresSafeArea()
    }
    
    private func triggerPopup() {
        // Prevent interfering if the menu is fully expanded manually
        guard !isExpanded else { return }
        
        popupCounter += 1
        let currentCounter = popupCounter
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showTrackPopup = true
        }
        
        // Hide after 1.5 seconds (quicker, snappier feel)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if self.popupCounter == currentCounter && !self.isExpanded {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.showTrackPopup = false
                }
            }
        }
    }
    
    // Mathematically calculates mouse position against the absolute screen pixels.
    // This makes it completely immune to Apple's notch physically hiding the cursor!
    private func checkMouseLocation() {
        let mouseLocation = NSEvent.mouseLocation
        if let screen = NSScreen.main {
            // NSEvent sets y=0 at the absolute bottom of the screen. We invert it to check distance from the top menu bar.
            let yFromTop = screen.frame.height - mouseLocation.y
            let midX = screen.frame.width / 2
            
            let activeCollapsedWidth: CGFloat = (spotify.trackName != "No Music" && spotify.trackName != "Spotify Closed") ? 276 : baseNotchWidth
            let checkWidth: CGFloat = isExpanded ? 434 : (showTrackPopup ? 320 : (activeCollapsedWidth + 20))
            let checkHeight: CGFloat = isExpanded ? (isVolumeExpanded ? 240 : 195) : (showTrackPopup ? dynamicNotchHeight + 72 : 45)
            
            let isWithinX = mouseLocation.x >= (midX - checkWidth/2) && mouseLocation.x <= (midX + checkWidth/2)
            let isWithinY = yFromTop >= 0 && yFromTop <= checkHeight
            
            let shouldHover = isWithinX && isWithinY
            
            if isHovering != shouldHover {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    isHovering = shouldHover
                    if !shouldHover {
                        // When mouse leaves, close the menu completely
                        isExpanded = false
                        isVolumeExpanded = false
                        showTrackPopup = false // Fix the popup bug where it gets stuck natively!
                    }
                }
            }
        }
    }
    
    private func detectNotchMetrics() {
        if let mainScreen = NSScreen.main {
            let topInset = mainScreen.safeAreaInsets.top
            if topInset > 24 {
                dynamicNotchHeight = topInset
            }
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        guard time.isFinite && !time.isNaN else { return "0:00" }
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

/*
 IMPORTANT:
 To allow this class to use NSAppleScript to control/query Spotify, you must add the following key
 to your App's Info.plist (or under the "Info" tab in Xcode target settings):
 
 Key: NSAppleEventsUsageDescription
 Value: "This app requires access to Spotify to display the current playing track."
 
 Additionally, if you have the "App Sandbox" enabled in "Signing & Capabilities", you must either:
 1. Remove the "App Sandbox" completely, OR
 2. Add an Apple Events temporary exception entitlement for "com.spotify.client"
*/
class SpotifyManager: ObservableObject {
    @Published var trackName: String = "Not Playing"
    @Published var artistName: String = ""
    @Published var coverImage: NSImage? = nil
    @Published var songColor: Color = .green
    @Published var isPlaying: Bool = false
    @Published var position: Double = 0.0
    @Published var duration: Double = 1.0
    @Published var isShuffling: Bool = false
    @Published var volume: Double = 50.0
    @Published var flipID: UUID = UUID()
    
    private var lastArtUrl: String = ""
    private var isFetching: Bool = false
    private var lastSeekTime: Date = Date.distantPast
    
    init() {
        // Fetch initially
        fetchSpotifyData()
        
        // Listen instantly for changes via DistributedNotificationCenter
        let notificationName = NSNotification.Name("com.spotify.client.PlaybackStateChanged")
        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(spotifyPlaybackStateChanged(_:)),
            name: notificationName,
            object: nil
        )
        
        // Let's also attach a slow fallback timer just in case notifications are missed
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.fetchSpotifyData()
        }
    }
    
    deinit {
        DistributedNotificationCenter.default.removeObserver(self)
    }
    
    @objc private func spotifyPlaybackStateChanged(_ notification: Notification) {
        // Trigger fetch immediately when Spotify announces a state change
        fetchSpotifyData()
    }
    
    @objc private func fetchSpotifyData() {
        if isFetching { return }
        isFetching = true
        
        let scriptString = """
        if application "Spotify" is running then
            tell application "Spotify"
                try
                    set tState to player state as string
                    if tState is "playing" or tState is "paused" then
                        set tName to name of current track
                        set tArtist to artist of current track
                        set tArtUrl to artwork url of current track
                        set tPos to player position as string
                        set tDur to (duration of current track) / 1000 as string
                        set tShuff to shuffling as string
                        set tVol to sound volume as string
                        return tState & "|" & tName & "|" & tArtist & "|" & tArtUrl & "|" & tPos & "|" & tDur & "|" & tShuff & "|" & tVol
                    else
                        return "stopped"
                    end if
                on error
                    return "error"
                end try
            end tell
        else
            return "not_running"
        end if
        """
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            var error: NSDictionary?
            let outputValue = NSAppleScript(source: scriptString)?.executeAndReturnError(&error).stringValue ?? "error"
            
            DispatchQueue.main.async {
                self.isFetching = false
                
                if outputValue == "not_running" || outputValue == "stopped" || outputValue == "error" {
                    withAnimation {
                        self.isPlaying = false
                        self.trackName = if outputValue == "not_running" { "Spotify Closed" } else { "No Music" }
                        self.artistName = "Spotify"
                        self.coverImage = nil
                        self.songColor = .green
                    }
                    self.lastArtUrl = ""
                    return
                }
                
                let parts = outputValue.components(separatedBy: "|")
                if parts.count >= 8 {
                    withAnimation {
                        self.isPlaying = (parts[0] == "playing")
                        self.trackName = parts[1]
                        self.artistName = parts[2]
                        let fetchedPos = Double(parts[4].replacingOccurrences(of: ",", with: ".")) ?? 0.0
                        if Date().timeIntervalSince(self.lastSeekTime) > 1.5 {
                            self.position = fetchedPos
                        }
                        self.duration = max(Double(parts[5].replacingOccurrences(of: ",", with: ".")) ?? 1.0, 1.0)
                        self.isShuffling = (parts[6] == "true")
                        self.volume = Double(parts[7].replacingOccurrences(of: ",", with: ".")) ?? 50.0
                        
                        // Update Widget
                        if let defaults = UserDefaults(suiteName: "group.dynamic_island") {
                            defaults.set(self.trackName, forKey: "spotify_trackName")
                            defaults.set(self.artistName, forKey: "spotify_artistName")
                            defaults.set(self.isPlaying, forKey: "spotify_isPlaying")
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                    }
                    
                    let artUrl = parts[3]
                    if artUrl != self.lastArtUrl, let url = URL(string: artUrl) {
                        self.lastArtUrl = artUrl
                        self.fetchImage(url: url)
                    }
                }
            }
        }
    }
    
    private func fetchImage(url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = NSImage(data: data) {
                let col = image.averageColor ?? .green
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        self.coverImage = image
                        self.songColor = col
                        self.flipID = UUID() // Trigger the transition only when image is ready
                        
                        // Save to Widget Shared Storage
                        if let defaults = UserDefaults(suiteName: "group.dynamic_island") {
                            defaults.set(data, forKey: "spotify_coverData")
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Controls
    private func executeCommand(_ cmd: String) {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                \(cmd)
            end tell
        end if
        """
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var error: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self?.fetchSpotifyData()
            }
        }
    }
    
    func playPause() {
        self.lastSeekTime = Date() // Prevent immediate overwrite from AppleScript lag
        executeCommand("playpause")
    }
    func nextTrack() { executeCommand("next track") }
    func previousTrack() { executeCommand("previous track") }
    func toggleShuffle() { executeCommand("set shuffling to not (get shuffling)") }
    func setVolume(_ vol: Double) { executeCommand("set sound volume to \(Int(vol))") }
    func seek(to pos: Double) {
        self.position = pos
        self.lastSeekTime = Date()
        executeCommand("set player position to \(Int(pos))")
    }
}

struct WaveformView: View {
    var isPlaying: Bool
    var color: Color
    @State private var peaks: [CGFloat] = [0.2, 0.4, 0.6, 0.3]
    
    // Faster timer for more responsive fluid motion
    let timer = Timer.publish(every: 0.14, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 3.0) {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(color)
                    // Slightly thicker, higher peaks for realism
                    .frame(width: 2.0, height: isPlaying ? peaks[index] * 14 + 2 : 3)
                    .shadow(color: color.opacity(isPlaying ? 0.6 : 0.0), radius: 2, x: 0, y: 0)
                    // Elastic spring makes it dance naturally, not just linear easing
                    .animation(.interactiveSpring(response: 0.22, dampingFraction: 0.7), value: peaks[index])
            }
        }
        .frame(height: 16)
        .onReceive(timer) { _ in
            if isPlaying {
                for i in 0..<4 {
                    // Blend previous value with a new random value so it doesn't jump crazily
                    let target = CGFloat.random(in: 0.05...1.0)
                    peaks[i] = (peaks[i] * 0.3) + (target * 0.7)
                }
            } else {
                peaks = [0.1, 0.15, 0.1, 0.15]
            }
        }
    }
}

struct CustomProgressBar: View {
    var position: Double
    var total: Double
    var onSeek: (Double) -> Void
    
    @State private var dragPosition: Double? = nil
    
    var body: some View {
        GeometryReader { geo in
            let currentPos = dragPosition ?? position
            let percent = max(0, min(1, total > 0 ? (currentPos / total) : 0))
            
            ZStack(alignment: .center) {
                // Invisible hit target
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 24)
                
                ZStack(alignment: .leading) {
                    let isDragging = dragPosition != nil
                    let barHeight: CGFloat = isDragging ? 8 : 4
                    
                    Capsule()
                        .fill(Color.white.opacity(0.25))
                        .frame(height: barHeight)
                    
                    Capsule()
                        .fill(Color.white)
                        .frame(width: max(0, geo.size.width * CGFloat(percent)), height: barHeight)
                        .shadow(color: isDragging ? Color.white.opacity(0.4) : Color.clear, radius: 3, x: 0, y: 0)
                }
                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: dragPosition != nil)
                // Smoothly animate the progress fill itself so it ticks up naturally instead of jumping
                .animation(.linear(duration: 1.0), value: dragPosition == nil ? position : nil)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let w = max(0, min(geo.size.width, gesture.location.x))
                        dragPosition = (Double(w) / Double(geo.size.width)) * total
                    }
                    .onEnded { gesture in
                        let w = max(0, min(geo.size.width, gesture.location.x))
                        let finalPos = (Double(w) / Double(geo.size.width)) * total
                        onSeek(finalPos)
                        dragPosition = nil
                    }
            )
        }
        .frame(height: 24)
    }
}







extension NSImage {
    var averageColor: Color? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        
        let width = 1
        let height = 1
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData: [UInt8] = [0, 0, 0, 0]
        
        guard let context = CGContext(data: &pixelData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: 4,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let r = Double(pixelData[0]) / 255.0
        let g = Double(pixelData[1]) / 255.0
        let b = Double(pixelData[2]) / 255.0
        
        // Boost brightness so it's not too dark to see
        let nsColor = NSColor(red: r, green: g, blue: b, alpha: 1.0).blended(withFraction: 0.2, of: .white) ?? NSColor(red: r, green: g, blue: b, alpha: 1.0)
        return Color(nsColor: nsColor)
    }
}


struct CustomVolumeSlider: View {
    @Binding var volume: Double
    var onEditingChanged: (Double) -> Void
    
    @State private var dragVolume: Double? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .foregroundColor(.gray)
                .font(.system(size: 10, weight: .medium))
            
            GeometryReader { geo in
                let currentVol = dragVolume ?? volume
                let percent = max(0, min(1, currentVol / 100.0))
                
                ZStack(alignment: .center) {
                    // Invisible hit target
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 24)
                    
                    ZStack(alignment: .leading) {
                        let isDragging = dragVolume != nil
                        let barHeight: CGFloat = isDragging ? 8 : 4
                        
                        Capsule()
                            .fill(Color.white.opacity(0.25))
                            .frame(height: barHeight)
                        
                        Capsule()
                            .fill(Color.white)
                            .frame(width: max(0, geo.size.width * CGFloat(percent)), height: barHeight)
                            // A subtle glow when actively dragging for that "nice" touch
                            .shadow(color: isDragging ? Color.white.opacity(0.4) : Color.clear, radius: 3, x: 0, y: 0)
                    }
                    .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: dragVolume != nil)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let w = max(0, min(geo.size.width, gesture.location.x))
                            let newVol = (Double(w) / Double(geo.size.width)) * 100.0
                            dragVolume = newVol
                            volume = newVol
                        }
                        .onEnded { gesture in
                            let w = max(0, min(geo.size.width, gesture.location.x))
                            let finalVol = (Double(w) / Double(geo.size.width)) * 100.0
                            volume = finalVol
                            onEditingChanged(finalVol)
                            dragVolume = nil
                        }
                )
            }
            .frame(height: 24)
            
            Image(systemName: "speaker.wave.3.fill")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .medium))
        }
    }
}

struct AlbumFlipModifier: ViewModifier {
    let amount: Double
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(amount * 90), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            .opacity(1.0 - abs(amount) * 1.5)
            .scaleEffect(1.0 - (abs(amount) * 0.4))
    }
}

extension AnyTransition {
    static var albumFlip: AnyTransition {
        .opacity.animation(.easeInOut(duration: 0.2))
    }
    
    // Smooth reveal transition replacing scaling/sliding
    static var contentReveal: AnyTransition {
        .asymmetric(
            insertion: .opacity.animation(.easeInOut(duration: 0.25).delay(0.05)),
            removal: .opacity.animation(.easeOut(duration: 0.05))
        )
    }
}

struct MarqueeText: View {
    let text: String
    let font: Font
    let maxWidth: CGFloat
    
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var isAnimating: Bool = false
    @State private var timer: Timer? = nil
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(text)
                .font(font)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundColor(Color(white: 0.75))
                .background(GeometryReader { geo in
                    Color.clear.onAppear {
                        textWidth = geo.size.width
                        setupAnimation()
                    }
                    .onChange(of: geo.size.width) { _, newWidth in
                        textWidth = newWidth
                        setupAnimation()
                    }
                })
                .offset(x: offset)
        }
        .frame(width: min(textWidth, maxWidth) == 0 ? maxWidth : min(textWidth, maxWidth), alignment: .center)
        .disabled(true)
        .onChange(of: text) { _, _ in
            offset = 0
            isAnimating = false
            timer?.invalidate()
            setupAnimation()
        }
    }
    
    private func setupAnimation() {
        guard textWidth > maxWidth, !isAnimating else {
            if textWidth <= maxWidth {
                offset = 0
                isAnimating = false
                timer?.invalidate()
            }
            return
        }
        isAnimating = true
        
        timer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
            guard self.isAnimating else { return }
            let duration = Double(textWidth - maxWidth) / 30.0 // adjust speed
            withAnimation(.linear(duration: duration)) {
                self.offset = -(self.textWidth - self.maxWidth)
            }
            
            let t2 = Timer.scheduledTimer(withTimeInterval: duration + 1.5, repeats: false) { _ in
                guard self.isAnimating else { return }
                withAnimation(.linear(duration: 0.5)) {
                    self.offset = 0
                }
                
                let t3 = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { _ in
                    guard self.isAnimating else { return }
                    self.isAnimating = false
                    self.setupAnimation()
                }
                self.timer = t3
            }
            self.timer = t2
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }
}

struct CallWaveformView: View {
    var micLevel: CGFloat // Continuous 0.0 ... 1.0 from microphone
    var color: Color = .green
    
    @State private var peaks: [CGFloat] = [0.1, 0.1, 0.1, 0.1]
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 3.0) {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(color)
                    // The louder the mic level, the higher the peaks
                    .frame(width: 2.0, height: max(3.0, peaks[index] * 14 + 2))
                    .shadow(color: color.opacity(micLevel > 0.1 ? 0.6 : 0.0), radius: 2, x: 0, y: 0)
                    .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.6), value: peaks[index])
            }
        }
        .frame(height: 16)
        .onReceive(timer) { _ in
            for i in 0..<4 {
                // If it's pure quiet, just rest at 0.1
                if micLevel < 0.05 {
                    peaks[i] = (peaks[i] * 0.5) + (0.1 * 0.5)
                } else {
                    // Combine actual microphone amplitude with a bit of random variation so all bars don't look identical
                    let randomJitter = CGFloat.random(in: 0.4...1.2)
                    let target = micLevel * randomJitter
                    peaks[i] = (peaks[i] * 0.4) + (target * 0.6)
                }
            }
        }
    }
}
