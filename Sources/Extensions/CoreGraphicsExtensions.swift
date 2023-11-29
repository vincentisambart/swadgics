import CoreGraphics

extension CGColorSpace {
    // Unfortunately, `sRGB` is already taken for the name of the sRGB color space.
    static let sRGBColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    // `ColorSpace` suffix for uniformity.
    static let grayscaleColorSpace = CGColorSpaceCreateDeviceGray()
}

extension CGColor {
    /// sRGB color from 3 0-255 8-bit values (plus an optional alpha).
    static func sRGB8(_ red: UInt8, _ green: UInt8, _ blue: UInt8, alpha: CGFloat = 1.0) -> CGColor {
        CGColor(srgbRed: CGFloat(red) / 0xff, green: CGFloat(green) / 0xff, blue: CGFloat(blue) / 0xff, alpha: alpha)
    }
}

extension CGImage {
    var hasAlpha: Bool {
        switch alphaInfo {
        case .none, .noneSkipLast, .noneSkipFirst:
            return false
        default:
            return true
        }
    }
}

extension CGContext {
    static func makeGrayscaleContext(size: CGSize) -> CGContext {
        CGContext(
            data: nil,
            width: Int(size.width.rounded(.up)),
            height: Int(size.height.rounded(.up)),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace.grayscaleColorSpace,
            // `CGImageAlphaInfo` is part of `CGBitmapInfo`.
            // Unfortunately, the grayscale color space only seems to support no alpha or alpha only.
            // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_context/dq_context.html#//apple_ref/doc/uid/TP30001066-CH203-BCIBHHBB
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )!
    }

    static func makeSRBGContext(size: CGSize) -> CGContext {
        CGContext(
            data: nil,
            width: Int(size.width.rounded(.up)),
            height: Int(size.height.rounded(.up)),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace.sRGBColorSpace,
            // `CGImageAlphaInfo` is part of `CGBitmapInfo`.
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
    }

    /// Add a rounded rect to the current path of the context.
    func addRoundedRect(_ rect: CGRect, radius: CGFloat) {
        move(to: CGPoint(x: rect.minX, y: rect.midY))
        addArc(
            tangent1End: CGPoint(x: rect.minX, y: rect.minY),
            tangent2End: CGPoint(x: rect.midX, y: rect.minY),
            radius: radius
        )
        addArc(
            tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
            tangent2End: CGPoint(x: rect.maxX, y: rect.midY),
            radius: radius
        )
        addArc(
            tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
            tangent2End: CGPoint(x: rect.midX, y: rect.maxY),
            radius: radius
        )
        addArc(
            tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
            tangent2End: CGPoint(x: rect.minX, y: rect.midY),
            radius: radius
        )
        closePath()
    }
}
