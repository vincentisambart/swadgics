import CoreText

extension CTFont {
    var ascent: CGFloat { CTFontGetAscent(self) }
    var descent: CGFloat { CTFontGetDescent(self) }
}
