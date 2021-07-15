import Cocoa
import Foundation

enum OSDImage: Int64 {
    case brightness = 1
    case contrast = 11
    case volume = 3
    case muted = 4
}

func displayInfoDictionary(_ id: CGDirectDisplayID) -> NSDictionary? {
    let unmanagedDict = CoreDisplay_DisplayCreateInfoDictionary(id)
    let retainedDict = unmanagedDict?.takeRetainedValue()
    guard let dict = retainedDict as NSDictionary? else {
        return nil
    }

    return dict
}

func name(for id: CGDirectDisplayID) -> String? {
    guard let dict = displayInfoDictionary(id),
          let name = (dict["DisplayProductName"] as? [String: String])?["en_US"]
    else {
        return nil
    }

    return name
}

func showOsd(osdImage: OSDImage, value: UInt32, displayID: CGDirectDisplayID, locked: Bool = false, respectMirroring: Bool = true) {
    guard let manager = OSDManager.sharedManager() as? OSDManager else {
        print("No OSDManager available")
        return
    }

    var osdID = displayID
    if respectMirroring {
        let mirroredID = CGDisplayMirrorsDisplay(displayID)
        osdID = mirroredID != kCGNullDirectDisplay ? mirroredID : displayID
    }

    manager.showImage(
        osdImage.rawValue,
        onDisplayID: osdID,
        priority: 0x1F4,
        msecUntilFade: 1500,
        filledChiclets: value,
        totalChiclets: 100,
        locked: locked
    )
}

let maxDisplays: UInt32 = 16
var onlineDisplays = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))
var displayCount: UInt32 = 0

let err = CGGetOnlineDisplayList(maxDisplays, &onlineDisplays, &displayCount)
let displayIDs = onlineDisplays.prefix(Int(displayCount))

print("Online Display IDs: \(displayIDs)")

for id in displayIDs {
    let displayName = name(for: id) ?? "unknown"
    print("Showing OSD on display \(displayName) [id: \(id)]")
    showOsd(osdImage: .brightness, value: 50, displayID: id)
    sleep(2)

    let mirroredID = CGDisplayMirrorsDisplay(id)
    guard mirroredID != kCGNullDirectDisplay else {
        print("Display \(displayName) [id: \(id)] does not mirror any other display")
        continue
    }
    let mirroredDisplayName = name(for: mirroredID) ?? "unknown"
    print("Display \(displayName) [id: \(id)] mirrors \(mirroredDisplayName) [id: \(mirroredID)]")

    print("Showing OSD on mirrored display \(mirroredDisplayName) [id: \(mirroredID)]")
    showOsd(osdImage: .brightness, value: 50, displayID: mirroredID)
    sleep(2)

    print("Showing OSD on mirrored display \(mirroredDisplayName) [id: \(mirroredID)] without respectMirroring")
    showOsd(osdImage: .brightness, value: 50, displayID: mirroredID, respectMirroring: false)
    sleep(2)
}
