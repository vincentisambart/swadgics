// Partial implementation of ImageMagick gravity and geometry concepts.

import ArgumentParser
import CoreGraphics

enum Gravity: String, ExpressibleByArgument {
    case northWest = "NorthWest"
    case north = "North"
    case northEast = "NorthEast"
    case west = "West"
    case center = "Center"
    case east = "East"
    case southWest = "SouthWest"
    case south = "South"
    case southEast = "SouthEast"

    func objectCenter(objectSize: CGSize, canvasSize: CGSize, geometry: Geometry?) -> CGPoint {
        var centerX, centerY: CGFloat
        switch self {
        case .northWest, .west, .southWest:
            centerX = 0
        case .north, .center, .south:
            centerX = canvasSize.width / 2
        case .northEast, .east, .southEast:
            centerX = canvasSize.width
        }
        switch self {
        case .southWest, .south, .southEast:
            centerY = 0
        case .west, .center, .east:
            centerY = canvasSize.height / 2
        case .northWest, .north, .northEast:
            centerY = canvasSize.height
        }

        if let geometry {
            switch geometry.x {
            case .pixels(let x):
                centerX += x
            case .percent(let x):
                centerX += canvasSize.width * x / 100
            }
            // Geometry's `y` is inverted compared to Core Graphics
            switch geometry.y {
            case .pixels(let y):
                centerY += -y
            case .percent(let y):
                centerY += canvasSize.width * -y / 100
            }
        }

        let halfObjectSize = CGSize(
            width: objectSize.width / 2,
            height: objectSize.height / 2
        )

        if objectSize.width <= canvasSize.width {
            if centerX - halfObjectSize.width < 0 {
                centerX = halfObjectSize.width
            } else if centerX + halfObjectSize.width > canvasSize.width {
                centerX = canvasSize.width - halfObjectSize.width
            }
        } else {
            switch self {
            case .northWest, .west, .southWest:
                centerX = halfObjectSize.width
            case .north, .center, .south:
                centerX = canvasSize.width / 2
            case .northEast, .east, .southEast:
                centerX = canvasSize.width - halfObjectSize.width
            }
        }

        if objectSize.height <= canvasSize.height {
            if centerY - halfObjectSize.height < 0 {
                centerY = halfObjectSize.height
            } else if centerY + halfObjectSize.height > canvasSize.height {
                centerY = canvasSize.height - halfObjectSize.height
            }
        } else {
            switch self {
            case .southWest, .south, .southEast:
                centerY = halfObjectSize.height
            case .west, .center, .east:
                centerY = canvasSize.height / 2
            case .northWest, .north, .northEast:
                centerY = canvasSize.height - halfObjectSize.height
            }
        }
        return CGPoint(x: centerX, y: centerY)
    }
}

struct Geometry: ExpressibleByArgument {
    var x: Offset
    var y: Offset

    enum Offset {
        case pixels(CGFloat)
        case percent(CGFloat)
    }

    private static let geometryRegex = try! Regex(#"([+\-]\d+)(%?)([+\-]\d+)(%?)"#, as: (Substring, Substring, Substring, Substring, Substring).self)

    init?(argument: String) {
        guard let match = try! Self.geometryRegex.wholeMatch(in: argument) else { return nil }
        let (_, x, percentX, y, percentY) = match.output
        if percentX.isEmpty {
            self.x = .pixels(Double(x)!)
        } else {
            self.x = .percent(Double(x)!)
        }
        if percentY.isEmpty {
            self.y = .pixels(Double(y)!)
        } else {
            self.y = .percent(Double(y)!)
        }
    }
}
