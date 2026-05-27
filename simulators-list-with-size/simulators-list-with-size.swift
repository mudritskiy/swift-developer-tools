import Foundation

struct DeviceInfo {
    let size: Int64
    let humanSize: String
    let name: String
    let iOS: String
    let udid: String
    
    func format() -> String {
        let truncatedName = String(name.prefix(25)).padding(toLength: 25, withPad: " ", startingAt: 0)
        let truncatedIOS = String(iOS.prefix(10)).padding(toLength: 10, withPad: " ", startingAt: 0)
        let truncatedHumanSize = String(humanSize.prefix(10)).padding(toLength: 10, withPad: " ", startingAt: 0)
        let truncatedUDID = String(udid.prefix(40)).padding(toLength: 40, withPad: " ", startingAt: 0)
        
        return String(
            format: "%@%@%@%@",
            truncatedHumanSize,
            truncatedName,
            truncatedIOS,
            truncatedUDID
        )
    }
}

// MARK: - Directory Size
func directorySize(url: URL) -> Int64 {
    let resourceKeys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey, .isRegularFileKey]
    guard let enumerator = FileManager.default.enumerator(
        at: url,
        includingPropertiesForKeys: Array(resourceKeys),
        options: [.skipsHiddenFiles]
    ) else { return 0 }

    var total: Int64 = 0
    for case let fileURL as URL in enumerator {
        guard let values = try? fileURL.resourceValues(forKeys: resourceKeys),
              values.isRegularFile == true else { continue }
        total += Int64(values.totalFileAllocatedSize ?? 0)
    }
    return total
}

// MARK: - Format Size
func formatSize(_ size: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useGB, .useMB]
    formatter.countStyle = .file
    formatter.isAdaptive = false

    let raw = formatter.string(fromByteCount: size)
    let parts = raw.split(separator: " ").map(String.init)
    guard parts.count == 2,
          let value = Double(parts[0].replacingOccurrences(of: ",", with: "."))
    else { return raw }
    return String(format: "%.2f %@", value, parts[1])
}

// MARK: - Simulator Info
func getSimulatorInfo() -> [DeviceInfo] {
    let fm = FileManager.default
    let simulatorsPath = NSHomeDirectory() + "/Library/Developer/CoreSimulator/Devices"

    guard fm.fileExists(atPath: simulatorsPath),
          let entries = try? fm.contentsOfDirectory(atPath: simulatorsPath) else {
        print("❌ Simulator directory not found: \(simulatorsPath)")
        return []
    }

    var deviceInfos: [DeviceInfo] = []

    for udid in entries {
        let devicePath = (simulatorsPath as NSString).appendingPathComponent(udid)
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: devicePath, isDirectory: &isDir), isDir.boolValue else { continue }

        let size = directorySize(url: URL(fileURLWithPath: devicePath))
        guard size > 100_000_000 else { continue }

        // Read device.plist — written by CoreSimulator, always present
        let plistURL = URL(fileURLWithPath: devicePath).appendingPathComponent("device.plist")
        let plist    = NSDictionary(contentsOf: plistURL)

        let deviceName = plist?["name"] as? String ?? "Unknown"

        // runtime value looks like "com.apple.CoreSimulator.SimRuntime.iOS-17-0"
        let runtime    = plist?["runtime"] as? String ?? ""
        let iOSVersion = runtime
            .components(separatedBy: "iOS-").last?
            .replacingOccurrences(of: "-", with: ".") ?? "unknown"

        deviceInfos.append(DeviceInfo(
            size: size,
            humanSize: formatSize(size),
            name: deviceName,
            iOS: iOSVersion,
            udid: udid
        ))
    }

    return deviceInfos
}

// MARK: - Entry Point
func main() {
    let deviceInfos = getSimulatorInfo().sorted { $0.size > $1.size }

    guard !deviceInfos.isEmpty else {
        print("❌ No simulators found larger than 100 MB")
        return
    }

    print("Size      Device Name              iOS       UDID (Unique Device Identifier)")
    print("--------- ------------------------ --------- ---------------------------------------")
    deviceInfos.forEach { print($0.format()) }

    print("\nInstructions:")
    print("  🔹 Delete a simulator:  xcrun simctl delete <UDID>")
    print("  🔹 Erase a simulator:   xcrun simctl erase <UDID>\n")
}

main()
