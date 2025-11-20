//
//  Color.swift
//  Paicord
//
//  Created by Lakhan Lothiyi on 20/11/2025.
//  Copyright © 2025 Lakhan Lothiyi.
//

import SwiftUIX

extension AppKitOrUIKitColor {
  var components: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
    #if os(macOS)
      var r: CGFloat = 0
      var g: CGFloat = 0
      var b: CGFloat = 0
      var a: CGFloat = 0
      self.usingColorSpace(.deviceRGB)?.getRed(&r, green: &g, blue: &b, alpha: &a)
      return (r, g, b, a)
    #else
      var r: CGFloat = 0
      var g: CGFloat = 0
      var b: CGFloat = 0
      var a: CGFloat = 0
      self.getRed(&r, green: &g, blue: &b, alpha: &a)
      return (r, g, b, a)
    #endif
  }
}

extension Color {
  func relativeLuminance() -> CGFloat {
    let uiColor = AppKitOrUIKitColor(self)
    let (r, g, b, _) = uiColor.components

    func toLinear(_ c: CGFloat) -> CGFloat {
      return (c <= 0.04045)
        ? c / 12.92
        : pow((c + 0.055) / 1.055, 2.4)
    }

    let R = toLinear(r)
    let G = toLinear(g)
    let B = toLinear(b)

    return 0.2126 * R + 0.7152 * G + 0.0722 * B
  }

  /// Suggests whether `.light` or `.dark` scheme is more readable
  func suggestedColorScheme() -> ColorScheme {
    let L = relativeLuminance()
    return L > 0.5 ? .light : .dark
  }
}
