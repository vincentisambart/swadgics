// Partial reimplementation of the shields.io badges using Core Graphics.

import ArgumentParser
import CoreGraphics
import CoreText

struct Shield {
    let content: Content
    let size: CGSize
    private let label: TextLine
    private let message: TextLine?

    private static let horizontalMargin: CGFloat = 5.5
    private static let horizontalSpacing: CGFloat = 7.0
    private static let verticalMargin: CGFloat = 5.0
    private static let roundedRectRadius: CGFloat = 3.0
    private static let font = CTFontCreateWithNameAndOptions("Verdana" as CFString, 11.0, nil, .init())

    init(content: Content) {
        self.content = content

        label = TextLine(text: content.label, font: Self.font)
        message = content.message.map { TextLine(text: $0, font: Self.font) }

        let width: CGFloat
        if let message {
            width = 2 * Self.horizontalMargin + Self.horizontalSpacing + label.width + message.width
        } else {
            width = 2 * Self.horizontalMargin + label.width
        }
        let height = Self.font.ascent + 2 * Self.verticalMargin
        size = CGSize(width: width, height: height)
    }

    func draw(on context: CGContext) {
        context.saveGState()

        context.addRoundedRect(
            CGRect(origin: .zero, size: size),
            radius: Self.roundedRectRadius
        )
        context.clip()

        context.setFillColor(content.labelBackgroundColor.cgColor)
        context.fill([
            CGRect(
                x: 0,
                y: 0,
                width: Self.horizontalMargin + label.width + (content.message == nil ? Self.horizontalMargin : Self.horizontalSpacing / 2),
                height: size.height
            ),
        ])

        if let message {
            context.setFillColor(content.messageBackgroundColor.cgColor)
            context.fill([
                CGRect(
                    x: Self.horizontalMargin + label.width + Self.horizontalSpacing / 2,
                    y: 0,
                    width: Self.horizontalMargin + message.width + Self.horizontalSpacing / 2,
                    height: size.height
                ),
            ])
        }

        let gradient = CGGradient(
            colorsSpace: CGColorSpace.sRGBColorSpace,
            colors: [
                CGColor.sRGB8(0x0, 0x0, 0x0, alpha: 0.1),
                CGColor.sRGB8(0xbb, 0xbb, 0xbb, alpha: 0.1),
            ] as CFArray,
            locations: [0.0, 1.0]
        )!

        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: 0, y: size.height),
            options: []
        )

        context.restoreGState()

        let textY = Self.verticalMargin - label.bounds.origin.y

        context.saveGState()
        context.translateBy(
            x: Self.horizontalMargin,
            y: textY
        )
        // The offset given to `setShadow` is not affected by the transformation matrix's scale, so scale it by hand.
        let ctmScaleY = context.ctm.d
        context.setShadow(offset: CGSize(width: 0, height: -ctmScaleY), blur: 0)
        context.textMatrix = .identity
        label.draw(on: context)
        context.restoreGState()

        if let message {
            context.saveGState()
            context.translateBy(
                x: Self.horizontalMargin + Self.horizontalSpacing + label.width,
                y: textY
            )
            context.setShadow(offset: CGSize(width: 0, height: -ctmScaleY), blur: 0)
            context.textMatrix = .identity
            message.draw(on: context)
            context.restoreGState()
        }
    }

    enum Color {
        case namedColor(NamedColor)

        var cgColor: CGColor {
            switch self {
            case .namedColor(let namedColor):
                return namedColor.cgColor
            }
        }
    }

    enum NamedColor {
        case brightGreen
        case green
        case yellow
        case yellowGreen
        case orange
        case red
        case blue
        case grey
        case lightGrey

        var cgColor: CGColor {
            switch self {
            case .brightGreen:
                return .sRGB8(0x44, 0xcc, 0x11)
            case .green:
                return .sRGB8(0x97, 0xca, 0x00)
            case .yellow:
                return .sRGB8(0xdf, 0xb3, 0x17)
            case .yellowGreen:
                return .sRGB8(0xa4, 0xa6, 0x1d)
            case .orange:
                return .sRGB8(0xfe, 0x7d, 0x37)
            case .red:
                return .sRGB8(0xe0, 0x5d, 0x44)
            case .blue:
                return .sRGB8(0x00, 0x7e, 0xc6)
            case .grey:
                return .sRGB8(0x55, 0x55, 0x55)
            case .lightGrey:
                return .sRGB8(0x9f, 0x9f, 0x9f)
            }
        }

        fileprivate static let mapping: [String: NamedColor] = [
            "brightgreen": .brightGreen,
            "green": .green,
            "yellow": .yellow,
            "yellowgreen": .yellowGreen,
            "orange": .orange,
            "red": .red,
            "blue": .blue,
            "grey": .grey,
            "lightgrey": .lightGrey,
            // Aliases
            "gray": .grey,
            "lightgray": .lightGrey,
            "critical": .red,
            "important": .orange,
            "success": .brightGreen,
            "informational": .blue,
            "inactive": .lightGrey,
        ]
    }

    struct Content: ExpressibleByArgument {
        var label: String
        var message: String?
        var color: Color

        init?(argument content: String) {
            guard let first = content.first else { return nil }
            var parts: [String] = [""]
            var previous: Character? = first
            for c in content.dropFirst() {
                switch (previous, c) {
                case ("_", "_"):
                    parts[parts.count - 1].append("_")
                    previous = nil
                case ("-", "-"):
                    parts[parts.count - 1].append("-")
                    previous = nil
                case ("-", _):
                    parts.append("")
                    previous = c
                case ("_", _):
                    parts[parts.count - 1].append(" ")
                    previous = c
                default:
                    if let previous {
                        parts[parts.count - 1].append(previous)
                    }
                    previous = c
                }
            }
            if let previous {
                switch previous {
                case "-":
                    return nil
                default:
                    parts[parts.count - 1].append(previous)
                }
            }

            let colorName: String
            switch parts.count {
            case 2:
                label = parts[0]
                colorName = parts[1]
            case 3:
                label = parts[0]
                message = parts[1]
                colorName = parts[2]
            default:
                return nil
            }

            if let namedColor = NamedColor.mapping[colorName.lowercased()] {
                color = .namedColor(namedColor)
            } else {
                return nil
            }
        }

        var labelBackgroundColor: Shield.Color {
            if message == nil {
                color
            } else {
                .namedColor(.grey)
            }
        }

        var messageBackgroundColor: Shield.Color {
            color
        }
    }
}
