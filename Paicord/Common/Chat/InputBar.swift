//
//  InputBar.swift
//  Paicord
//
//  Created by Lakhan Lothiyi on 17/10/2025.
//  Copyright © 2025 Lakhan Lothiyi.
//  

import SwiftUIX
import PaicordLib

struct InputBar: View {
  @Environment(PaicordAppState.self) var appState
  @Environment(GatewayStore.self) var gw
  var vm: ChannelStore
  
  @State var text: String = ""
  
  var body: some View {
    HStack {
      TextField("Message", text: $text)
        .textFieldStyle(.roundedBorder)
        #if os(iOS)
          .disabled(appState.chatOpen == false)
        #endif
        .onSubmit(sendMessage)
      #if os(iOS)
        if text.isEmpty == false {
          Button(action: sendMessage) {
            Image(systemName: "paperplane.fill")
              .imageScale(.large)
              .padding(5)
              .foregroundStyle(.white)
              .background(.primaryButton)
              .clipShape(.circle)
          }
          .buttonStyle(.borderless)
          .foregroundStyle(.primaryButton)
          .transition(.move(edge: .trailing).combined(with: .opacity))
        }
      #endif
    }
    .padding(5)
    .background(.regularMaterial)
  }
  
  private func sendMessage() {
    let msg = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !msg.isEmpty else { return }
    text = ""  // clear input field
    Task.detached {
      let nonce: MessageSnowflake? = try? .makeFake(date: .now)
      return try await gw.client.createMessage(
        channelId: vm.channelId,
        payload: .init(
          content: msg,
          nonce: nonce != nil ? .string(nonce!.rawValue) : nil
        )
      )
    }
  }
}
