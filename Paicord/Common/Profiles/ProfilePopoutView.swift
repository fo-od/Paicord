//
//  ProfilePopoutView.swift
//  Paicord
//
//  Created by Lakhan Lothiyi on 18/10/2025.
//  Copyright © 2025 Lakhan Lothiyi.
//

import PaicordLib
import SwiftUIX

struct ProfilePopoutView: View {
  @Environment(\.userInterfaceIdiom) var idiom
  var guild: GuildStore?
  let member: Guild.PartialMember?
  let user: DiscordUser

  var body: some View {
    ScrollView {

      VStack {
        Profile.AvatarWithPresence(
          member: member,
          user: user,
          hideOffline: false
        )
        .frame(maxWidth: 80, maxHeight: 80)
      }
      .minWidth(idiom == .phone ? nil : 300)
      .maxWidth(idiom == .phone ? nil : 300)
      .minHeight(idiom == .phone ? nil : 400)
    }
    .presentationDetents([.medium, .large])
  }

  func bannerURL(animated: Bool) -> URL? {
    let userId = user.id
    if let guildId = guild?.guildId,
      let banner = member?.banner ?? user.banner
    {
      return URL(
        string: CDNEndpoint.guildMemberBanner(
          guildId: guildId,
          userId: userId,
          banner: banner
        ).url
          + ((banner.hasPrefix("a_") && animated)
            ? "gif" : "png") + "?size=600"
      )
    }
    return nil
  }
}
