import re

new_content = """struct CustomVolumeSlider: View {
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
                        Capsule()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(Color.white)
                            .frame(width: max(0, geo.size.width * CGFloat(percent)), height: 6)
                    }
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
}"""

with open('/Users/gaspaco/Desktop/dynamic island/dynamic island/ContentView.swift', 'r') as f:
    text = f.read()

pattern = re.compile(r"struct CustomVolumeSlider: View \{.*?\n\}", re.DOTALL)
text = pattern.sub(new_content, text)

with open('/Users/gaspaco/Desktop/dynamic island/dynamic island/ContentView.swift', 'w') as f:
    f.write(text)
print("Updated Volume Slider")