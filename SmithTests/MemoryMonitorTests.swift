import XCTest
@testable import Smith

final class MemoryMonitorTests: XCTestCase {
    func testFormatBytesGB() {
        let monitor = MemoryMonitor()
        let result = monitor.formatBytes(1_073_741_824)
        XCTAssertEqual(result, "1 GB")
    }

    func testFormatBytesMB() {
        let monitor = MemoryMonitor()
        let result = monitor.formatBytes(104_857_600)
        XCTAssertEqual(result, "100 MB")
    }
}
