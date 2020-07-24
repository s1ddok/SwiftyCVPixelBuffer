import XCTest
@testable import SwiftyCVPixelBuffer

final class SwiftyCVPixelBufferTests: XCTestCase {
    func testCodableRoundTrip() throws {
        let pixelBuffer = try CVPixelBuffer.create(width: 512,
                                                   height: 512)
        let data = try JSONEncoder().encode(pixelBuffer.codableBox)
        let decodedBox = try JSONDecoder().decode(CVPixelBufferCodableBox.self,
                                                  from: data)
        dump(decodedBox.buffer)
    }

    static var allTests = [
        ("testCodableRoundTrip", testCodableRoundTrip),
    ]
}
