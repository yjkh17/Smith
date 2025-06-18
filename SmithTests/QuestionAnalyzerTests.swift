import XCTest
@testable import Smith

final class QuestionAnalyzerTests: XCTestCase {
    func testCPUCategory() {
        XCTAssertEqual(QuestionAnalyzer.categorize("How is my CPU usage?"), .cpu)
    }

    func testMemoryCategory() {
        XCTAssertEqual(QuestionAnalyzer.categorize("Check RAM status"), .memory)
    }

    func testStorageCategory() {
        XCTAssertEqual(QuestionAnalyzer.categorize("Is my disk full?"), .storage)
    }

    func testNetworkCategory() {
        XCTAssertEqual(QuestionAnalyzer.categorize("Wifi speed test"), .network)
    }

    func testBatteryCategory() {
        XCTAssertEqual(QuestionAnalyzer.categorize("Battery power left"), .battery)
    }

    func testIdentityCategory() {
        XCTAssertEqual(QuestionAnalyzer.categorize("Who are you?"), .identity)
    }

    func testGeneralCategory() {
        XCTAssertEqual(QuestionAnalyzer.categorize("Tell me something"), .general)
    }
}
