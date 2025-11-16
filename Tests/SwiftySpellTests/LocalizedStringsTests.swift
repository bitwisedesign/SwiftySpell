//
//  LocalizedStringsTests.swift
//  SwiftySpell
//
//  Tests for check_only_localized_strings rule
//

import XCTest
@testable import SwiftySpellCore

internal class LocalizedStringsTests: XCTestCase {
    var swiftySpell: SwiftySpell?
    let testDirectoryPath = FileManager.default.temporaryDirectory.appendingPathComponent("LocalizedStringsTests").path
    let testTimeout = 5.0

    override func setUp() {
        super.setUp()
        swiftySpell = SwiftySpell()
        try? FileManager.default.createDirectory(atPath: testDirectoryPath, withIntermediateDirectories: true, attributes: nil)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: testDirectoryPath)
        super.tearDown()
    }

    func testCheckOnlyLocalizedStrings() {
        let expectation = expectation(description: "Test check_only_localized_strings rule")

        guard let swiftySpell = swiftySpell else {
            XCTFail("SwiftySpell instance not initialized")
            return
        }

        // Create a config file with check_only_localized_strings enabled
        let configContent = """
        languages:
          - en
        rules:
          - check_only_localized_strings
        """
        let configFilePath = "\(testDirectoryPath)/.swiftyspell.yml"
        try? configContent.write(toFile: configFilePath, atomically: true, encoding: .utf8)
        swiftySpell.setConfig(configFilePath: configFilePath)

        // Create a test file with both localized and non-localized misspellings
        let testCode = """
        import Foundation

        // Localized strings - SHOULD be checked
        let localizedText = NSLocalizedString("Helo world", comment: "Greeting")
        let modernLocalized = String(localized: "Welcom message")

        // Non-localized strings - SHOULD NOT be checked
        let internalString = "This is an internall error message"
        let debugMessage = "Debugg mode enabled"

        // Variable names - SHOULD NOT be checked
        var occurence = 0
        var temporyValue = 42

        // Function names - SHOULD NOT be checked
        func processsData() {
            print("Processing")
        }
        """

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        try? testCode.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let misspelledWords = swiftySpell.allMisspelledWords.sorted()

            // Should only find misspellings in localized strings (Helo, Welcom)
            // Should NOT find: internall, Debugg, occurence, temporyValue, processsData
            XCTAssertEqual(misspelledWords.count, 2, "Should only find 2 misspelled words in localized strings")
            XCTAssertTrue(misspelledWords.contains("Helo"), "Should find 'Helo' in NSLocalizedString")
            XCTAssertTrue(misspelledWords.contains("Welcom"), "Should find 'Welcom' in String(localized:)")

            // Verify it does NOT find non-localized misspellings
            XCTAssertFalse(misspelledWords.contains("internall"), "Should NOT check non-localized strings")
            XCTAssertFalse(misspelledWords.contains("Debugg"), "Should NOT check non-localized strings")
            XCTAssertFalse(misspelledWords.contains("occurence"), "Should NOT check variable names")
            XCTAssertFalse(misspelledWords.contains("temporyValue"), "Should NOT check variable names")
            XCTAssertFalse(misspelledWords.contains("processsData"), "Should NOT check function names")

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testDefaultBehaviorWithoutRule() {
        let expectation = expectation(description: "Test default behavior without check_only_localized_strings")

        guard let swiftySpell = swiftySpell else {
            XCTFail("SwiftySpell instance not initialized")
            return
        }

        // Use default config (rule NOT enabled)
        swiftySpell.setConfig()

        // Test code with misspellings in various locations
        let testCode = """
        import Foundation

        let localizedText = NSLocalizedString("Helo world", comment: "Greeting")
        let internalString = "Errror message"
        var occurence = 0

        func processs() {
            print("Processing")
        }
        """

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        try? testCode.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let misspelledWords = swiftySpell.allMisspelledWords.sorted()

            // With default behavior, should find ALL misspellings including strings, vars, functions
            XCTAssertTrue(misspelledWords.count >= 4, "Should find multiple misspelled words in default mode, found: \(misspelledWords)")
            XCTAssertTrue(misspelledWords.contains("Helo"), "Should find 'Helo' in NSLocalizedString")
            XCTAssertTrue(misspelledWords.contains("Errror"), "Should find 'Errror' in regular string literal")
            XCTAssertTrue(misspelledWords.contains("occurence"), "Should find 'occurence' in variable name")
            XCTAssertTrue(misspelledWords.contains("processs"), "Should find 'processs' in function name")

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testSwiftUITextDetection() {
        let expectation = expectation(description: "Test SwiftUI Text detection")

        guard let swiftySpell = swiftySpell else {
            XCTFail("SwiftySpell instance not initialized")
            return
        }

        let configContent = """
        languages:
          - en
        rules:
          - check_only_localized_strings
        """
        let configFilePath = "\(testDirectoryPath)/.swiftyspell.yml"
        try? configContent.write(toFile: configFilePath, atomically: true, encoding: .utf8)
        swiftySpell.setConfig(configFilePath: configFilePath)

        let testCode = """
        import SwiftUI

        struct ContentView: View {
            var body: some View {
                VStack {
                    Text("Helo from SwiftUI")
                    Text("Another misspeling here")
                }
                .navigationTitle("Settinggs")
            }
        }

        let nonLocalizedString = "This has a missspelling"
        """

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        try? testCode.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let misspelledWords = swiftySpell.allMisspelledWords.sorted()

            // Should find misspellings in SwiftUI Text and navigationTitle
            XCTAssertTrue(misspelledWords.contains("Helo"), "Should detect misspelling in Text()")
            XCTAssertTrue(misspelledWords.contains("misspeling"), "Should detect misspelling in Text()")
            XCTAssertTrue(misspelledWords.contains("Settinggs"), "Should detect misspelling in .navigationTitle()")

            // Should NOT find non-localized string misspelling
            XCTAssertFalse(misspelledWords.contains("missspelling"), "Should NOT check non-localized strings")

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testLabelSystemImageNotChecked() {
        let expectation = expectation(description: "Test that systemImage parameter is NOT checked")

        guard let swiftySpell = swiftySpell else {
            XCTFail("SwiftySpell instance not initialized")
            return
        }

        let configContent = """
        languages:
          - en
        rules:
          - check_only_localized_strings
        """
        let configFilePath = "\(testDirectoryPath)/.swiftyspell.yml"
        try? configContent.write(toFile: configFilePath, atomically: true, encoding: .utf8)
        swiftySpell.setConfig(configFilePath: configFilePath)

        let testCode = """
        import SwiftUI

        struct ContentView: View {
            var body: some View {
                VStack {
                    // Should check "Search" title but NOT "magnifyingglass" systemImage
                    Label("Search", systemImage: "magnifyingglass")
                    Label("Searcch", systemImage: "magnifyingglass")

                    // Should check "Settings" title but NOT "gearshape" systemImage
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        """

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        try? testCode.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let misspelledWords = swiftySpell.allMisspelledWords.sorted()

            // Should find the misspelling in Label title
            XCTAssertTrue(misspelledWords.contains("Searcch"), "Should detect misspelling in Label title")

            // Should NOT find SF Symbol names as misspellings
            XCTAssertFalse(misspelledWords.contains("magnifyingglass"), "Should NOT check systemImage parameter (SF Symbol name)")
            XCTAssertFalse(misspelledWords.contains("gearshape"), "Should NOT check systemImage parameter (SF Symbol name)")

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testImageSystemNameNotChecked() {
        let expectation = expectation(description: "Test that Image systemName parameter is NOT checked")

        guard let swiftySpell = swiftySpell else {
            XCTFail("SwiftySpell instance not initialized")
            return
        }

        let configContent = """
        languages:
          - en
        rules:
          - check_only_localized_strings
        """
        let configFilePath = "\(testDirectoryPath)/.swiftyspell.yml"
        try? configContent.write(toFile: configFilePath, atomically: true, encoding: .utf8)
        swiftySpell.setConfig(configFilePath: configFilePath)

        let testCode = """
        import SwiftUI

        struct ContentView: View {
            var body: some View {
                VStack {
                    // Should NOT check "questionmark" or "exclamationmark" - these are SF Symbol names
                    Image(systemName: "questionmark")
                    Image(systemName: "exclamationmark")

                    // Should check Text content
                    Text("Searcch results")
                }
            }
        }
        """

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        try? testCode.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let misspelledWords = swiftySpell.allMisspelledWords.sorted()

            // Should find the misspelling in Text
            XCTAssertTrue(misspelledWords.contains("Searcch"), "Should detect misspelling in Text()")

            // Should NOT find SF Symbol names as misspellings
            XCTAssertFalse(misspelledWords.contains("questionmark"), "Should NOT check Image systemName parameter (SF Symbol name)")
            XCTAssertFalse(misspelledWords.contains("exclamationmark"), "Should NOT check Image systemName parameter (SF Symbol name)")

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testDispatchQueueLabelNotChecked() {
        let expectation = expectation(description: "Test that DispatchQueue label parameter is NOT checked")

        guard let swiftySpell = swiftySpell else {
            XCTFail("SwiftySpell instance not initialized")
            return
        }

        let configContent = """
        languages:
          - en
        rules:
          - check_only_localized_strings
        """
        let configFilePath = "\(testDirectoryPath)/.swiftyspell.yml"
        try? configContent.write(toFile: configFilePath, atomically: true, encoding: .utf8)
        swiftySpell.setConfig(configFilePath: configFilePath)

        let testCode = """
        import Foundation

        class MediaViewModel {
            // Should NOT check the DispatchQueue label - it's an internal identifier
            private let queue = DispatchQueue(label: "com.mygolfworks.GolfPracticeUIKit.MediaListViewModel.mediaItemsQueue")

            // Should check localized strings
            let title = NSLocalizedString("Searcch Results", comment: "Title")
        }
        """

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        try? testCode.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let misspelledWords = swiftySpell.allMisspelledWords.sorted()

            // Should find the misspelling in NSLocalizedString
            XCTAssertTrue(misspelledWords.contains("Searcch"), "Should detect misspelling in NSLocalizedString")

            // Should NOT find words from DispatchQueue label
            XCTAssertFalse(misspelledWords.contains("mygolfworks"), "Should NOT check DispatchQueue label parameter")
            XCTAssertFalse(misspelledWords.contains("GolfPracticeUIKit"), "Should NOT check DispatchQueue label parameter")
            XCTAssertFalse(misspelledWords.contains("MediaListViewModel"), "Should NOT check DispatchQueue label parameter")
            XCTAssertFalse(misspelledWords.contains("mediaItemsQueue"), "Should NOT check DispatchQueue label parameter")

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testAccessibilityIdentifierNotChecked() {
        let expectation = expectation(description: "Test that accessibilityIdentifier is NOT checked")

        guard let swiftySpell = swiftySpell else {
            XCTFail("SwiftySpell instance not initialized")
            return
        }

        let configContent = """
        languages:
          - en
        rules:
          - check_only_localized_strings
        """
        let configFilePath = "\(testDirectoryPath)/.swiftyspell.yml"
        try? configContent.write(toFile: configFilePath, atomically: true, encoding: .utf8)
        swiftySpell.setConfig(configFilePath: configFilePath)

        let testCode = """
        import SwiftUI

        struct ContentView: View {
            var body: some View {
                VStack {
                    // Should NOT check accessibilityIdentifier - it's for testing/automation
                    Button("Start") {}
                        .accessibilityIdentifier("btn_get_started")

                    Text("Errror message")
                        .accessibilityIdentifier("lbl_error_msg")

                // Button with label closure - accessibilityIdentifier should NOT be checked
                Button {
                    print("Tapped")
                } label: {
                    Text("Get Started")
                }
                .accessibilityIdentifier("btn_get_started_v2")

                // Button with label closure - accessibilityLabel SHOULD be checked (VoiceOver speaks it)
                // but accessibilityIdentifier should NOT be checked (it's for testing/automation)
                Button {
                    print("Tapped")
                } label: {
                    Text("Continue")
                }
                .accessibilityLabel(Text("Contineu"))
                .accessibilityIdentifier("btnv3_get_started")

                // VStack with accessibilityIdentifier - should NOT be checked
                    VStack {
                        Text("Content")
                    }
                    .accessibilityIdentifier("vstack_main_content")

                    // Image with accessibilityIdentifier - should NOT be checked
                    Image(systemName: "star")
                        .accessibilityIdentifier("img_star_icon")

                    // HStack with accessibilityIdentifier - should NOT be checked
                    HStack {
                        Text("Info")
                    }
                    .accessibilityIdentifier("hstack_info_row")

                    // Should check the actual user-facing text
                    Text("Welcom to the app")
                }
            }
        }
        """

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        try? testCode.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let misspelledWords = swiftySpell.allMisspelledWords.sorted()

            print("DEBUG testAccessibilityIdentifierNotChecked: Found misspellings: \(misspelledWords)")

            // Should find the misspelling in user-facing Text
            XCTAssertTrue(misspelledWords.contains("Welcom"), "Should detect misspelling in Text(), found: \(misspelledWords)")

            // Should find misspelling in accessibilityLabel (it's spoken by VoiceOver)
            XCTAssertTrue(misspelledWords.contains("Contineu"), "Should detect misspelling in accessibilityLabel (VoiceOver), found: \(misspelledWords)")

            // Should NOT find words from accessibilityIdentifier on various views
            XCTAssertFalse(misspelledWords.contains("btn"), "Should NOT check accessibilityIdentifier on Button")
            XCTAssertFalse(misspelledWords.contains("btnv3"), "Should NOT check accessibilityIdentifier on Button that also has accessibilityLabel")
            XCTAssertFalse(misspelledWords.contains("lbl"), "Should NOT check accessibilityIdentifier on Text modifier")
            XCTAssertFalse(misspelledWords.contains("msg"), "Should NOT check accessibilityIdentifier")
            XCTAssertFalse(misspelledWords.contains("vstack"), "Should NOT check accessibilityIdentifier on VStack")
            XCTAssertFalse(misspelledWords.contains("img"), "Should NOT check accessibilityIdentifier on Image")
            XCTAssertFalse(misspelledWords.contains("hstack"), "Should NOT check accessibilityIdentifier on HStack")

            // Should check Text content even when the view has an accessibilityIdentifier modifier
            XCTAssertTrue(misspelledWords.contains("Errror"), "Should check Text content even with accessibilityIdentifier modifier")

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testIgnoreLoremIpsumWithCheckOnlyLocalizedStrings() {
        let expectation = expectation(description: "Test that ignore_lorem_ipsum works with check_only_localized_strings")

        guard let swiftySpell = swiftySpell else {
            XCTFail("SwiftySpell instance not initialized")
            return
        }

        let configContent = """
        languages:
          - en
        rules:
          - check_only_localized_strings
          - ignore_lorem_ipsum
        """
        let configFilePath = "\(testDirectoryPath)/.swiftyspell.yml"
        try? configContent.write(toFile: configFilePath, atomically: true, encoding: .utf8)
        swiftySpell.setConfig(configFilePath: configFilePath)

        let testCode = """
        import SwiftUI

        struct ContentView: View {
            var body: some View {
                VStack {
                    // Should check these user-facing strings
                    Text("Welcom to the app")
                    Text("This is a tst")

                    // Should NOT flag lorem ipsum words even in user-facing text
                    Text("Lorem ipsum dolor sit amet")
                    Text("consectetur adipiscing elit")
                }
            }
        }
        """

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        try? testCode.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let misspelledWords = swiftySpell.allMisspelledWords.sorted()

            print("DEBUG testIgnoreLoremIpsumWithCheckOnlyLocalizedStrings: Found misspellings: \(misspelledWords)")

            // Should find real misspellings
            XCTAssertTrue(misspelledWords.contains("Welcom"), "Should detect misspelling in Text(), found: \(misspelledWords)")
            XCTAssertTrue(misspelledWords.contains("tst"), "Should detect misspelling in Text(), found: \(misspelledWords)")

            // Should NOT find lorem ipsum words (they should be ignored)
            XCTAssertFalse(misspelledWords.contains("Lorem"), "Should NOT flag lorem ipsum words (ignore_lorem_ipsum rule)")
            XCTAssertFalse(misspelledWords.contains("ipsum"), "Should NOT flag lorem ipsum words (ignore_lorem_ipsum rule)")
            XCTAssertFalse(misspelledWords.contains("dolor"), "Should NOT flag lorem ipsum words (ignore_lorem_ipsum rule)")
            XCTAssertFalse(misspelledWords.contains("amet"), "Should NOT flag lorem ipsum words (ignore_lorem_ipsum rule)")
            XCTAssertFalse(misspelledWords.contains("consectetur"), "Should NOT flag lorem ipsum words (ignore_lorem_ipsum rule)")
            XCTAssertFalse(misspelledWords.contains("adipiscing"), "Should NOT flag lorem ipsum words (ignore_lorem_ipsum rule)")
            XCTAssertFalse(misspelledWords.contains("elit"), "Should NOT flag lorem ipsum words (ignore_lorem_ipsum rule)")

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testIgnoreUrlsWithCheckOnlyLocalizedStrings() {
        let expectation = expectation(description: "Test that ignore_urls works with check_only_localized_strings")

        guard let swiftySpell = swiftySpell else {
            XCTFail("SwiftySpell instance not initialized")
            return
        }

        let configContent = """
        languages:
          - en
        rules:
          - check_only_localized_strings
          - ignore_urls
        """
        let configFilePath = "\(testDirectoryPath)/.swiftyspell.yml"
        try? configContent.write(toFile: configFilePath, atomically: true, encoding: .utf8)
        swiftySpell.setConfig(configFilePath: configFilePath)

        let testCode = """
        import SwiftUI

        struct ContentView: View {
            var body: some View {
                VStack {
                    // Should check these user-facing strings
                    Text("Welcom to the app")
                    Text("Visit our websit")

                    // Should NOT flag complete URLs with protocols
                    Text("https://example.com")
                    Text("http://test.org/path")
                }
            }
        }
        """

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        try? testCode.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let misspelledWords = swiftySpell.allMisspelledWords.sorted()

            print("DEBUG testIgnoreUrlsWithCheckOnlyLocalizedStrings: Found misspellings: \(misspelledWords)")

            // Should find real misspellings
            XCTAssertTrue(misspelledWords.contains("Welcom"), "Should detect misspelling in Text(), found: \(misspelledWords)")
            XCTAssertTrue(misspelledWords.contains("websit"), "Should detect misspelling in Text(), found: \(misspelledWords)")

            // Should NOT find complete URLs with protocols (they should be ignored as complete strings)
            // Note: ignore_urls only works for complete URL strings with protocols (http://, https://, ftp://)
            // It checks the entire string before word-splitting occurs
            XCTAssertFalse(misspelledWords.contains("https://example.com"), "Should NOT flag complete URLs (ignore_urls rule)")
            XCTAssertFalse(misspelledWords.contains("http://test.org/path"), "Should NOT flag complete URLs (ignore_urls rule)")

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testCustomModifiersWithSystemImage() {
        let expectation = expectation(description: "Test that systemImage parameters in custom modifiers are NOT checked")

        guard let swiftySpell = swiftySpell else {
            XCTFail("SwiftySpell instance not initialized")
            return
        }

        let configContent = """
        languages:
          - en
        rules:
          - check_only_localized_strings
        """
        let configFilePath = "\(testDirectoryPath)/.swiftyspell.yml"
        try? configContent.write(toFile: configFilePath, atomically: true, encoding: .utf8)
        swiftySpell.setConfig(configFilePath: configFilePath)

        let testCode = """
        import SwiftUI

        struct ContentView: View {
            var body: some View {
                VStack {
                    // Standard SwiftUI with systemImage - SHOULD work
                    Label("Searcch", systemImage: "magnifying.glass")

                    // Custom function with systemImage parameter
                    // Note: Our detector checks the parameter NAME, not the function name
                    // So this SHOULD exclude the systemImage value
                    CustomView(
                        title: "Welcom",
                        systemImage: "arrow.trianglehead.clockwise"
                    )
                }
            }
        }
        """

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        try? testCode.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let misspelledWords = swiftySpell.allMisspelledWords.sorted()

            print("DEBUG testCustomModifiersWithSystemImage: Found misspellings: \(misspelledWords)")

            // Should find misspellings in user-facing text
            XCTAssertTrue(misspelledWords.contains("Searcch"), "Should detect misspelling in Label title, found: \(misspelledWords)")
            XCTAssertTrue(misspelledWords.contains("Welcom"), "Should detect misspelling in title parameter, found: \(misspelledWords)")

            // Should NOT find SF Symbol names from systemImage parameters (works for ANY function/initializer)
            XCTAssertFalse(misspelledWords.contains("magnifying"), "Should NOT check systemImage parameter")
            XCTAssertFalse(misspelledWords.contains("arrow"), "Should NOT check systemImage parameter in custom function")
            XCTAssertFalse(misspelledWords.contains("trianglehead"), "Should NOT check systemImage parameter in custom function")
            XCTAssertFalse(misspelledWords.contains("clockwise"), "Should NOT check systemImage parameter in custom function")

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testFormatSpecifiersAreStripped() {
        let expectation = expectation(description: "Test that format specifiers like %.1f are stripped")

        guard let swiftySpell = swiftySpell else {
            XCTFail("SwiftySpell instance not initialized")
            return
        }

        let configContent = """
        languages:
          - en
        rules:
          - check_only_localized_strings
        """
        let configFilePath = "\(testDirectoryPath)/.swiftyspell.yml"
        try? configContent.write(toFile: configFilePath, atomically: true, encoding: .utf8)
        swiftySpell.setConfig(configFilePath: configFilePath)

        let testCode = """
        import SwiftUI

        struct ContentView: View {
            let hours: Double = 3.5
            let count: Int = 42

            var body: some View {
                VStack {
                    // Format specifiers should be stripped, only "hours" should be checked
                    Text(String(format: "%.1f hours", hours))
                    Text(String(format: "%d items", count))
                    Text(String(format: "%.2f%%", 95.5))

                    // Test with misspellings - format specifiers stripped, but words checked
                    Text(String(format: "%.1f hourss", hours))  // "hourss" is misspelled
                    Text(String(format: "%d itemms", count))  // "itemms" is misspelled
                    Text(String(format: "Value: %@ dolars", "test"))  // "dolars" is misspelled

                    // Multiple format specifiers
                    Text(String(format: "%d of %d completd", 5, 10))  // "completd" is misspelled
                }
            }
        }
        """

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        try? testCode.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let misspelledWords = swiftySpell.allMisspelledWords.sorted()

            print("DEBUG testFormatSpecifiersAreStripped: Found misspellings: \(misspelledWords)")

            // Should find actual misspellings in the words
            XCTAssertTrue(misspelledWords.contains("hourss"), "Should detect 'hourss' (format specifier should be stripped), found: \(misspelledWords)")
            XCTAssertTrue(misspelledWords.contains("itemms"), "Should detect 'itemms' (format specifier should be stripped), found: \(misspelledWords)")
            XCTAssertTrue(misspelledWords.contains("dolars"), "Should detect 'dolars' (format specifier should be stripped), found: \(misspelledWords)")
            XCTAssertTrue(misspelledWords.contains("completd"), "Should detect 'completd' (format specifier should be stripped), found: \(misspelledWords)")

            // Should NOT find format specifiers themselves
            XCTAssertFalse(misspelledWords.contains("%.1f"), "Should NOT check format specifier %.1f")
            XCTAssertFalse(misspelledWords.contains("%d"), "Should NOT check format specifier %d")
            XCTAssertFalse(misspelledWords.contains("%.2f"), "Should NOT check format specifier %.2f")
            XCTAssertFalse(misspelledWords.contains("%@"), "Should NOT check format specifier %@")

            // Should NOT find correctly spelled words
            XCTAssertFalse(misspelledWords.contains("hours"), "Should NOT flag correctly spelled 'hours'")
            XCTAssertFalse(misspelledWords.contains("items"), "Should NOT flag correctly spelled 'items'")

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testStringInterpolationIsStripped() {
        let expectation = expectation(description: "Test that string interpolation like \\(variable) is stripped")

        guard let swiftySpell = swiftySpell else {
            XCTFail("SwiftySpell instance not initialized")
            return
        }

        let configContent = """
        languages:
          - en
        rules:
          - check_only_localized_strings
        """
        let configFilePath = "\(testDirectoryPath)/.swiftyspell.yml"
        try? configContent.write(toFile: configFilePath, atomically: true, encoding: .utf8)
        swiftySpell.setConfig(configFilePath: configFilePath)

        let testCode = """
        import SwiftUI

        struct Entry {
            let numAchievedGoals: Int
            let userName: String
        }

        struct ContentView: View {
            let entry = Entry(numAchievedGoals: 5, userName: "John")

            var body: some View {
                VStack {
                    // String interpolation should be stripped, only surrounding words checked
                    Text("\\(entry.numAchievedGoals)")
                    Text("\\(entry.numAchievedGoals) goals")
                    Text("User: \\(entry.userName)")
                    Text("\\(entry.userName) has \\(entry.numAchievedGoals) goals")

                    // Test with misspellings - interpolation stripped, but words checked
                    Text("\\(entry.numAchievedGoals) goalsss")  // "goalsss" is misspelled
                    Text("Usser: \\(entry.userName)")  // "Usser" is misspelled
                    Text("\\(entry.userName) has \\(entry.numAchievedGoals) trophys")  // "trophys" is misspelled

                    // Complex interpolation expressions
                    Text("Progress: \\(entry.numAchievedGoals * 100)%")
                    Text("Welcom \\(entry.userName)!")  // "Welcom" is misspelled
                }
            }
        }
        """

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        try? testCode.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let misspelledWords = swiftySpell.allMisspelledWords.sorted()

            print("DEBUG testStringInterpolationIsStripped: Found misspellings: \(misspelledWords)")

            // Should find actual misspellings in the words
            XCTAssertTrue(misspelledWords.contains("goalsss"), "Should detect 'goalsss' (interpolation should be stripped), found: \(misspelledWords)")
            XCTAssertTrue(misspelledWords.contains("Usser"), "Should detect 'Usser' (interpolation should be stripped), found: \(misspelledWords)")
            XCTAssertTrue(misspelledWords.contains("trophys"), "Should detect 'trophys' (interpolation should be stripped), found: \(misspelledWords)")
            XCTAssertTrue(misspelledWords.contains("Welcom"), "Should detect 'Welcom' (interpolation should be stripped), found: \(misspelledWords)")

            // Should NOT find variable names or property accesses from interpolation
            XCTAssertFalse(misspelledWords.contains("numAchievedGoals"), "Should NOT check variable name from interpolation")
            XCTAssertFalse(misspelledWords.contains("userName"), "Should NOT check variable name from interpolation")
            XCTAssertFalse(misspelledWords.contains("entry"), "Should NOT check variable name from interpolation")

            // Should NOT find correctly spelled words
            XCTAssertFalse(misspelledWords.contains("goals"), "Should NOT flag correctly spelled 'goals'")
            XCTAssertFalse(misspelledWords.contains("User"), "Should NOT flag correctly spelled 'User'")
            XCTAssertFalse(misspelledWords.contains("has"), "Should NOT flag correctly spelled 'has'")

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testMixedFormatSpecifiersAndInterpolation() {
        let expectation = expectation(description: "Test that both format specifiers and interpolation are stripped together")

        guard let swiftySpell = swiftySpell else {
            XCTFail("SwiftySpell instance not initialized")
            return
        }

        let configContent = """
        languages:
          - en
        rules:
          - check_only_localized_strings
        """
        let configFilePath = "\(testDirectoryPath)/.swiftyspell.yml"
        try? configContent.write(toFile: configFilePath, atomically: true, encoding: .utf8)
        swiftySpell.setConfig(configFilePath: configFilePath)

        let testCode = """
        import SwiftUI

        struct ContentView: View {
            let score: Double = 98.5
            let name: String = "John"

            var body: some View {
                VStack {
                    // Mix of format specifiers and interpolation
                    Text("\\(name) scored %.1f%%")
                    Text("User \\(name) has %d points")

                    // With misspellings
                    Text("\\(name) scorred %.1f%%")  // "scorred" is misspelled
                    Text("Usser \\(name) has %d pointts")  // "Usser" and "pointts" are misspelled
                }
            }
        }
        """

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        try? testCode.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let misspelledWords = swiftySpell.allMisspelledWords.sorted()

            print("DEBUG testMixedFormatSpecifiersAndInterpolation: Found misspellings: \(misspelledWords)")

            // Should find actual misspellings
            XCTAssertTrue(misspelledWords.contains("scorred"), "Should detect 'scorred', found: \(misspelledWords)")
            XCTAssertTrue(misspelledWords.contains("Usser"), "Should detect 'Usser', found: \(misspelledWords)")
            XCTAssertTrue(misspelledWords.contains("pointts"), "Should detect 'pointts', found: \(misspelledWords)")

            // Should NOT find format specifiers or interpolation content
            XCTAssertFalse(misspelledWords.contains("%.1f"), "Should NOT check format specifier")
            XCTAssertFalse(misspelledWords.contains("%d"), "Should NOT check format specifier")
            XCTAssertFalse(misspelledWords.contains("name"), "Should NOT check variable name from interpolation")

            // Should NOT find correctly spelled words
            XCTAssertFalse(misspelledWords.contains("scored"), "Should NOT flag correctly spelled 'scored'")
            XCTAssertFalse(misspelledWords.contains("User"), "Should NOT flag correctly spelled 'User'")
            XCTAssertFalse(misspelledWords.contains("points"), "Should NOT flag correctly spelled 'points'")

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }
}
