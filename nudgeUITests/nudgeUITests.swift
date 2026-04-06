//
//  nudgeUITests.swift
//  nudgeUITests
//
//  Created by Bongjin Lee on 4/2/26.
//

import XCTest
import AppKit
import Darwin

final class nudgeUITests: XCTestCase {
    private let bundleIdentifier = "com.bongjinlee.nudgewhip"
    private let terminationTimeout: TimeInterval = 5

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        try terminateRunningAppIfNeeded()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try terminateRunningAppIfNeeded()
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
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
