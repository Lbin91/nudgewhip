//
//  nudgeUITestsLaunchTests.swift
//  nudgeUITests
//
//  Created by Bongjin Lee on 4/2/26.
//

import XCTest
import AppKit

final class nudgeUITestsLaunchTests: XCTestCase {
    private let bundleIdentifier = "com.bongjinlee.nudge"

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
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
    
    private func terminateRunningAppIfNeeded() throws {
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
        
        for app in runningApps where !app.isTerminated {
            if !app.terminate() {
                _ = app.forceTerminate()
            }
        }
    }
}
