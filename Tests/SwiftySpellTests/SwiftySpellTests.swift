//
//  SwiftySpellTests.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 12/10/2024.
//

import XCTest
@testable import SwiftySpellCore

internal class SwiftySpellTests: XCTestCase {
    var swiftySpell: SwiftySpell?
    let testDirectoryPath = FileManager.default.temporaryDirectory.appendingPathComponent("SwiftySpellTests").path
    let testTimeout = 5.0

    override func setUp() {
        super.setUp()
        swiftySpell = SwiftySpell()
        guard let swiftySpell = swiftySpell else {
            return
        }
        swiftySpell.setConfig()
        try? FileManager.default.createDirectory(atPath: testDirectoryPath, withIntermediateDirectories: true, attributes: nil)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: testDirectoryPath)
        super.tearDown()
    }

    func testInitCommand() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        guard let swiftySpell = swiftySpell else {
            return
        }

        DispatchQueue.global().async {
            let result = swiftySpell.createConfigFile(at: self.testDirectoryPath)

            let configFilePath = "\(self.testDirectoryPath)/\(Constants.configFileName)"
            XCTAssertTrue(FileManager.default.fileExists(atPath: configFilePath), "Config file should be created")

            expectation.fulfill()
        }

        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testLoadConfig() {
        let testConfigPath = "\(testDirectoryPath)/\(Constants.configFileName)"
        let testConfig = """
                    # Languages to check
                    languages:
                      - en
                      - en_GB

                    # Directories/Files/Regular expressions to exclude
                    exclude:
                      - Pods
                      - Constants.swift

                    # Rules to apply
                    rules:
                      - support_flat_case
                      - support_one_line_comment
                      - support_multi_line_comment
                      #- support_british_words
                      #- ignore_capitalization
                      - ignore_swift_keywords
                      - ignore_commonly_used_words
                      #- ignore_shortened_words
                      #- ignore_lorem_ipsum
                      #- ignore_html_tags
                      - ignore_urls

                    # Words/Regular expressions to ignore
                    ignore:
                      - iOS
            """
        try? testConfig.write(toFile: testConfigPath, atomically: true, encoding: .utf8)

        guard let swiftySpell = swiftySpell else {
            return
        }

        swiftySpell.setConfig(configFilePath: testConfigPath)

        guard let config = swiftySpell.config else {
            return
        }

        XCTAssertTrue(config.ignore.contains("iOS"))
        XCTAssertEqual(config.languages, ["en", "en_GB"])
    }

    func testCheckSpellingForVariables() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        guard let swiftySpell = swiftySpell else {
            return
        }

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        let swiftCode = SwiftCodesForTests.forVariables()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let array = swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(array, swiftCode.misspelledWords.sorted())

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testCheckSpellingForStrings() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        guard let swiftySpell = swiftySpell else {
            return
        }

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        let swiftCode = SwiftCodesForTests.forStrings()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let array = swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(array, swiftCode.misspelledWords.sorted())

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testCheckSpellingForEnumCases() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        guard let swiftySpell = swiftySpell else {
            return
        }

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        let swiftCode = SwiftCodesForTests.forEnumCases()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let array = swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(array, swiftCode.misspelledWords.sorted())

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testCheckSpellingForComments() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        guard let swiftySpell = swiftySpell else {
            return
        }

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        let swiftCode = SwiftCodesForTests.forComments()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let array = swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(array, swiftCode.misspelledWords.sorted())

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testCheckSpellingForClassWithAttributes() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        guard let swiftySpell = swiftySpell else {
            return
        }

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        let swiftCode = SwiftCodesForTests.forClassWithAttributes()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let array = swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(array, swiftCode.misspelledWords.sorted())

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testCheckSpellingForClassWithEnumsAndFunctions() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        guard let swiftySpell = swiftySpell else {
            return
        }

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        let swiftCode = SwiftCodesForTests.forClassWithEnumsAndFunctions()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let array = swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(array, swiftCode.misspelledWords.sorted())

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testCheckSpellingForManyCodeSegments() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        guard let swiftySpell = swiftySpell else {
            return
        }

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        let swiftCode = SwiftCodesForTests.forManyCodeSegments()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let array = swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(array, swiftCode.misspelledWords.sorted())

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testFixCommand() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        guard let swiftySpell = swiftySpell else {
            return
        }

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        let swiftCode = SwiftCodesForTests.forVariables()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: true, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let fileContent = try? String(contentsOfFile: testFilePath)
            XCTAssertEqual(fileContent, swiftCode.code.replace(swiftCode.misspelledWords[0], swiftCode.correctedWords[0]))

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testLanguagesCommand() {
        guard let swiftySpell = swiftySpell else {
            return
        }

        let languages = swiftySpell.getSupportedLanguages()
        XCTAssertNotNil(languages)
    }

    func testRulesCommand() {
        guard let swiftySpell = swiftySpell else {
            return
        }

        let rules = swiftySpell.getSupportedRules()
        XCTAssertNotNil(rules)
    }

    func testVersionCommand() {
        guard let swiftySpell = swiftySpell else {
            return
        }

        let version = swiftySpell.getCurrentVersion()
        XCTAssertNotNil(version)
    }

    func testCheckSingleFile() {
        let expectation = expectation(description: "Test checking single file")

        guard let swiftySpell = swiftySpell else {
            return
        }

        let testFilePath = "\(testDirectoryPath)/SingleFile.swift"
        let swiftCode = SwiftCodesForTests.forVariables()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check([testFilePath], withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let array = swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(array, swiftCode.misspelledWords.sorted())

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testCheckMultipleFiles() {
        let expectation = expectation(description: "Test checking multiple files")

        guard let swiftySpell = swiftySpell else {
            return
        }

        let testFile1Path = "\(testDirectoryPath)/File1.swift"
        let testFile2Path = "\(testDirectoryPath)/File2.swift"
        let swiftCode1 = SwiftCodesForTests.forVariables()
        let swiftCode2 = SwiftCodesForTests.forStrings()

        try? swiftCode1.code.write(toFile: testFile1Path, atomically: true, encoding: .utf8)
        try? swiftCode2.code.write(toFile: testFile2Path, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check([testFile1Path, testFile2Path], withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let expectedWords = (swiftCode1.misspelledWords + swiftCode2.misspelledWords).sorted()
            let actualWords = swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(actualWords, expectedWords)

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testCheckMixedPathsAndFiles() {
        let expectation = expectation(description: "Test checking mixed directory and files")

        guard let swiftySpell = swiftySpell else {
            return
        }

        // Create a subdirectory with a file
        let subDirPath = "\(testDirectoryPath)/SubDir"
        try? FileManager.default.createDirectory(atPath: subDirPath, withIntermediateDirectories: true, attributes: nil)

        let testFile1Path = "\(testDirectoryPath)/File1.swift"
        let testFile2Path = "\(subDirPath)/File2.swift"
        let swiftCode1 = SwiftCodesForTests.forVariables()
        let swiftCode2 = SwiftCodesForTests.forStrings()

        try? swiftCode1.code.write(toFile: testFile1Path, atomically: true, encoding: .utf8)
        try? swiftCode2.code.write(toFile: testFile2Path, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            // Check explicit file and directory
            swiftySpell.check([testFile1Path, subDirPath], withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let expectedWords = (swiftCode1.misspelledWords + swiftCode2.misspelledWords).sorted()
            let actualWords = swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(actualWords, expectedWords)

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testFixMultipleFiles() {
        let expectation = expectation(description: "Test fixing multiple files")

        guard let swiftySpell = swiftySpell else {
            return
        }

        let testFile1Path = "\(testDirectoryPath)/FixFile1.swift"
        let testFile2Path = "\(testDirectoryPath)/FixFile2.swift"
        let swiftCode1 = SwiftCodesForTests.forVariables()
        let swiftCode2 = SwiftCodesForTests.forVariables()

        try? swiftCode1.code.write(toFile: testFile1Path, atomically: true, encoding: .utf8)
        try? swiftCode2.code.write(toFile: testFile2Path, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check([testFile1Path, testFile2Path], withFix: true, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let fileContent1 = try? String(contentsOfFile: testFile1Path)
            let fileContent2 = try? String(contentsOfFile: testFile2Path)

            if !swiftCode1.misspelledWords.isEmpty {
                XCTAssertEqual(fileContent1, swiftCode1.code.replace(swiftCode1.misspelledWords[0], swiftCode1.correctedWords[0]))
            }
            if !swiftCode2.misspelledWords.isEmpty {
                XCTAssertEqual(fileContent2, swiftCode2.code.replace(swiftCode2.misspelledWords[0], swiftCode2.correctedWords[0]))
            }

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testNonExistentFileHandling() {
        let expectation = expectation(description: "Test handling non-existent file")

        guard let swiftySpell = swiftySpell else {
            return
        }

        let nonExistentPath = "\(testDirectoryPath)/NonExistent.swift"

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check([nonExistentPath], withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            // Should handle gracefully without crashing
            XCTAssertEqual(swiftySpell.allMisspelledWords.count, 0)

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }
}
