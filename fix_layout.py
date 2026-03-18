import re
with open("dynamic island/ContentView.swift", "r") as f:
    text = f.read()

pattern = r"(// BLUETOOTH CONNECTION ALERT\n.*?)(?=\} else if showTrackPopup)"

new_code = """// BLUETOOTH CONNECTION ALERT
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
                            
                            // Elegant pill-shaped battery indicators matching macOS
                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Text("L")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(Color(white: 0.5))
                                    Image(systemName: "battery.100")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(Color(white: 0.5), .green)
                                        .font(.system(size: 12))
                                }
                                
                                HStack(spacing: 4) {
                                    Text("R")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(Color(white: 0.5))
                                    Image(systemName: "battery.100")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(Color(white: 0.5), .green)
                                        .font(.system(size: 12))
                                }
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "battery.50")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(Color(white: 0.5), .orange)
                                        .font(.system(size: 13))
                                    Text("Case")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(Color(white: 0.5))
                                }
                            }
                            .padding(.top, 2)
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
                """

match = re.search(pattern, text, re.DOTALL)
if match:
    new_text = text[:match.start()] + new_code + text[match.end():]
    with open("dynamic island/ContentView.swift", "w") as f:
        f.write(new_text)
    print("Replaced successfully!")
else:
    print("No match found")
