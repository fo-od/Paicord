//
//  PaicordCommands.swift
//  Paicord
//
//  Created by Lakhan Lothiyi on 18/09/2025.
//  Copyright © 2025 Lakhan Lothiyi.
//

import SwiftUI

// TODO: Make more account related commands etc

struct PaicordCommands: Commands {
  @Environment(\.gateway) var gatewayStore
  @Environment(\.appState) var appState

  var body: some Commands {
    CommandMenu("Account") {
      Button("Log Out") {
        Task {
          if let current = gatewayStore.accounts.currentAccount {
            gatewayStore.accounts.removeAccount(current)
            await gatewayStore.logOut()
          }
        }
      }
    }
    // add reload button to the system's View menu
    CommandGroup(after: .toolbar) {
      Button("Reload") {
        Task {
          await gatewayStore.disconnectIfNeeded()
          gatewayStore.resetStores()
          PaicordAppState.instances.values.forEach { $0.resetStore() }
          await gatewayStore.connectIfNeeded()
        }
      }
      .keyboardShortcut("r", modifiers: [.command, .shift])
      .disabled(gatewayStore.state != .connected)
    }
  }
}
