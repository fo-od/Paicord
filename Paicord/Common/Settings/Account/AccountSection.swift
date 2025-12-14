//
//  AccountSection.swift
//  Paicord
//
//  Created by Lakhan Lothiyi on 15/11/2025.
//  Copyright © 2025 Lakhan Lothiyi.
//

import SettingsKit

extension SettingsView {
  var accountSection: some SettingsContent {
    SettingsGroup("My Account", systemImage: "person.crop.circle") {
      SettingsItem("Log Out") {
        AsyncButton("") {
          guard let currentAccount = gw.accounts.currentAccount else { return }
          gw.accounts.removeAccount(currentAccount)
          await gw.logOut()
        } catch: { _ in
        }

      }
    }
  }
}
