import AppKit
import Foundation

if CommandLine.arguments.contains("--hotkey-self-test") {
    _ = NSApplication.shared
    let hotKey = GlobalHotKey {}
    guard hotKey.register() else {
        fputs("HOTKEY TEST FAILED: ⌥⌘C could not be registered\n", stderr)
        exit(1)
    }
    hotKey.unregister()
    print("HOTKEY TEST PASSED: ⌥⌘C registers without accessibility permission")
    exit(0)
}

if let previewIndex = CommandLine.arguments.firstIndex(of: "--render-preview") {
    let outputPath: String
    if CommandLine.arguments.indices.contains(previewIndex + 1) {
        outputPath = CommandLine.arguments[previewIndex + 1]
    } else {
        outputPath = FileManager.default.currentDirectoryPath + "/caffeinator-preview.png"
    }

    _ = NSApplication.shared
    let previewSize = NSSize(width: 356, height: 500)
    let view = DashboardView(frame: NSRect(origin: .zero, size: previewSize))
    if CommandLine.arguments.contains("--preview-off") {
        view.isActive = false
        view.selectedPreset = .untilTurnedOff
    } else {
        view.isActive = true
        view.startedAt = Date(timeIntervalSinceNow: -(12 * 60 + 34))
        if CommandLine.arguments.contains("--preview-timed") {
            view.endsAt = Date(timeIntervalSinceNow: 53 * 60 + 22)
            view.selectedPreset = .oneHour
        } else {
            view.selectedPreset = .untilTurnedOff
        }
    }
    view.displayIfNeeded()

    guard let representation = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
        fputs("PREVIEW FAILED: could not allocate bitmap\n", stderr)
        exit(1)
    }
    view.cacheDisplay(in: view.bounds, to: representation)
    guard let png = representation.representation(using: .png, properties: [:]) else {
        fputs("PREVIEW FAILED: could not encode PNG\n", stderr)
        exit(1)
    }
    do {
        try png.write(to: URL(fileURLWithPath: outputPath), options: .atomic)
        print(outputPath)
        exit(0)
    } catch {
        fputs("PREVIEW FAILED: \(error)\n", stderr)
        exit(1)
    }
}

if CommandLine.arguments.contains("--self-test") {
    let controller = CaffeinationController()
    do {
        try controller.start(preset: .oneHour)
        Thread.sleep(forTimeInterval: 0.15)
        guard controller.isActive,
              controller.assertionIsRunning,
              controller.endsAt != nil,
              controller.preset == .oneHour else {
            fputs("SELF-TEST FAILED: caffeinate assertion did not start\n", stderr)
            exit(1)
        }

        controller.updateSession(preset: .untilTurnedOff)
        guard controller.endsAt == nil && controller.preset == .untilTurnedOff else {
            fputs("SELF-TEST FAILED: session preset did not update\n", stderr)
            exit(1)
        }
        controller.stop()
        guard !controller.isActive && !controller.assertionIsRunning else {
            fputs("SELF-TEST FAILED: caffeinate assertion did not stop\n", stderr)
            exit(1)
        }

        var didExpire = false
        controller.onAutomaticStop = {
            didExpire = true
        }
        try controller.start(preset: .thirtyMinutes, durationOverride: 0.20)
        let deadline = Date(timeIntervalSinceNow: 1.0)
        while !didExpire && Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.04))
        }
        guard didExpire && !controller.isActive && !controller.assertionIsRunning else {
            fputs("SELF-TEST FAILED: timed session did not expire cleanly\n", stderr)
            exit(1)
        }

        print("SELF-TEST PASSED: indefinite, updated, and timed caffeine sessions release cleanly")
        exit(0)
    } catch {
        fputs("SELF-TEST FAILED: \(error)\n", stderr)
        exit(1)
    }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.run()
