import AppKit

func getTeamsIcon() -> NSImage? {
    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.teams") {
        return NSWorkspace.shared.icon(forFile: url.path)
    }
    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.teams2") {
        return NSWorkspace.shared.icon(forFile: url.path)
    }
    return nil
}
print(getTeamsIcon() != nil)
