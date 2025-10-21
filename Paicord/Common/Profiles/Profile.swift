//
//  Profile.swift
//  Paicord
//
//  Created by Lakhan Lothiyi on 18/10/2025.
//  Copyright © 2025 Lakhan Lothiyi.
//

import PaicordLib
import SDWebImageSwiftUI
import SwiftUIX

/// Collection of ui components for profiles
enum Profile {
  struct Avatar: View {
    let member: Guild.PartialMember?
    let user: DiscordUser

    var body: some View {
      WebImage(url: avatarURL(animated: true)) { phase in
        switch phase {
        case .success(let image):
          image
            .resizable()
            .scaledToFit()
        default:
          Circle()
            .foregroundStyle(.gray.opacity(0.3))
        }
      }
      .clipShape(Circle())
    }

    func avatarURL(animated: Bool) -> URL? {
      let id = user.id
      if let avatar = member?.avatar ?? user.avatar {
        if avatar.starts(with: "a_"), animated {
          return URL(
            string: CDNEndpoint.userAvatar(userId: id, avatar: avatar).url
              + ".gif?size=128&animated=true"
          )
        } else {
          return URL(
            string: CDNEndpoint.userAvatar(userId: id, avatar: avatar).url
              + ".png?size=128&animated=false"
          )
        }
      } else {
        let discrim = user.discriminator
        return URL(
          string: CDNEndpoint.defaultUserAvatar(discriminator: discrim).url
            + "?size=128"
        )
      }
    }
  }

  struct AvatarWithPresence: View {
    @Environment(GatewayStore.self) var gw
    let member: Guild.PartialMember?
    let user: DiscordUser
    var hideOffline: Bool

    var body: some View {
      GeometryReader { geo in
        let size = min(geo.size.width, geo.size.height)
        let dotSize = size * 0.25
        let inset = dotSize * 0.55

        let presence: ActivityData? = {
          if user.id == gw.user.currentUser?.id,
            let session = gw.user.sessions.last
          {
            return session
          } else {
            return gw.user.presences[user.id]
          }
        }()

        ZStack(alignment: .bottomTrailing) {
          Avatar(member: member, user: user)
            .reverseMask(alignment: .bottomTrailing) {
              if ([Gateway.Status.offline, .invisible].contains(
                presence?.status ?? .offline
              ) && hideOffline) == false {
                Circle()
                  .frame(width: dotSize * 1.5, height: dotSize * 1.5)
                  .position(
                    x: geo.size.width - inset,
                    y: geo.size.height - inset
                  )
              }
            }

          if let presence {
            let color: Color = {
              switch presence.status {
              case .online: return .init(hexadecimal6: 0x42a25a)
              case .afk: return .init(hexadecimal6: 0xca9653)
              case .doNotDisturb: return .init(hexadecimal6: 0xd83a42)
              default: return .init(hexadecimal6: 0x82838b)
              }
            }()

            Group {
              switch presence.status {
              case .online:
                StatusIndicatorShapes.OnlineShape()
              case .afk:
                StatusIndicatorShapes.IdleShape()
              case .doNotDisturb:
                StatusIndicatorShapes.DNDShape()
              default:
                StatusIndicatorShapes.InvisibleShape()
                  .hidden(hideOffline)
              }
            }
            .foregroundStyle(color)
            .frame(width: dotSize, height: dotSize)
            .position(
              x: geo.size.width - inset,
              y: geo.size.height - inset
            )
          } else {
            StatusIndicatorShapes.InvisibleShape()
              .foregroundStyle(Color.init(hexadecimal6: 0x82838b))
              .frame(width: dotSize, height: dotSize)
              .position(
                x: geo.size.width - inset,
                y: geo.size.height - inset
              )
              .hidden(hideOffline)
          }
        }
        .frame(width: geo.size.width, height: geo.size.height)
      }
      .aspectRatio(1, contentMode: .fit)
    }
  }

  struct NameplateView: View {
    @Environment(\.colorScheme) var colorScheme
    let nameplate: DiscordUser.Collectibles.Nameplate

    var color: Color {
      switch colorScheme {
      case .light:
        nameplate.palette.color.light.asColor()
      case .dark:
        nameplate.palette.color.dark.asColor()
      @unknown default:
        fatalError()
      }
    }

    var staticURL: URL? {
      URL(
        string: CDNEndpoint.collectibleNameplate(
          asset: nameplate.asset,
          file: .static
        ).url
      )
    }

    var body: some View {
      ZStack {
        switch nameplate.palette {
        case .none, .__undocumented: EmptyView()
        default:
          LinearGradient(
            gradient: Gradient(stops: [
              .init(color: color.opacity(0.1), location: 0.0),
              .init(color: color.opacity(0.4), location: 1.0),
            ]),
            startPoint: .leading,
            endPoint: .trailing
          )
        }
        WebImage(url: staticURL)
          .resizable()
          .scaledToFill()
          .clipped()
      }
    }
  }
}

enum StatusIndicatorShapes {
  struct OnlineShape: View {
    var body: some View {
      Circle()
    }
  }
  struct IdleShape: View {
    var body: some View {
      GeometryReader { geo in
        let size = min(geo.size.width, geo.size.height)
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        let radius = size / 2

        let cutoutRadius = radius * 0.65
        let cutoutCenter = CGPoint(
          x: geo.size.width - radius * 1.5,
          y: geo.size.height - radius * 1.4
        )

        Circle()
          .frame(width: radius * 2, height: radius * 2)
          .position(center)
          .reverseMask {
            Circle()
              .frame(width: cutoutRadius * 2, height: cutoutRadius * 2)
              .position(cutoutCenter)
          }
      }
      .aspectRatio(1, contentMode: .fit)
    }
  }
  struct DNDShape: View {
    var body: some View {
      GeometryReader { geo in
        let size = min(geo.size.width, geo.size.height)
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        let radius = size / 2

        let capsuleWidth = size * 0.6
        let capsuleHeight = size * 0.18
        let capsuleCenter = center

        Circle()
          .frame(width: radius * 2, height: radius * 2)
          .position(center)
          .reverseMask {
            RoundedRectangle(cornerRadius: capsuleHeight / 2)
              .frame(width: capsuleWidth, height: capsuleHeight)
              .position(x: capsuleCenter.x, y: capsuleCenter.y)
          }
      }
      .aspectRatio(1, contentMode: .fit)
    }
  }
  struct InvisibleShape: View {
    var body: some View {
      GeometryReader { geo in
        let size = min(geo.size.width, geo.size.height)
        let radius = size / 2
        let cutoutRadius = radius * 0.5

        Circle()
          .frame(width: radius * 2, height: radius * 2)
          .reverseMask {
            Circle()
              .frame(width: cutoutRadius * 2, height: cutoutRadius * 2)
          }
      }
      .aspectRatio(1, contentMode: .fit)
    }
  }
}
