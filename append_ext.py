content = """

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
"""

with open('/Users/gaspaco/Desktop/dynamic island/dynamic island/ContentView.swift', 'a') as f:
    f.write(content)
