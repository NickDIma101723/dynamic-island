import Cocoa

let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
guard let infoList = windowListInfo as NSArray? as? [[String: AnyObject]] else { exit(0) }

var teamsCount = 0
for window in infoList {
    if let owner = window[kCGWindowOwnerName as String] as? String, owner.lowercased().contains("teams") {
        let name = window[kCGWindowName as String] as? String ?? "No Name"
        let layer = window[kCGWindowLayer as String] as? Int ?? 0
        if layer == 0 { // Standard app windows are layer 0
            teamsCount += 1
            print("Found Teams Window: \(name)")
        }
    }
}
print("Total Teams windows: \(teamsCount)")
