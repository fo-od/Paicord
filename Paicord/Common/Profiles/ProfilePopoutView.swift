//
//  ProfilePopoutView.swift
//  Paicord
//
//  Created by Lakhan Lothiyi on 18/10/2025.
//  Copyright © 2025 Lakhan Lothiyi.
//

import PaicordLib
import SDWebImageSwiftUI
import SwiftPrettyPrint
import SwiftUIX

/// Sheet on iOS, else its the popover on macOS/ipadOS.
struct ProfilePopoutView: View {
  @Environment(GatewayStore.self) var gw
  @Environment(PaicordAppState.self) var appState
  @Environment(\.userInterfaceIdiom) var idiom
  var guild: GuildStore?
  let member: Guild.PartialMember?
  let user: PartialUser

  @State private var profile: DiscordUser.Profile?
  @State private var showMainProfile: Bool = false

  public init(
    guild: GuildStore? = nil,
    member: Guild.PartialMember? = nil,
    user: PartialUser,
    profile: DiscordUser.Profile? = nil
  ) {
    self.guild = guild
    self.member = member
    self.user = user
    self._profile = State(initialValue: profile)
  }

  var body: some View {
    ScrollView {
      VStack {
        WebImage(
          url: bannerURL(animated: true),
        )
        .resizable()
        .scaledToFit()
        .maxWidth(.infinity)
        .background(.red)

        Profile.AvatarWithPresence(
          member: member,
          user: user
        )
        .animated(true)
        .showsAvatarDecoration()
        .frame(maxWidth: 80, maxHeight: 80)

        Text(
          member?.nick ?? user.global_name ?? user.username ?? "Unknown User"
        )
        .font(.title)
        .bold()
        .padding(.top, 4)
      }
      .minWidth(idiom == .phone ? nil : 300)  // popover limits on larger devices
      .maxWidth(idiom == .phone ? nil : 300)  // popover limits on larger devices
      .minHeight(idiom == .phone ? nil : 400)  // popover limits on larger devices
    }
    .presentationDetents([.medium, .large])
    .task {
      guard profile == nil else { return }
      let res = try? await gw.client.getUserProfile(
        userID: user.id,
        withMutualGuilds: true,
        withMutualFriends: true,
        withMutualFriendsCount: true,
        guildID: guild?.guildId
      )
      do {
        // ensure request was successful
        try res?.guardSuccess()
        let profile = try res?.decode()
        self.profile = profile
      } catch {
        if let error = res?.asError() {
          appState.error = error
        } else {
          appState.error = error
        }
      }
    }
  }

  func bannerURL(animated: Bool) -> URL? {
    let userId = user.id
    if let guildProfile = profile?.guild_member_profile,
      let guildId = profile?.guild_member_profile?.guild_id,
      let banner = guildProfile.banner, self.showMainProfile == false
    {
      return URL(
        string: CDNEndpoint.guildMemberBanner(
          guildId: guildId,
          userId: userId,
          banner: banner
        ).url
          + ((banner.hasPrefix("a_") && animated)
            ? ".gif" : ".png") + "?size=600"
      )
    } else if let banner = profile?.user_profile?.banner {
      return URL(
        string: CDNEndpoint.userBanner(
          userId: userId,
          banner: banner
        ).url
          + ((banner.hasPrefix("a_") && animated)
            ? ".gif" : ".png") + "?size=600"
      )
    }
    return nil
  }
}
