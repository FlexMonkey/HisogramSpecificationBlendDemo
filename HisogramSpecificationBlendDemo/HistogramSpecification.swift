//
//  HistogramSpecification.swift
//  HisogramSpecificationBlendDemo
//
//  Created by Simon Gladman on 09/05/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//

import CoreImage
import Accelerate.vImage

extension CIImage
{
    convenience init?(fromvImageBuffer: vImage_Buffer)
    {
        var mutableBuffer = fromvImageBuffer
        var error = vImage_Error()
        
        let cgImage = vImageCreateCGImageFromBuffer(
            &mutableBuffer,
            &format,
            nil,
            nil,
            UInt32(kvImageNoFlags),
            &error)
        
        self.init(CGImage: cgImage.takeRetainedValue())
    }
}


var format = vImage_CGImageFormat(
    bitsPerComponent: 8,
    bitsPerPixel: 32,
    colorSpace: nil,
    bitmapInfo: CGBitmapInfo(
        rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue),
    version: 0,
    decode: nil,
    renderingIntent: .RenderingIntentDefault)

func vImageBufferFromCIImage(ciImage: CIImage, ciContext: CIContext) -> vImage_Buffer
{
    let imageRef = ciContext.createCGImage(
        ciImage,
        fromRect: ciImage.extent)
    
    var buffer = vImage_Buffer()
    
    vImageBuffer_InitWithCGImage(
        &buffer,
        &format,
        nil,
        imageRef,
        UInt32(kvImageNoFlags))
    
    return buffer
}

class HistogramSpecification: CIFilter
{
    var inputImage: CIImage?
    var inputHistogramSource: CIImage?
    
    override var attributes: [String : AnyObject]
    {
        return [
            kCIAttributeFilterDisplayName: "Histogram Specification",
            "inputImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage],
            "inputHistogramSource": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Histogram Source",
                kCIAttributeType: kCIAttributeTypeImage],
        ]
    }
    
    lazy var ciContext: CIContext =
        {
            return CIContext()
    }()
    
    override var outputImage: CIImage?
    {
        guard let inputImage = inputImage,
            inputHistogramSource = inputHistogramSource else
        {
            return nil
        }
        
        let imageRef = ciContext.createCGImage(
            inputImage,
            fromRect: inputImage.extent)
        
        var imageBuffer = vImageBufferFromCIImage(inputImage, ciContext: ciContext)
        var histogramSourceBuffer = vImageBufferFromCIImage(inputHistogramSource, ciContext: ciContext)
        
        let alpha = [UInt](count: 256, repeatedValue: 0)
        let red = [UInt](count: 256, repeatedValue: 0)
        let green = [UInt](count: 256, repeatedValue: 0)
        let blue = [UInt](count: 256, repeatedValue: 0)
        
        let alphaMutablePointer = UnsafeMutablePointer<vImagePixelCount>(alpha)
        let redMutablePointer = UnsafeMutablePointer<vImagePixelCount>(red)
        let greenMutablePointer = UnsafeMutablePointer<vImagePixelCount>(green)
        let blueMutablePointer = UnsafeMutablePointer<vImagePixelCount>(blue)
        
        let rgba = [redMutablePointer, greenMutablePointer, blueMutablePointer, alphaMutablePointer]
        
        let histogram = UnsafeMutablePointer<UnsafeMutablePointer<vImagePixelCount>>(rgba)
        
        vImageHistogramCalculation_ARGB8888(&histogramSourceBuffer, histogram, UInt32(kvImageNoFlags))
        
        let pixelBuffer = malloc(CGImageGetBytesPerRow(imageRef) * CGImageGetHeight(imageRef))
        
        var outBuffer = vImage_Buffer(
            data: pixelBuffer,
            height: UInt(CGImageGetHeight(imageRef)),
            width: UInt(CGImageGetWidth(imageRef)),
            rowBytes: CGImageGetBytesPerRow(imageRef))
        
        let alphaPointer = UnsafePointer<vImagePixelCount>(alpha)
        let redPointer = UnsafePointer<vImagePixelCount>(red)
        let greenPointer = UnsafePointer<vImagePixelCount>(green)
        let bluePointer = UnsafePointer<vImagePixelCount>(blue)
        
        let rgbaMutablePointer = UnsafeMutablePointer<UnsafePointer<vImagePixelCount>>([redPointer, greenPointer, bluePointer, alphaPointer])
        
        vImageHistogramSpecification_ARGB8888(&imageBuffer, &outBuffer, rgbaMutablePointer, UInt32(kvImageNoFlags))
        
        let outImage = CIImage(fromvImageBuffer: outBuffer)
        
        free(imageBuffer.data)
        free(histogramSourceBuffer.data)
        free(pixelBuffer)
        
        return outImage!
    }
}