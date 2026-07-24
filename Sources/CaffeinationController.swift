import Foundation

enum CaffeinePreset: Int, CaseIterable {
    case thirtyMinutes
    case oneHour
    case fourHours
    case untilTurnedOff

    var duration: TimeInterval? {
        switch self {
        case .thirtyMinutes: return 30 * 60
        case .oneHour: return 60 * 60
        case .fourHours: return 4 * 60 * 60
        case .untilTurnedOff: return nil
        }
    }

    var compactTitle: String {
        switch self {
        case .thirtyMinutes: return "30 min"
        case .oneHour: return "1 hour"
        case .fourHours: return "4 hours"
        case .untilTurnedOff: return "∞"
        }
    }

    var menuTitle: String {
        switch self {
        case .thirtyMinutes: return "30 minutes"
        case .oneHour: return "1 hour"
        case .fourHours: return "4 hours"
        case .untilTurnedOff: return "Until turned off"
        }
    }

    var overlayTitle: String {
        switch self {
        case .thirtyMinutes: return "30 MIN SESSION"
        case .oneHour: return "1 HOUR SESSION"
        case .fourHours: return "4 HOUR SESSION"
        case .untilTurnedOff: return "UNTIL YOU’RE BACK"
        }
    }
}

final class CaffeinationController {
    private(set) var isActive = false
    private(set) var startedAt: Date?
    private(set) var endsAt: Date?
    private(set) var preset: CaffeinePreset = .untilTurnedOff
    var onAutomaticStop: (() -> Void)?

    private var caffeineProcess: Process?
    private var expirationTimer: Timer?

    var elapsed: TimeInterval {
        guard let startedAt else { return 0 }
        return Date().timeIntervalSince(startedAt)
    }

    var remaining: TimeInterval? {
        guard let endsAt else { return nil }
        return max(0, endsAt.timeIntervalSinceNow)
    }

    var assertionIsRunning: Bool {
        caffeineProcess?.isRunning == true
    }

    func start(
        preset: CaffeinePreset = .untilTurnedOff,
        durationOverride: TimeInterval? = nil
    ) throws {
        guard !isActive else { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        // -d prevents display sleep, -i prevents idle system sleep, and -m prevents idle disk sleep.
        // The assertion lives only as long as this tiny child process and is released immediately on stop.
        process.arguments = ["-d", "-i", "-m"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()

        caffeineProcess = process
        startedAt = Date()
        self.preset = preset
        let duration = durationOverride ?? preset.duration
        endsAt = duration.map { Date(timeIntervalSinceNow: $0) }
        isActive = true
        scheduleExpiration(after: duration)
    }

    func updateSession(
        preset: CaffeinePreset,
        durationOverride: TimeInterval? = nil
    ) {
        guard isActive else { return }
        self.preset = preset
        let duration = durationOverride ?? preset.duration
        endsAt = duration.map { Date(timeIntervalSinceNow: $0) }
        scheduleExpiration(after: duration)
    }

    func stop() {
        guard isActive else { return }
        expirationTimer?.invalidate()
        expirationTimer = nil
        if let process = caffeineProcess, process.isRunning {
            process.terminate()
        }
        caffeineProcess = nil
        startedAt = nil
        endsAt = nil
        isActive = false
    }

    func toggle(preset: CaffeinePreset = .untilTurnedOff) throws -> Bool {
        if isActive {
            stop()
        } else {
            try start(preset: preset)
        }
        return isActive
    }

    private func scheduleExpiration(after duration: TimeInterval?) {
        expirationTimer?.invalidate()
        expirationTimer = nil
        guard let duration else { return }

        let timer = Timer(timeInterval: duration, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.stop()
            self.onAutomaticStop?()
        }
        RunLoop.main.add(timer, forMode: .common)
        expirationTimer = timer
    }

    deinit {
        expirationTimer?.invalidate()
        if let process = caffeineProcess, process.isRunning {
            process.terminate()
        }
    }
}
