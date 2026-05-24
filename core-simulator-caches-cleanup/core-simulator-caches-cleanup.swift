import Foundation

func shell(_ command: String) -> String? {
    let process = Process()
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    process.arguments = ["-c", command]
    process.launchPath = "/bin/zsh"
    process.launch()
    process.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
}

let title = "Xcode iOS Simulator Cache"
let path = "~/Library/Developer/CoreSimulator/Caches"

print("-----------------------------------------------------")
print("\u{001B}[1m\(title)\u{001B}[0m")
print("📁 \(path)")

if let sizeOutput = shell("du -sh \(path)"),
   let size = sizeOutput.components(separatedBy: "\t").first {
    print("   Folder size: \u{001B}[1m\(size)\u{001B}[0m")
    print("-----------------------------------------------------")
    print("❓ Clear? (y/n): ", terminator: "")
    if let input = readLine(), input.lowercased() == "y" {
        _ = shell("rm -rf \(path)/*")
        print("Cleared!")
    } else {
        print("Cancelled.")
    }
} else {
    print("Error retrieving folder size.")
    print("-----------------------------------------------------")
}
