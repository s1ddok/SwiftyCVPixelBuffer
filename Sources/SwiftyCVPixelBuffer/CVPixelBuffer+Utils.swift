import CoreVideo.CVPixelBuffer

public extension CVPixelBuffer {

    // MARK: - Type Definitions

    enum Error: Swift.Error {
        case missingPlaneData
        case pixelBufferCreationFailed
    }
    
    // MARK: - Properties
    
    var width: Int { CVPixelBufferGetWidth(self) }
    var height: Int { CVPixelBufferGetHeight(self) }
    var isPlanar: Bool { CVPixelBufferIsPlanar(self) }
    var planeCount: Int { CVPixelBufferGetPlaneCount(self) }
    var pixelFormat: OSType { CVPixelBufferGetPixelFormatType(self) }
    var baseAddress: UnsafeMutableRawPointer? { CVPixelBufferGetBaseAddress(self) }
    var bytesPerRow: Int { CVPixelBufferGetBytesPerRow(self) }

    // MARK: - Functions

    func width(of plane: Int) -> Int {
        return CVPixelBufferGetWidthOfPlane(self, plane)
    }

    func height(of plane: Int) -> Int {
        return CVPixelBufferGetHeightOfPlane(self, plane)
    }
    
    func attachments(mode: CVAttachmentMode) -> CFDictionary? {
        return CVBufferGetAttachments(self, mode)
    }
    
    func baseAddress(of plane: Int) -> UnsafeMutableRawPointer? {
        return CVPixelBufferGetBaseAddressOfPlane(self, plane)
    }
    
    func lockBaseAddress(options: CVPixelBufferLockFlags) {
        CVPixelBufferLockBaseAddress(self, options)
    }
    
    func unlockBaseAddress(options: CVPixelBufferLockFlags) {
        CVPixelBufferUnlockBaseAddress(self, options)
    }
    
    func bytesPerRow(of plane: Int) -> Int {
        return CVPixelBufferGetBytesPerRowOfPlane(self, plane)
    }

    static func create(width: Int,
                       height: Int,
                       pixelFormat: OSType = kCVPixelFormatType_32BGRA,
                       attachments: CFDictionary? = nil) throws -> CVPixelBuffer {
        var optionalPixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(nil,
                            width,
                            height,
                            pixelFormat,
                            attachments,
                            &optionalPixelBuffer)
        guard let pixelBuffer = optionalPixelBuffer
        else { throw Error.pixelBufferCreationFailed }
        return pixelBuffer
    }
    
    func allocateBlankCopy() throws -> CVPixelBuffer {
        precondition(CFGetTypeID(self) == CVPixelBuffer.typeID,
                     "copy() cannot be called on a non-CVPixelBuffer")
        return try Self.create(width: self.width,
                               height: self.height,
                               pixelFormat: self.pixelFormat,
                               attachments: self.attachments(mode: .shouldPropagate))
    }
    
    /// Deep copy a CVPixelBuffer:
    /// http://stackoverflow.com/questions/38335365/pulling-data-from-a-cmsamplebuffer-in-order-to-create-a-deep-copy
    func makeCopy() throws -> CVPixelBuffer {
        let copy = try self.allocateBlankCopy()
        
        self.lockBaseAddress(options: .readOnly)
        copy.lockBaseAddress(options: [])
        defer {
            copy.unlockBaseAddress(options: [])
            self.unlockBaseAddress(options: .readOnly)
        }
        
        // TODO: Handle non-planar pixel buffers
        for plane in 0 ..< self.planeCount {
            let dest = copy.baseAddress(of: plane)
            let source = self.baseAddress(of: plane)
            let height = self.height(of: plane)
            let bytesPerRow = self.bytesPerRow(of: plane)
            memcpy(dest, source, height * bytesPerRow)
        }
        
        return copy
    }

    func fillExtendedPixels() -> CVReturn {
        return CVPixelBufferFillExtendedPixels(self)
    }

    func extendedPixels() -> (left: Int, right: Int, top: Int, bottom: Int) {
        var eLeft: Int = 0, eRight: Int = 0, eTop: Int = 0, eBottom: Int = 0
        CVPixelBufferGetExtendedPixels(self, &eLeft, &eRight, &eTop, &eBottom)
        return (eLeft, eRight, eTop, eBottom)
    }

    static var typeID: CFTypeID { CVPixelBufferGetTypeID() }
}

extension CVPixelBuffer {
    func data(of plane: Int) -> Data? {
        guard let source = self.baseAddress(of: plane)
        else { return nil }
        let height = self.height(of: plane)
        let bytesPerRow = self.bytesPerRow(of: plane)
        return .init(bytes: source,
                     count: height * bytesPerRow)
    }
}
