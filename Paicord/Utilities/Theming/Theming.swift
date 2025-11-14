//
//  Theming.swift
//  Paicord
//
//  Created by Lakhan Lothiyi on 13/11/2025.
//  Copyright © 2025 Lakhan Lothiyi.
//

import Playgrounds
import SwiftUIX

@Observable
class Theming {
  static let shared = Theming()
  
  var themes: [Theme] {
    Theming.defaultThemes + loadedThemes
  }
    
  var loadedThemes: [Theme] {
    didSet {
      save()
    }
  }
  
  @ObservationIgnored
  @AppStorage("Paicord.Theming.CurrentThemeID")
  var currentThemeID: String = "Paicord.Auto"
  
  var currentTheme: Theme {
    themes.first(where: { $0.id == currentThemeID }) ?? Theming.defaultThemes[0]
  }

  private init() {
    self.loadedThemes = []
    load()
    setupAppearance()
  }

  func setupAppearance() {
    #if canImport(UIKit)
    NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { _ in
      // update appearance
      UIApplication.shared.windows.forEach { window in
        // set accent color
        window.tintColor = AppKitOrUIKitColor(self.currentTheme.common.accentColor)
      }
    }
    #endif
  }
  
  func save() {
    // save to file ~/Library/Preferences/themes.json
    let data = try? JSONEncoder().encode(loadedThemes)
    let url = URL.libraryDirectory.appendingPathComponent("Preferences/themes.json")
    try? data?.write(to: url, options: .atomic)
  }
  
  func load() {
    let url = URL.libraryDirectory.appendingPathComponent("Preferences/themes.json")
    guard let data = try? Data(contentsOf: url) else { return }
    guard let themes = try? JSONDecoder().decode([Theme].self, from: data) else { return }
    self.loadedThemes = themes
  }
}

extension Theming {
  struct Theme: Sendable, Codable, Hashable, Equatable, Identifiable {
    let id: String
    let metadata: ThemeMetadata

    let common: ThemeCommon

    struct ThemeMetadata: Sendable, Codable, Hashable, Equatable {
      let name: String
      let author: String
      let description: String
      let version: String
    }

    struct ThemeCommon: Sendable, Codable, Hashable, Equatable {
      // common theme properties
      let accentColor: Color
    }
  }
}

extension Theming {
  static let defaultThemes: [Theme] = [
    .init(
      id: "Paicord.Auto",
      metadata: .init(
        name: "Auto",
        author: "Paicord",
        description: "Changes according to system color scheme.",
        version: "1.0"
      ),
      common: .init(accentColor: .accent)
    ),
    .init(
      id: "Paicord.Light",
      metadata: .init(
        name: "Light",
        author: "Paicord",
        description: "Permanent light theme.",
        version: "1.0"
      ),
      common: .init(accentColor: .accent)
    ),
    .init(
      id: "Paicord.Dark",
      metadata: .init(
        name: "Dark",
        author: "Paicord",
        description: "Permanent dark theme.",
        version: "1.0"
      ),
      common: .init(accentColor: .accent)
    ),
  ]
}

extension Theming {
  enum Styling: Sendable, Codable, Hashable, Equatable {
    case color(Color)
    case gradient(Gradient, GradientType)
    case image(PlatformImageRepresentation, Set<ImageScaling>)

    enum GradientType: String, Sendable, Codable, Hashable, Equatable {
      case linear
      case radial
      case angular
    }
    
    struct ImageScaling: Sendable, OptionSet, Codable, Hashable, Equatable {
      let rawValue: Int

      // allows image to be resized
      static let resizable = ImageScaling(rawValue: 1 << 0)
      // scales the image to completely fill the container, image may be stretched or cropped (depends on if resizable is set)
      static let fill = ImageScaling(rawValue: 1 << 1)
      // scales the image to fit within the container, image may be stretched (depends on if resizable is set)
      static let fit = ImageScaling(rawValue: 1 << 2)
      // tiles the image to fill the container, image scale is not changed
      static let tile = ImageScaling(rawValue: 1 << 3)

      // below options require 'tile' to be set

      // width of image fits container, tiles to fill height
      static let tilingFitWidth = [Self.tile, ImageScaling(rawValue: 1 << 4)]
      // height of image fits container, tiles to fill width
      static let tilingFitHeight = [
        Self.tile, ImageScaling(rawValue: 1 << 5),
      ]
    }
  }
}

#Playground {
  let theme = Theming.Theme.init(
    id: "com.llsc12.ugly",
    metadata: .init(
      name: "Ugly Theme",
      author: "llsc12",
      description: "Ugly ass theme for testing.",
      version: "1.0"
    ),
    common: .init(
      accentColor: .init(
        light: Color(hexadecimal6: 0xffffff).opacity(0.5),
        dark: .init(hexadecimal6: 0x0)
      )
    )
  )

  let data1 = try! JSONEncoder().encode(theme)
  let json = try! JSONSerialization.jsonObject(with: data1)
  let data2 = try! JSONSerialization.data(
    withJSONObject: json,
    options: .prettyPrinted
  )
  let string = String(data: data2, encoding: .utf8)
}
