//
//  AccessibilitySection.swift
//  Paicord
//
//  Created by Lakhan Lothiyi on 02/12/2025.
//  Copyright © 2025 Lakhan Lothiyi.
//  


import SettingsKit

extension SettingsView {
  var accessibilitySection: some SettingsContent {
    SettingsGroup("Accessibility", systemImage: "accessibility.fill") {
    }
  }
}
