import XCTest
@testable import SmithCore

final class QuestionAnalyzerTests: XCTestCase {
    func testCPUQuestion() {
        XCTAssertEqual(QuestionAnalyzer.categorize("How do I check CPU usage?"), .cpu)
    }

    func testMemoryQuestion() {
        XCTAssertEqual(QuestionAnalyzer.categorize("What's using my memory?"), .memory)
    }

    func testStorageSynonym() {
        XCTAssertEqual(QuestionAnalyzer.categorize("I'm running low on hard drive space"), .storage)
    }

    func testBatteryQuestion() {
        XCTAssertEqual(QuestionAnalyzer.categorize("How can I improve battery life?"), .battery)
    }

    func testNetworkQuestion() {
        XCTAssertEqual(QuestionAnalyzer.categorize("Why is my WiFi slow?"), .network)
    }

    func testFileSystemQuestion() {
        XCTAssertEqual(QuestionAnalyzer.categorize("Where are my log files stored?"), .fileSystem)
    }

    func testIdentityQuestion() {
        XCTAssertEqual(QuestionAnalyzer.categorize("Who are you?"), .identity)
    }

    func testGeneralFallback() {
        XCTAssertEqual(QuestionAnalyzer.categorize("Tell me a joke"), .general)
    }
}
