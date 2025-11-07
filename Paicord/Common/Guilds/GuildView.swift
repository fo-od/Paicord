//
//  GuildView.swift
//  Paicord
//
//  Created by Lakhan Lothiyi on 22/09/2025.
//  Copyright © 2025 Lakhan Lothiyi.
//

import PaicordLib
import SDWebImageSwiftUI
import SwiftUIX

struct GuildView: View {
  var guild: GuildStore
  @Environment(\.userInterfaceIdiom) var idiom
  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        if let bannerURL = bannerURL(animated: true) {  // maybe add animation control?
          AnimatedImage(url: bannerURL)
            .resizable()
            .aspectRatio(16 / 9, contentMode: .fill)
        }

        if idiom == .phone {
          VStack(spacing: 0) {
            VStack(alignment: .leading) {
              Text(guild.guild?.name ?? "Unknown Guild")
                .font(.headline)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
              Text("\(guild.guild?.member_count ?? 0) members")
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .padding()

            Divider()
              .padding(.bottom, 4)
          }
        }

        // these are channels without a category, aka categories themselves or actually uncategorized channels
        let uncategorizedChannels = guild.channels.values
          .filter { $0.parent_id == nil }
          .sorted { ($0.position ?? 0) < ($1.position ?? 0) }

        VStack(spacing: 4) {
          ForEach(uncategorizedChannels) { channel in
            ChannelButton(channels: guild.channels, channel: channel)
              .padding(.horizontal, 10)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
    }
    .frame(maxWidth: .infinity)
    .background(.tableBackground.opacity(0.5))
    .roundedCorners(radius: 10, corners: .topLeft)
  }

  func bannerURL(animated: Bool) -> URL? {
    guard let banner = guild.guild?.banner else { return nil }
    if banner.starts(with: "a_"), animated {
      return URL(
        string: CDNEndpoint.guildBanner(guildId: guild.guildId, banner: banner)
          .url
          + ".\(animated ? "gif" : "png")?size=600&animated=true"
      )
    } else {
      return URL(
        string: CDNEndpoint.guildBanner(guildId: guild.guildId, banner: banner)
          .url
          + ".png?size=600&animated=false"
      )
    }
  }
}
