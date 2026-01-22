//
//  main.swift
//  PaicordLib
//
// Created by Lakhan Lothiyi on 04/09/2025.
// Copyright © 2025 Lakhan Lothiyi.
//

import PaicordLib
import Foundation
import Logging

@main
struct Test {
  static func main() async {
//    DiscordGlobalConfiguration.makeLogger = { label in
//      let stdoutHandler = StreamLogHandler.standardOutput(label: label)
//      var logger = Logger(label: label, factory: { _ in stdoutHandler })
//      logger.logLevel = .debug
//      return logger
//    }
    do {
      let manager = RemoteAuthGatewayManager()
        await manager.connect()
      for await event in await manager.events {
        switch event.op {
        case .pending_remote_init:
          // show qr code using fingerprint
          guard let fingerprint = event.fingerprint else { break }
          let url = URL(string: "https://discord.com/ra/\(fingerprint)")!
          print(url)
        case .pending_ticket:
          // ticket pending, awaiting user confirmation from remote device for auth.
          // we received encrypted user data which we can use to show a preview of the account
          print(event.user_payload)
        case .pending_login:
          // login pending, user confirmed on remote device, need to send ticket
          // exchanging it for token.
          guard let ticket = event.ticket else { break }
          let token = try await manager.exchange(ticket: ticket)
          print(token)
          await manager.disconnect()
          exit(0)
        case .cancel:
          print("Remote auth cancelled")
        default:
          break
        }
      }
    } catch {
      print("RemoteAuthGatewayManager test failed with error: \(error)")
      exit(1)
    }
  }
}
