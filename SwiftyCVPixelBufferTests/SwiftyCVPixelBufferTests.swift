//
//  SwiftyCVPixelBufferTests.swift
//  SwiftyCVPixelBufferTests
//
//  Created by Andrey Volodin on 15.05.2018.
//  Copyright © 2018 Andrey Volodin. All rights reserved.
//

import XCTest
import CoreVideo
@testable import SwiftyCVPixelBuffer

class SwiftyCVPixelBufferTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCodableRoundTrip() {
        let jsonEncoder = JSONEncoder()
        
        let pb = CVPixelBuffer.create(width: 512, height: 512)
        let pbBox = CVPixelBufferBox(pb!)
        guard let data = try? jsonEncoder.encode(pbBox) else {
            fatalError("Encoding of pixel buffer wasn't successful")
        }
        
        let jsonDecoder = JSONDecoder()
        let decodedBox = try? jsonDecoder.decode(CVPixelBufferBox.self, from: data)
        
        let decodedPb = decodedBox?.buffer
        dump(decodedPb)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
