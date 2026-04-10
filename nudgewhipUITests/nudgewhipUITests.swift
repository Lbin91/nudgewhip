//
//  nudgewhipUITests.swift
//  nudgewhipUITests
//
//  Created by Bongjin Lee on 4/2/26.
//

import XCTest
import AppKit
import Darwin

final class nudgewhipUITests: XCTestCase {
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
        let app = makeConfiguredApp(accessibility: "granted")
        app.launch()
        XCTAssertTrue(element(in: app, label: "Get Started").waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            makeConfiguredApp(accessibility: "granted").launch()
        }
    }

    @MainActor
    func testOnboardingReadyFlowCompletesFromFreshLaunch() throws {
        let app = makeConfiguredApp(accessibility: "granted")
        app.launch()

        let getStarted = element(in: app, label: "Get Started")
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
        getStarted.tap()

        let continueFromPermission = element(in: app, label: "Continue")
        XCTAssertTrue(continueFromPermission.waitForExistence(timeout: 5))
        continueFromPermission.tap()

        XCTAssertTrue(element(in: app, label: "Launch at login").waitForExistence(timeout: 5))
        XCTAssertTrue(element(in: app, label: "Show top countdown overlay").exists)
    }

    @MainActor
    func testOnboardingLimitedFlowShowsRecoveryActions() throws {
        let app = makeConfiguredApp(accessibility: "denied")
        app.launch()

        let getStarted = element(in: app, label: "Get Started")
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
        getStarted.tap()

        let requestAccess = element(in: app, label: "Request Access")
        XCTAssertTrue(requestAccess.waitForExistence(timeout: 5))

        let setUpLater = element(in: app, label: "Set Up Later")
        XCTAssertTrue(setUpLater.waitForExistence(timeout: 5))
        setUpLater.tap()

        XCTAssertTrue(element(in: app, label: "Continue in Limited Mode").waitForExistence(timeout: 5))
        XCTAssertTrue(element(in: app, label: "Open System Settings").exists)
    }

    private func makeConfiguredApp(accessibility: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["NUDGE_RESET_ON_LAUNCH"] = "1"
        app.launchEnvironment["NUDGE_UI_TEST_ONBOARDING"] = "1"
        app.launchEnvironment["NUDGE_TEST_ACCESSIBILITY"] = accessibility
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        return app
    }

    private func element(in app: XCUIApplication, label: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", label))
            .firstMatch
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
