import CoreVideo.CVPixelBuffer

public protocol CustomEncodable {
    func encode(with encoder: Encoder) throws
}

public protocol CustomDecodable {
    associatedtype T
    static func decode(with decoder: Decoder) throws -> T
}

struct GenericCodingKeys: CodingKey {
    var intValue: Int?
    var stringValue: String
    
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
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

public struct CVPixelBufferCodableBox: Codable {
    public var buffer: CVPixelBuffer?
    
    public init(_ pixelBuffer: CVPixelBuffer) {
        self.buffer = pixelBuffer
    }
    
    public init(from decoder: Decoder) throws {
        self.buffer = try CVPixelBuffer.decode(with: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        try self.buffer?.encode(with: encoder)
    }
}

// NOTE: Attachments are not supported for now
extension CVPixelBuffer: CustomEncodable, CustomDecodable {

    public typealias T = CVPixelBuffer
    
    enum CodingKeys: String, CodingKey {
        case planeCount
        case pixelFormat
        case width
        case height
        case planes
        case isPlanar
        case data
    }

    public var codableBox: CVPixelBufferCodableBox { .init(self) }

    public func encode(with encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.planeCount, forKey: .planeCount)
        try container.encode(self.pixelFormat, forKey: .pixelFormat)
        try container.encode(self.width, forKey: .width)
        try container.encode(self.height, forKey: .height)
        try container.encode(self.isPlanar, forKey: .isPlanar)
        
        self.lockBaseAddress(options: .readOnly)
        defer { self.unlockBaseAddress(options: .readOnly) }
        
        if (isPlanar) {
            var nestedContainer = container.nestedContainer(keyedBy: GenericCodingKeys.self, forKey: .planes)
            for planeIdx in 0 ..< self.planeCount {
                // Prepare keys
                let planeKey = GenericCodingKeys.planeDataKey(index: planeIdx)
                let planeBytesPerRowKey = GenericCodingKeys.planeBytesPerRowKey(index: planeIdx)
                let planeHeightKey = GenericCodingKeys.planeBytesPerRowKey(index: planeIdx)
                
                // Prepare data
                guard let planeData = self.data(of: planeIdx)
                else { throw Error.missingPlaneData }
                let planeBytesPerRow = self.bytesPerRow(of: planeIdx)
                let planeHeight = self.height(of: planeIdx)
                
                // Encode
                try nestedContainer.encode(planeData, forKey: planeKey)
                try nestedContainer.encode(planeBytesPerRow, forKey: planeBytesPerRowKey)
                try nestedContainer.encode(planeHeight, forKey: planeHeightKey)
            }
        } else {
            guard let data = self.data() else { throw Error.missingData }
            try container.encode(data, forKey: .data)
        }
    }
    
    public static func decode(with decoder: Decoder) throws -> CVPixelBuffer {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let width = try container.decode(Int.self, forKey: .width)
        let height = try container.decode(Int.self, forKey: .height)
        let pixelFormat = try container.decode(OSType.self, forKey: .pixelFormat)
        let planeCount = try container.decode(Int.self, forKey: .planeCount)
        let isPlanar = try container.decode(Bool.self, forKey: .isPlanar)
        
        let pixelBuffer = try CVPixelBuffer.create(width: width,
                                                   height: height,
                                                   pixelFormat: pixelFormat)
        
        pixelBuffer.lockBaseAddress(options: [])
        defer { pixelBuffer.unlockBaseAddress(options: []) }

        if isPlanar {
            let planesData = try container.nestedContainer(keyedBy: GenericCodingKeys.self,
                                                           forKey: .planes)
            for plane in 0 ..< planeCount {
                let dest = pixelBuffer.baseAddress(of: plane)
                let source = try planesData.decode(Data.self,
                                                   forKey: .planeDataKey(index: plane))

                _ = source.withUnsafeBytes { pointer in
                    memcpy(dest, pointer.baseAddress!, source.count)
                }
            }
        } else {
            let dest = pixelBuffer.baseAddress
            let source = try container.decode(Data.self, forKey: .data)
            
            _ = source.withUnsafeBytes { pointer in
                memcpy(dest, pointer.baseAddress!, source.count)
            }
        }
        
        return pixelBuffer
    }
}
