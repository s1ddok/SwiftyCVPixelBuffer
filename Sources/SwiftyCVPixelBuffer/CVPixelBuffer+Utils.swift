import CoreVideo.CVPixelBuffer

public extension CVPixelBuffer {

    // MARK: - Type Definitions

    enum Error: Swift.Error {
        case missingPlaneData
        case pixelBufferCreationFailed
        case allocationFailed
        case missingData
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
    /// https://stackoverflow.com/a/58647596/3940420
    func makeCopy() throws -> CVPixelBuffer {
        precondition(CFGetTypeID(self) == CVPixelBufferGetTypeID(), "copy() cannot be called on a non-CVPixelBuffer")

        var _copy: CVPixelBuffer?

        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        let formatType = CVPixelBufferGetPixelFormatType(self)
        let attachments = CVBufferGetAttachments(self, .shouldPropagate)

        CVPixelBufferCreate(nil, width, height, formatType, attachments, &_copy)

        guard let copy = _copy else { throw Error.allocationFailed }

        CVPixelBufferLockBaseAddress(self, .readOnly)
        CVPixelBufferLockBaseAddress(copy, [])

        defer {
            CVPixelBufferUnlockBaseAddress(copy, [])
            CVPixelBufferUnlockBaseAddress(self, .readOnly)
        }

        let pixelBufferPlaneCount: Int = CVPixelBufferGetPlaneCount(self)


        if pixelBufferPlaneCount == 0 {
            let dest = copy.baseAddress
            let source = self.baseAddress
            let height = self.height
            let bytesPerRowSrc = self.bytesPerRow
            let bytesPerRowDest = copy.bytesPerRow
            if bytesPerRowSrc == bytesPerRowDest {
                memcpy(dest, source, height * bytesPerRowSrc)
            } else {
                var startOfRowSrc = source
                var startOfRowDest = dest
                for _ in 0..<height {
                    memcpy(startOfRowDest, startOfRowSrc, min(bytesPerRowSrc, bytesPerRowDest))
                    startOfRowSrc = startOfRowSrc?.advanced(by: bytesPerRowSrc)
                    startOfRowDest = startOfRowDest?.advanced(by: bytesPerRowDest)
                }
            }

        } else {
            for plane in 0 ..< pixelBufferPlaneCount {
                let dest = CVPixelBufferGetBaseAddressOfPlane(copy, plane)
                let source = CVPixelBufferGetBaseAddressOfPlane(self, plane)
                let height = CVPixelBufferGetHeightOfPlane(self, plane)
                let bytesPerRowSrc = CVPixelBufferGetBytesPerRowOfPlane(self, plane)
                let bytesPerRowDest = CVPixelBufferGetBytesPerRowOfPlane(copy, plane)

                if bytesPerRowSrc == bytesPerRowDest {
                    memcpy(dest, source, height * bytesPerRowSrc)
                } else {
                    var startOfRowSrc = source
                    var startOfRowDest = dest
                    for _ in 0 ..< height {
                        memcpy(startOfRowDest, startOfRowSrc, min(bytesPerRowSrc, bytesPerRowDest))
                        startOfRowSrc = startOfRowSrc?.advanced(by: bytesPerRowSrc)
                        startOfRowDest = startOfRowDest?.advanced(by: bytesPerRowDest)
                    }
                }
            }
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
    
    func data() -> Data? {
        guard let source = self.baseAddress else { return nil }
        let height = self.height
        let bytesPerRow = self.bytesPerRow
        return .init(bytes: source, count: height * bytesPerRow)
    }
}
