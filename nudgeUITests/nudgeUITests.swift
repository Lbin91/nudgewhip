//
//  nudgeUITests.swift
//  nudgeUITests
//
//  Created by Bongjin Lee on 4/2/26.
//

import XCTest
import AppKit

final class nudgeUITests: XCTestCase {
    private let bundleIdentifier = "com.bongjinlee.nudge"
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
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
        
        for app in runningApps where !app.isTerminated {
            if !app.terminate() {
                _ = app.forceTerminate()
            }
        }
        
        let deadline = Date().addingTimeInterval(terminationTimeout)
        while Date() < deadline {
            let stillRunning = NSRunningApplication
                .runningApplications(withBundleIdentifier: bundleIdentifier)
                .contains(where: { !$0.isTerminated })
            if !stillRunning {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        
        throw XCTSkip("Could not fully terminate \(bundleIdentifier) before the next UI test launch.")
    }
}
