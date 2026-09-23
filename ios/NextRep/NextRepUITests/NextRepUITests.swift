//
//  NextRepUITests.swift
//  NextRepUITests
//
//  End-to-end UI tests. Require a local backend:
//    cd server && SMELLIS_DB_PATH=/tmp/nextrep-uitest.db SECRET_KEY=x \
//      ADMIN_EMAILS=admin@test.dev uvicorn app.main:app --port 8002
//

import XCTest

final class NextRepUITests: XCTestCase {

    private var apiBase = "http://localhost:8003" // logging proxy -> 8002

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["NEXTREP_API_URL"] = apiBase
        app.launchEnvironment["NEXTREP_RESET_SESSION"] = "1"
        app.launch()
        return app
    }

    private func uniqueEmail() -> String {
        "uitest-\(Int(Date().timeIntervalSince1970))-\(Int.random(in: 100...999))@qareal.dev"
    }

    private func expectElement(_ element: XCUIElement, _ timeout: TimeInterval = 15, _ message: String = "") -> XCUIElement {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "\(message) — \(element) not found")
        return element
    }

    private func signUp(_ app: XCUIApplication) {
        app.buttons["Sign up"].tap()
        let name = app.textFields["Name"]
        expectElement(name, 5, "Name field")
        name.tap()
        name.typeText("UI Tester")
        app.textFields["Email"].tap()
        app.textFields["Email"].typeText(uniqueEmail())
        let password = app.secureTextFields["At least 10 characters"]
        if password.exists {
            fillViaPaste(password, "testpassword123", app: app)
        } else {
            fillViaPaste(app.textFields["At least 10 characters"], "testpassword123", app: app)
        }
        app.buttons["Create Account"].tap()
        // Post-signup the app fetches data + catalog before showing tabs.
        expectElement(app.tabBars.firstMatch, 20, "Tab bar after signup")
        // iOS offers to save the password to AutoFill — the modal sheet
        // swallows all taps on the app until dismissed.
        let notNow = app.buttons["Not Now"]
        if notNow.waitForExistence(timeout: 5) {
            notNow.tap()
            // Let the sheet finish dismissing before the next interaction.
            Thread.sleep(forTimeInterval: 1)
        }
    }

    /// Taps a tab and confirms it actually became selected — a dismissing
    /// system sheet can silently eat the first tap.
    private func tapTab(_ app: XCUIApplication, _ name: String) {
        let button = app.tabBars.buttons[name]
        expectElement(button, 10, "\(name) tab")
        for _ in 0..<3 where !button.isSelected {
            button.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        XCTAssertTrue(button.isSelected, "\(name) tab never became selected")
    }

    private func tapWhenHittable(_ element: XCUIElement, app: XCUIApplication, maxSwipes: Int = 8) {
        var swipes = 0
        while !element.isHittable && swipes < maxSwipes {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(element.isHittable, "\(element) never became hittable")
        element.tap()
    }

    private func programCard(_ app: XCUIApplication, named name: String, id: String) -> XCUIElement {
        let predicate = NSPredicate(
            format: "identifier == %@ OR label CONTAINS[c] %@", "program-card-\(id)", name
        )
        return app.descendants(matching: .any).matching(predicate).firstMatch
    }

    /// LazyVStack rows don't exist until scrolled into view — swipe until
    /// the element is on screen, then tap.
    private func scrollRevealAndTap(_ element: XCUIElement, in app: XCUIApplication,
                                    _ label: String, maxSwipes: Int = 15) {
        _ = element.waitForExistence(timeout: 10)
        var swipes = 0
        while (!element.exists || !element.isHittable) && swipes < maxSwipes {
            app.swipeUp()
            swipes += 1
            Thread.sleep(forTimeInterval: 0.2)
        }
        XCTAssertTrue(element.exists, "\(label) never appeared")
        XCTAssertTrue(element.isHittable, "\(label) never became hittable")
        element.tap()
    }

    private func openFirstWorkoutDay(_ app: XCUIApplication) {
        tapTab(app, "Programs")
        let program = programCard(app, named: "The Classic", id: "classic-physique")
        scrollRevealAndTap(program, in: app, "The Classic program card")
        let day = app.staticTexts["Push"]
        expectElement(day, 10, "Push day")
        day.tap()
        let start = app.buttons["Start Workout"]
        expectElement(start, 10, "Start Workout button")
        start.tap()
        expectElement(app.navigationBars["Workout"], 10, "Workout screen")
    }

    private func dismissKeyboard(_ app: XCUIApplication) {
        let dismiss = app.buttons["Dismiss keyboard"]
        if dismiss.exists { dismiss.tap() }
    }

    /// SecureField typing drops characters — the password-hints re-render
    /// steals first responder after the first char. Pasteboard is atomic and
    /// sidesteps per-char focus entirely.
    private func fillViaPaste(_ element: XCUIElement, _ text: String, app: XCUIApplication) {
        UIPasteboard.general.string = text
        element.tap()
        element.press(forDuration: 1.2)
        let paste = app.menuItems["Paste"]
        if paste.waitForExistence(timeout: 3) {
            paste.tap()
        } else {
            for ch in text {
                element.tap()
                element.typeText(String(ch))
            }
        }
    }

    /// Matches an element of any type by label (NavigationLink labels don't
    /// surface as staticText).
    private func labeled(_ app: XCUIApplication, _ text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", text)).firstMatch
    }

    // MARK: - Tests

    @MainActor
    func testAuthScreenRendersAndValidates() throws {
        let app = launchApp()

        expectElement(app.buttons["Log in"], 15, "Auth mode picker")
        XCTAssertTrue(app.textFields["Email"].waitForExistence(timeout: 5))
        XCTAssertTrue(labeled(app, "Forgot password?").exists)

        app.buttons["Sign up"].tap()
        XCTAssertTrue(app.textFields["Name"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Create Account"].exists)

        // Submit stays disabled with empty fields.
        XCTAssertFalse(app.buttons["Create Account"].isEnabled)

        // Forgot password link navigates to the recovery screen.
        app.buttons["Log in"].tap()
        labeled(app, "Forgot password?").tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5))
    }

    @MainActor
    func testGoldenPathWorkoutFlow() throws {
        let app = launchApp()
        signUp(app)
        openFirstWorkoutDay(app)

        // Exercise card renders with the catalog exercise name.
        XCTAssertTrue(app.staticTexts["Barbell Bench Press"].waitForExistence(timeout: 10))

        // --- Free-text swap: unmatched text becomes today's exercise ---
        let swapButtons = app.buttons.matching(identifier: "Swap exercise for today")
        let firstSwap = swapButtons.element(boundBy: 0)
        XCTAssertTrue(firstSwap.waitForExistence(timeout: 5))
        firstSwap.tap()

        let swapField = app.textFields["Exercise for today"]
        expectElement(swapField, 5, "Swap field")
        swapField.tap()
        swapField.typeText("Band Floor Press")

        let useFreeText = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Use '")).firstMatch
        expectElement(useFreeText, 5, "Use free-text button")
        useFreeText.tap()

        // The typed name replaces the exercise on the card. The planned-day
        // list underneath (DayDetailView stays mounted in the nav stack)
        // correctly still shows the original — session-only swap.
        XCTAssertTrue(app.staticTexts["Band Floor Press"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Barbell Bench Press"].isHittable,
                       "Original name must not be reachable on the workout screen")

        // --- Enter weight + reps, complete a set ---
        // TextField placeholders surface as labels, not identifiers; the
        // covered DayDetailView subtree has no fields, so first match is the
        // first set row of the workout.
        let weightField = app.textFields["Weight"].firstMatch
        expectElement(weightField, 5, "Weight field")
        weightField.tap()
        weightField.typeText("135.5")
        let repsField = app.textFields["Reps"].firstMatch
        repsField.tap()
        // Reps is prefilled — select all before typing or the digits append.
        repsField.press(forDuration: 1.2)
        let selectAll = app.menuItems["Select All"]
        if selectAll.waitForExistence(timeout: 2) { selectAll.tap() }
        repsField.typeText("8")
        XCTAssertEqual(repsField.value as? String, "8", "Reps field should contain 8")
        dismissKeyboard(app)

        // One "Complete set 1" exists per exercise card — first match is the
        // first card's first set.
        let completeSet1 = app.buttons["Complete set 1"].firstMatch
        expectElement(completeSet1, 5, "Complete set button")
        completeSet1.tap()

        // --- Rest bar appears, then un-completing clears it (regression:
        // restEndsAt used to stay set, leaving a stray running timer) ---
        let minus = app.buttons["-5s"]
        expectElement(minus, 8, "Rest bar -5s")
        let set1Done = app.buttons["Set 1 done"].firstMatch
        expectElement(set1Done, 5, "Completed set button")
        set1Done.tap() // un-complete
        XCTAssertTrue(minus.waitForNonExistence(timeout: 5),
                      "Rest bar must disappear when the set is un-completed")

        // Re-complete: bar returns; -5/+5 adjust; Done dismisses.
        expectElement(app.buttons["Complete set 1"].firstMatch, 5, "Complete set button again").tap()
        expectElement(minus, 8, "Rest bar returns")
        XCTAssertTrue(app.buttons["+5s"].exists)
        XCTAssertTrue(app.buttons["Done"].exists)
        minus.tap()
        app.buttons["+5s"].tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(minus.waitForNonExistence(timeout: 5), "Rest bar should dismiss on Done")

        // --- Finish workout -> summary ---
        let finish = app.buttons["Finish Workout"]
        tapWhenHittable(finish, app: app)
        let confirm = app.alerts.buttons["Finish"]
        expectElement(confirm, 5, "Finish confirm")
        confirm.tap()

        let summaryTitle = app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS[c] 'Workout Complete'"))
            .firstMatch
        expectElement(summaryTitle, 10, "Summary title")
        // The swapped exercise name lands in the saved log.
        XCTAssertTrue(app.staticTexts["Band Floor Press"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
    }

    @MainActor
    func testProgramNavigationRenders() throws {
        let app = launchApp()
        signUp(app)

        tapTab(app, "Programs")
        let program = programCard(app, named: "The Classic", id: "classic-physique")
        scrollRevealAndTap(program, in: app, "Program list")

        let day = app.staticTexts["Push"]
        expectElement(day, 10, "Program detail day cards")
        day.tap()

        // Day detail lists the planned exercises.
        expectElement(app.staticTexts["Barbell Bench Press"], 10, "Day detail exercises")
        XCTAssertTrue(app.staticTexts["Incline Dumbbell Press"].exists)
        XCTAssertTrue(app.buttons["Start Workout"].exists)
    }
}
