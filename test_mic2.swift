import Cocoa

func getTeamsWindows() {
    let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
    let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
    guard let infoList = windowListInfo as NSArray? as? [[String: AnyObject]] else { return }
    
    for window in infoList {
        if let owner = window[kCGWindowOwnerName as String] as? String, owner.lowercased().contains("teams") {
            let name = window[kCGWindowName as String] as? String ?? "No Name"
            print("Teams Window: \(name)")
        }
    }
}
getTeamsWindows()
