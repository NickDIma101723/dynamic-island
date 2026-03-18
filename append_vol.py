content = """

struct CustomVolumeSlider: View {
    @Binding var volume: Double
    var onEditingChanged: (Double) -> Void
    
    @State private var dragVolume: Double? = nil
    
    var body: some View {
        GeometryReader { geo in
            let currentVol = dragVolume ?? volume
            let percent = max(0, min(1, currentVol / 100.0))
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 20)
                
                Capsule()
                    .fill(Color.white)
                    .frame(width: max(20, geo.size.width * CGFloat(percent)), height: 20)
                
                HStack {
                    Image(systemName: percent == 0 ? "speaker.slash.fill" : (percent < 0.5 ? "speaker.wave.1.fill" : "speaker.wave.3.fill"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(percent > 0.05 ? .black : .white.opacity(0.5))
                        .padding(.leading, 8)
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let w = max(0, min(geo.size.width, gesture.location.x))
                        let newVol = (Double(w) / Double(geo.size.width)) * 100.0
                        dragVolume = newVol
                    }
                    .onEnded { gesture in
                        let w = max(0, min(geo.size.width, gesture.location.x))
                        let finalVol = (Double(w) / Double(geo.size.width)) * 100.0
                        onEditingChanged(finalVol)
                        dragVolume = nil
                    }
            )
            .animation(.interactiveSpring(), value: dragVolume)
        }
        .frame(height: 20)
    }
}
"""

with open('/Users/gaspaco/Desktop/dynamic island/dynamic island/ContentView.swift', 'a') as f:
    f.write(content)
