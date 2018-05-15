//
//  CVPixelBuffer+Codable.swift
//  ARParty
//
//  Created by Andrey Volodin on 05.05.2018.
//  Copyright © 2018 s1ddok. All rights reserved.
//

import CoreVideo.CVPixelBuffer

public protocol CustomDecodable {
    associatedtype T
    static func decode(with decoder: Decoder) -> T?
}

struct GenericCodingKeys: CodingKey {
    var intValue: Int?
    var stringValue: String
    
    init?(intValue: Int) { self.intValue = intValue; self.stringValue = "\(intValue)" }
    init?(stringValue: String) { self.stringValue = stringValue }
    
    static func makeKey(name: String) -> GenericCodingKeys {
        return GenericCodingKeys(stringValue: name)!
    }
}

extension GenericCodingKeys {
    static func planeDataKey(index: Int) -> GenericCodingKeys {
        return GenericCodingKeys(stringValue: "planeData\(index)")!
    }
    
    static func planeBytesPerRowKey(index: Int) -> GenericCodingKeys {
        return GenericCodingKeys(stringValue: "planeBytesPerRow\(index)")!
    }
    
    static func planeHeightKey(index: Int) -> GenericCodingKeys {
        return GenericCodingKeys(stringValue: "planeHeight\(index)")!
    }
}

// NOTE: Attachments are not supported for now
extension CVPixelBuffer: Encodable, CustomDecodable {
    public typealias T = CVPixelBuffer
    
    enum CodingKeys: String, CodingKey {
        case planeCount
        case pixelFormat
        case width
        case height
        case planes
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.planeCount, forKey: .planeCount)
        try container.encode(self.pixelFormat, forKey: .pixelFormat)
        try container.encode(self.width, forKey: .width)
        try container.encode(self.height, forKey: .height)
        
        self.lockBaseAddress(options: .readOnly)
        defer {
            self.unlockBaseAddress(options: .readOnly)
        }
        
        var nestedContainer = container.nestedContainer(keyedBy: GenericCodingKeys.self, forKey: .planes)
        for planeIdx in 0..<self.planeCount {
            // Prepare keys
            let planeKey = GenericCodingKeys.planeDataKey(index: planeIdx)
            let planeBytesPerRowKey = GenericCodingKeys.planeBytesPerRowKey(index: planeIdx)
            let planeHeightKey = GenericCodingKeys.planeBytesPerRowKey(index: planeIdx)
            
            // Prepare data
            guard let planeData = self.data(of: planeIdx) else {
                fatalError("Couldn't get plane data")
            }
            let planeBytesPerRow = self.bytesPerRow(of: planeIdx)
            let planeHeight = self.height(of: planeIdx)
            
            // Encode
            try nestedContainer.encode(planeData, forKey: planeKey)
            try nestedContainer.encode(planeBytesPerRow, forKey: planeBytesPerRowKey)
            try nestedContainer.encode(planeHeight, forKey: planeHeightKey)
        }
    }
    
    public static func decode(with decoder: Decoder) -> CVPixelBuffer? {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            let width = try container.decode(Int.self, forKey: .width)
            let height = try container.decode(Int.self, forKey: .height)
            let pixelFormat = try container.decode(OSType.self, forKey: .pixelFormat)
            let planeCount = try container.decode(Int.self, forKey: .planeCount)
        
            guard let pb = CVPixelBuffer.create(width: width,
                                                height: height,
                                                pixelFormat: pixelFormat)
            else {
                return nil
            }
            
            let planesData = try container.nestedContainer(keyedBy: GenericCodingKeys.self, forKey: .planes)
            
            pb.lockBaseAddress(options: [])
            defer {
                pb.unlockBaseAddress(options: [])
            }
            
            for plane in 0..<planeCount {
                let dest = pb.baseAddress(of: plane)
                let source = try planesData.decode(Data.self, forKey: .planeDataKey(index: plane))
                
                source.withUnsafeBytes { pointer -> Void in
                    memcpy(dest, pointer, source.count)
                }
            }
            
            return pb
        } catch {
            return nil
        }
    }
}
