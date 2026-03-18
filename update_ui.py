import sys
with open('/Users/gaspaco/Desktop/dynamic island/dynamic island/ContentView.swift', 'r') as f:
    text = f.read()

import re

# Since start/end marker matching can be finicky due to subtle spacing, let's use exact line replacement
lines = text.split('\n')
start_idx = -1
end_idx = -1
for i, l in enumerate(lines):
    if l.strip() == '// Show contents ONLY when clicked/expanded':
        start_idx = i
    if start_idx != -1 and 'height: isExpanded ?' in l and 'dynamicNotchHeight' in l:
        end_idx = i
        break

if start_idx != -1 and end_idx != -1:
    new_ui = """                // Show contents ONLY when clicked/expanded
                if isExpanded {
                    VStack(spacing: 0) {
                        // 1. Top Section: Art and Titles
                        HStack(alignment: .center, spacing: 16) {
                            // Album Artwork
                            if let cover = spotify.coverImage {
                                Image(nsImage: cover)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(12)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white.opacity(0.6))
                                    )
                            }
                            
                            // Text Meta Data
                            VStack(alignment: .leading, spacing: 4) {
                                Text(spotify.trackName)
                                    .foregroundColor(.white)
                                    .font(.system(size: 18, weight: .bold))
                                    .lineLimit(1)
                                
                                Text(spotify.artistName.isEmpty ? "Spotify" : spotify.artistName)
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16, weight: .regular))
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            // Dynamic Waveform "Sound beat"
                            WaveformView(isPlaying: spotify.isPlaying)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        // 2. Progress / Loadbar
                        HStack(spacing: 12) {
                            Text(formatTime(spotify.position))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            CustomProgressBar(position: spotify.position, total: spotify.duration, onSeek: { newPos in
                                spotify.seek(to: newPos)
                            })
                            
                            Text("-" + formatTime(max(0, spotify.duration - spotify.position)))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // 3. Media Controls
                        ZStack {
                            HStack {
                                Button(action: { spotify.toggleShuffle() }) {
                                    Image(systemName: "shuffle")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(spotify.isShuffling ? .green : .gray)
                                }.buttonStyle(.plain)
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                        isVolumeExpanded.toggle()
                                    }
                                }) {
                                    Image(systemName: "macbook")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(isVolumeExpanded ? .white : .gray)
                                }.buttonStyle(.plain)
                            }
                            
                            HStack(spacing: 32) {
                                Button(action: { spotify.previousTrack() }) {
                                    Image(systemName: "backward.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(.white)
                                }.buttonStyle(.plain)
                                
                                Button(action: { spotify.playPause() }) {
                                    Image(systemName: spotify.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                }.buttonStyle(.plain)
                                
                                Button(action: { spotify.nextTrack() }) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(.white)
                                }.buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, isVolumeExpanded ? 16 : 24)
                        
                        // Volume Slider
                        if isVolumeExpanded {
                            HStack(spacing: 12) {
                                Image(systemName: "speaker.fill").foregroundColor(.gray).font(.system(size: 12))
                                Slider(value: Binding(
                                    get: { spotify.volume },
                                    set: { v in spotify.volume = v; spotify.setVolume(v) }
                                ), in: 0...100)
                                .tint(.white)
                                Image(systemName: "speaker.wave.3.fill").foregroundColor(.gray).font(.system(size: 14))
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                            .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                        }
                    }
                    .zIndex(1)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.animation(.easeIn(duration: 0.2).delay(0.1)),
                            removal: .opacity.animation(.easeOut(duration: 0.02))
                        )
                    )
                }
            }
            .contentShape(Rectangle())
            // Dynamic heights for expansion
            .frame(width: isExpanded ? 400 : baseNotchWidth,
                   height: isExpanded ? (isVolumeExpanded ? 270 : 210) : dynamicNotchHeight)"""
    
    new_content = '\n'.join(lines[:start_idx]) + '\n' + new_ui + '\n' + '\n'.join(lines[end_idx+1:])
    
    new_content = new_content.replace('let checkWidth: CGFloat = isExpanded ? 420 : 250', 'let checkWidth: CGFloat = isExpanded ? 420 : 250')
    new_content = new_content.replace('let checkHeight: CGFloat = isExpanded ? (isVolumeExpanded ? 220 : 185) : 45', 'let checkHeight: CGFloat = isExpanded ? (isVolumeExpanded ? 280 : 220) : 45')
    new_content = new_content.replace('LiquidNotchShape(bottomRadius: isExpanded ? 38 : notchCornerRadius)', 'LiquidNotchShape(bottomRadius: isExpanded ? 46 : notchCornerRadius)')

    cprogressBar = '''
struct CustomProgressBar: View {
    var position: Double
    var total: Double
    var onSeek: (Double) -> Void
    
    @State private var dragPosition: Double? = nil
    
    var body: some View {
        GeometryReader { geo in
            let currentPos = dragPosition ?? position
            let percent = max(0, min(1, total > 0 ? (currentPos / total) : 0))
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 6)
                
                Capsule()
                    .fill(Color.white)
                    .frame(width: max(0, geo.size.width * CGFloat(percent)), height: 6)
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
        .frame(height: 6)
    }
}
'''
    if "CustomProgressBar" not in new_content:
        new_content += cprogressBar

    with open('/Users/gaspaco/Desktop/dynamic island/dynamic island/ContentView.swift', 'w') as f:
        f.write(new_content)
    print("DONE REPLACING")
else:
    print(f"FAILED TO FIND INDICES {start_idx} {end_idx}")
