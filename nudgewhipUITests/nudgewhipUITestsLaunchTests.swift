//
//  nudgewhipUITestsLaunchTests.swift
//  nudgewhipUITests
//
//  Created by Bongjin Lee on 4/2/26.
//

import XCTest
import AppKit
import Darwin

final class nudgewhipUITestsLaunchTests: XCTestCase {
    private let bundleIdentifier = "com.bongjinlee.nudgewhip"
    private let terminationTimeout: TimeInterval = 5

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        try terminateRunningAppIfNeeded()
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    override func tearDownWithError() throws {
        try terminateRunningAppIfNeeded()
    }
    
    private func terminateRunningAppIfNeeded() throws {
        func runningApps() -> [NSRunningApplication] {
            NSRunningApplication
                .runningApplications(withBundleIdentifier: bundleIdentifier)
                .filter { !$0.isTerminated }
        }

        for app in runningApps() {
            _ = app.terminate()
        }

        let gracefulDeadline = Date().addingTimeInterval(terminationTimeout / 2)
        while Date() < gracefulDeadline, !runningApps().isEmpty {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        for app in runningApps() {
            _ = app.forceTerminate()
            kill(pid_t(app.processIdentifier), SIGKILL)
            if let parentProcessIdentifier = parentProcessIdentifier(of: pid_t(app.processIdentifier)) {
                kill(parentProcessIdentifier, SIGKILL)
            }
        }

        let forcedDeadline = Date().addingTimeInterval(terminationTimeout / 2)
        while Date() < forcedDeadline {
            if runningApps().isEmpty {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        throw XCTSkip("Could not fully terminate \(bundleIdentifier) before the next UI test launch.")
    }

    private func parentProcessIdentifier(of processIdentifier: pid_t) -> pid_t? {
        let process = Process()
        let outputPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-o", "ppid=", "-p", "\(processIdentifier)"]
        process.standardOutput = outputPipe

        do {
            try process.run()
        } catch {
            return nil
        }

        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parent = Int32(output), parent > 1 else { return nil }
        return parent
    }
}
