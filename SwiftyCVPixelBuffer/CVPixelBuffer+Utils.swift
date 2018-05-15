//
//  CVPixelBuffer+Utils.swift
//  SwiftyCVPixelBuffer
//
//  Created by Andrey Volodin on 14.02.2018.
//  Copyright © 2018 Andrey Volodin. All rights reserved.
//

import CoreVideo.CVPixelBuffer

public extension CVPixelBuffer {
    
    // MARK: Properties
    
    var width: Int {
        return CVPixelBufferGetWidth(self)
    }
    
    var height: Int {
        return CVPixelBufferGetHeight(self)
    }
    
    func width(of plane: Int) -> Int {
        return CVPixelBufferGetWidthOfPlane(self, plane)
    }
    
    func height(of plane: Int) -> Int {
        return CVPixelBufferGetHeightOfPlane(self, plane)
    }
    
    var isPlanar: Bool {
        return CVPixelBufferIsPlanar(self)
    }
    
    var planeCount: Int {
        return CVPixelBufferGetPlaneCount(self)
    }
    
    var pixelFormat: OSType {
        return CVPixelBufferGetPixelFormatType(self)
    }
    
    func attachments(mode: CVAttachmentMode) -> CFDictionary? {
        return CVBufferGetAttachments(self, mode)
    }
    
    // MARK: Memory
    
    var baseAddress: UnsafeMutableRawPointer? {
        return CVPixelBufferGetBaseAddress(self)
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
    
    var bytesPerRow: Int {
        return CVPixelBufferGetBytesPerRow(self)
    }
    
    func bytesPerRow(of plane: Int) -> Int {
        return CVPixelBufferGetBytesPerRowOfPlane(self, plane)
    }
    
    // MARK: Creation
    
    static func create(width: Int, height: Int, pixelFormat: OSType = kCVPixelFormatType_32BGRA, attachments: CFDictionary? = nil) -> CVPixelBuffer? {
        var pb: CVPixelBuffer?
        
        CVPixelBufferCreate(
            nil,
            width, height,
            pixelFormat,
            attachments,
            &pb)
        
        return pb
    }
    
    func allocateBlankCopy() -> CVPixelBuffer? {
        precondition(CFGetTypeID(self) == CVPixelBuffer.typeID, "copy() cannot be called on a non-CVPixelBuffer")
        
        return CVPixelBuffer.create(width: self.width,
                                    height: self.height,
                                    pixelFormat: self.pixelFormat,
                                    attachments: self.attachments(mode: .shouldPropagate))
    }
    
    /// Deep copy a CVPixelBuffer:
    /// http://stackoverflow.com/questions/38335365/pulling-data-from-a-cmsamplebuffer-in-order-to-create-a-deep-copy
    func makeCopy() -> CVPixelBuffer? {
        guard let copy = self.allocateBlankCopy() else {
            return nil
        }
        
        self.lockBaseAddress(options: .readOnly)
        copy.lockBaseAddress(options: [])
        defer {
            copy.unlockBaseAddress(options: [])
            self.unlockBaseAddress(options: .readOnly)
        }
        
        // TODO: Handle non-planar pixel buffers
        for plane in 0..<self.planeCount {
            let dest        = copy.baseAddress(of: plane)
            let source      = self.baseAddress(of: plane)
            let height      = self.height(of: plane)
            let bytesPerRow = self.bytesPerRow(of: plane)
            
            memcpy(dest, source, height * bytesPerRow)
        }
        
        return copy
    }
    
    // MARK: Meta
    static var typeID: CFTypeID {
        return CVPixelBufferGetTypeID()
    }
    
    func fillExtendedPixels() -> CVReturn {
        return CVPixelBufferFillExtendedPixels(self)
    }
    
    func extendedPixels() -> (left: Int, right: Int, top: Int, bottom: Int) {
        var eLeft: Int = 0, eRight: Int = 0, eTop: Int = 0, eBottom: Int = 0
        CVPixelBufferGetExtendedPixels(self, &eLeft, &eRight, &eTop, &eBottom)
        
        return (eLeft, eRight, eTop, eBottom)
        
    }
}

extension CVPixelBuffer {
    func data(of plane: Int) -> Data? {
        guard let source      = self.baseAddress(of: plane) else {
            return nil
        }
        let height      = self.height(of: plane)
        let bytesPerRow = self.bytesPerRow(of: plane)
        
        let data = Data(bytes: source, count: height * bytesPerRow)
        return data
    }
}
