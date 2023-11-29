// Simple wrapper around Core Text's `CTLine`.

import CoreText

struct TextLine {
    private let font: CTFont
    private let line: CTLine
    let bounds: CGRect

    init(text: String, font: CTFont) {
        self.font = font

        let attributes: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: CGColor.white,
        ]
        let attributedString = CFAttributedStringCreate(nil, text as CFString, attributes as CFDictionary)!
        line = CTLineCreateWithAttributedString(attributedString)
        bounds = CTLineGetBoundsWithOptions(line, .init())
    }

    var height: CGFloat { bounds.maxY } // Same as the font's ascent
    var width: CGFloat { bounds.maxX }

    func draw(on context: CGContext) {
        CTLineDraw(line, context)
    }
}
