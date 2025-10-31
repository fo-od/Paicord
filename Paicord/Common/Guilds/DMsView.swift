//
//  DMsView.swift
//  Paicord
//
//  Created by Lakhan Lothiyi on 06/10/2025.
//  Copyright © 2025 Lakhan Lothiyi.
//

//
//  DMsView.swift
//  Paicord
//
//  Created by Lakhan Lothiyi on 22/09/2025.
//  Copyright © 2025 Lakhan Lothiyi.
//

import PaicordLib
import SwiftUIX

struct DMsView: View {
  @Environment(GatewayStore.self) var gw
  @Environment(PaicordAppState.self) var appState
  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        Text("Direct Messages")
          .font(.title2)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(8)
        Divider()
      }
      .hidden(on: .mac)
      .hidden(on: .pad)

      let channels = Array(gw.user.privateChannels.values)
      LazyVStack {
        ForEach(channels) { channel in
          ChannelButton(channels: [:], channel: channel)
        }
      }
      .padding(.vertical, 4)
    }
    .frame(maxWidth: .infinity)
    .background(.tableBackground.opacity(0.5))
    .roundedCorners(radius: 10, corners: .topLeft)
  }
}
