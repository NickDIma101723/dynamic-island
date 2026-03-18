//
//  ContentView.swift
//  dynamic island
//

import SwiftUI

// Ensure we use a custom shape to create the organic "fillet" curves at the top that perfectly match the hardware notch.
struct LiquidNotchShape: Shape {
    var bottomRadius: CGFloat
    // The inverse radius curve merging into the bezel
    let topFillet: CGFloat = 8
    
    var animatableData: CGFloat {
        get { bottomRadius }
        set { bottomRadius = newValue }
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
    @State private var dynamicNotchHeight: CGFloat = 34 // Mac notch is usually 32-34
    
    // Exact dimensions
    let baseNotchWidth: CGFloat = 160 // Slight buffer to accommodate fillets
    let notchCornerRadius: CGFloat = 12
    
    var body: some View {
        // Encase in a container that fills the entire NSPanel frame but aligns elements to the top.
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                // To blend perfectly with the hardware notch, it must be pure pitch black.
                // Translucency or grey makes it obvious it's a fake overlay.
                LiquidNotchShape(bottomRadius: (isExpanded || isHovering) ? 24 : notchCornerRadius)
                    .fill(Color.black)
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    .zIndex(0)
                
                // Show contents when hovered or expanded, fading in with a delay
                if isExpanded || isHovering {
                    HStack(spacing: 0) {
                        Image(systemName: "music.note")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .bold))
                            .padding(.leading, 24)
                        
                        Spacer()
                        
                        Text("Mac Island")
                            .foregroundColor(.white)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Image(systemName: "cellularbars")
                            Image(systemName: "wifi")
                            Image(systemName: "battery.100")
                        }
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                        .padding(.trailing, 24)
                    }
                    .padding(.bottom, 16) // Pulls the content down to escape the physical hardware notch area!
                    .zIndex(1) // Forces SwiftUI to render this above the shape
                    .transition(
                        .asymmetric(
                            insertion: .opacity.animation(.easeIn(duration: 0.2).delay(0.1)),
                            removal: .opacity.animation(.easeOut(duration: 0.02)) // Instantly fades out when collapsing!
                        )
                    )
                }
            }
            .contentShape(Rectangle()) // Ensures the mouse detection is easy to hit, even when invisible
            // Animate only the inner graphic frame.
            .frame(width: (isExpanded || isHovering) ? 300 : baseNotchWidth,
                   height: (isExpanded || isHovering) ? 80 : dynamicNotchHeight)
            // Removed `.clipShape` and `.drawingGroup()` which were locking up the Metal renderer and causing Xcode to freeze
            .onHover { hovered in
                // Apple-like liquid spring feeling
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.2)) {
                    isHovering = hovered
                    if !hovered {
                        isExpanded = false
                    }
                }
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.2)) {
                    isExpanded.toggle()
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
        .ignoresSafeArea()
    }
    
    private func detectNotchMetrics() {
        if let mainScreen = NSScreen.main {
            let topInset = mainScreen.safeAreaInsets.top
            if topInset > 24 {
                dynamicNotchHeight = topInset
            }
        }
    }
}

#Preview {
    ContentView()
}





