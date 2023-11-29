// Calls the needed processing depending on the arguments given by the user.
// Note that part of the arguments parsing is done in some of the features' implementation using `ExpressibleByArgument`.

import ArgumentParser
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum SwadgicsError: LocalizedError {
    case couldNotRead(_ url: URL)
    case couldNotWrite(_ url: URL)
    case unknownFileFormat(_ url: URL)
    case outputFileOnlyWhenOneInput

    var errorDescription: String? {
        switch self {
        case .couldNotRead(let url):
            return "Could not read file \(url.path)"
        case .couldNotWrite(let url):
            return "Could not write file \(url.path)"
        case .unknownFileFormat(let url):
            return "Format of file \(url.path) unknown"
        case .outputFileOnlyWhenOneInput:
            return "An output file can only be specified when there is only one input file"
        }
    }
}

@main
struct Swadgics: ParsableCommand {
    @Argument var inputFiles: [String]
    @Option var outputFile: String?

    @Flag var grayscale = false

    @Option var shield: Shield.Content?
    @Option var shield_scale: Double?
    @Option var shield_gravity: Gravity = .north
    @Option var shield_geometry: Geometry?

    @Flag var no_badge = false
    @Flag var dark = false
    @Flag var alpha = false
    @Option var custom: String?
    var badge: Badge? = .standard(.beta(.light))

    mutating func run() throws {
        if no_badge {
            badge = nil
        } else if alpha {
            if dark {
                badge = .standard(.alpha(.dark))
            } else {
                badge = .standard(.alpha(.light))
            }
        } else if dark {
            badge = .standard(.beta(.dark))
        } else if let custom {
            badge = .custom(URL(fileURLWithPath: custom))
        }

        if inputFiles.count == 1 {
            let inputURL = URL(fileURLWithPath: inputFiles[0])
            if let outputFile {
                let outputURL = URL(fileURLWithPath: outputFile)
                try process(inputURL: inputURL, outputURL: outputURL)
            } else {
                try process(inputURL: inputURL, outputURL: inputURL)
            }
        } else {
            if outputFile != nil {
                throw SwadgicsError.outputFileOnlyWhenOneInput
            }
            for inputFile in inputFiles {
                let inputURL = URL(fileURLWithPath: inputFile)
                try process(inputURL: inputURL, outputURL: inputURL)
            }
        }
    }

    func process(inputURL: URL, outputURL: URL) throws {
        guard let imageSource = CGImageSourceCreateWithURL(inputURL as CFURL, nil) else {
            throw SwadgicsError.couldNotRead(inputURL)
        }
        guard let sourceImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw SwadgicsError.unknownFileFormat(inputURL)
        }
        let imageSize = CGSize(width: sourceImage.width, height: sourceImage.height)
        let fullImageRect = CGRect(origin: .zero, size: imageSize)

        var image = sourceImage
        if grayscale {
            let grayContext = CGContext.makeGrayscaleContext(size: imageSize)
            // Unfortunately the grayscale context loses alpha.
            grayContext.draw(image, in: fullImageRect)
            let grayImage = grayContext.makeImage()!
            let colorContext = CGContext.makeSRBGContext(size: imageSize)
            colorContext.draw(grayImage, in: fullImageRect)
            // Bring back the alpha from the original image.
            colorContext.setBlendMode(.destinationIn)
            colorContext.draw(image, in: fullImageRect)
            image = colorContext.makeImage()!
        }

        if let shieldContent = shield {
            let shield = Shield(content: shieldContent)
            let shieldScale: CGFloat
            if let shield_scale {
                shieldScale = shield_scale * imageSize.width / shield.size.width
            } else {
                shieldScale = imageSize.width / shield.size.width
            }
            let scaledShieldSize = CGSize(
                width: shield.size.width * shieldScale,
                height: shield.size.height * shieldScale
            )
            let center = shield_gravity.objectCenter(objectSize: scaledShieldSize, canvasSize: imageSize, geometry: shield_geometry)

            let context = CGContext.makeSRBGContext(size: imageSize)
            context.draw(image, in: fullImageRect)

            context.saveGState()
            context.translateBy(
                x: (center.x - (scaledShieldSize.width / 2)).rounded(),
                y: (center.y - (scaledShieldSize.height / 2)).rounded()
            )

            context.scaleBy(x: shieldScale, y: shieldScale)

            shield.draw(on: context)

            context.restoreGState()

            image = context.makeImage()!
        }

        if let badge {
            let badgeImage: CGImage
            switch badge {
            case .standard(let standardBadge):
                let resource: [UInt8]
                switch standardBadge {
                case .beta(.light):
                    resource = PackageResources.beta_badge_light_png
                case .beta(.dark):
                    resource = PackageResources.beta_badge_dark_png
                case .alpha(.light):
                    resource = PackageResources.alpha_badge_light_png
                case .alpha(.dark):
                    resource = PackageResources.alpha_badge_dark_png
                }
                let badgeData = CFDataCreate(nil, &resource, resource.count)!
                let badgeSource = CGImageSourceCreateWithData(badgeData, nil)!
                badgeImage = CGImageSourceCreateImageAtIndex(badgeSource, 0, nil)!

            case .custom(let badgeURL):
                guard let badgeSource = CGImageSourceCreateWithURL(badgeURL as CFURL, nil) else {
                    throw SwadgicsError.couldNotRead(badgeURL)
                }

                guard let image = CGImageSourceCreateImageAtIndex(badgeSource, 0, nil) else {
                    throw SwadgicsError.unknownFileFormat(badgeURL)
                }
                badgeImage = image
            }

            let context = CGContext.makeSRBGContext(size: imageSize)
            context.draw(image, in: fullImageRect)
            context.draw(badgeImage, in: fullImageRect)
            image = context.makeImage()!
        }

        let outputOptions = [kCGImagePropertyHasAlpha: sourceImage.hasAlpha]
        guard let imageDestination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, outputOptions as CFDictionary) else {
            throw SwadgicsError.couldNotWrite(outputURL)
        }
        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)
    }
}

enum BadgeTheme: Decodable {
    case light
    case dark
}

enum StandardBadge: Decodable {
    case alpha(BadgeTheme)
    case beta(BadgeTheme)
}

enum Badge: Decodable {
    case standard(StandardBadge)
    case custom(_ url: URL)
}
