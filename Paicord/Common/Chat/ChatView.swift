//
//  ChatView.swift
//  PaiCord
//
// Created by Lakhan Lothiyi on 31/08/2025.
// Copyright © 2025 Lakhan Lothiyi.
//

import Collections
import PaicordLib
@_spi(Advanced) import SwiftUIIntrospect
import SwiftUIX

struct ChatView: View {
  var vm: ChannelStore
  @Environment(\.gateway) var gw
  @Environment(\.appState) var appState
  @Environment(\.accessibilityReduceMotion) var accessibilityReduceMotion
  @Environment(\.userInterfaceIdiom) var idiom
  @Environment(\.theme) var theme

  @ViewStorage private var isNearBottom = true  // used to track if we are near the bottom, if so scroll.
  @ViewStorage private var pendingScrollWorkItem: DispatchWorkItem?

  init(vm: ChannelStore) { self.vm = vm }

  var body: some View {
    #if os(macOS)
      let orderedMessages = vm.messages.values.reversed()  // prep for flipping scrollview and then each message
    #else
      let orderedMessages = vm.messages.values
    #endif
    VStack(spacing: 0) {
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 0) {
            // if on ios or macos, you put certain elements first and last due to 180º rotation.
            #if os(iOS)
              PlaceholderMessageSet()

              ForEach(orderedMessages) { msg in
                let prior = vm.getMessage(before: msg)
                if messageAllowed(msg) {
                  MessageCell(for: msg, prior: prior, channel: vm)
                    .onAppear {
                      guard msg == vm.messages.values.last else { return }
                      self.isNearBottom = true
                    }
                    .onDisappear {
                      guard msg == vm.messages.values.last else { return }
                      self.isNearBottom = false
                    }
                }
              }

            // message drain here
            #endif

            #if os(macOS)
              ForEach(orderedMessages) { msg in
                let prior = vm.getMessage(before: msg)
                if messageAllowed(msg) {
                  MessageCell(for: msg, prior: prior, channel: vm)
                    .rotationEffect(.degrees(-180))
                }
              }

              PlaceholderMessageSet()
                .rotationEffect(.degrees(-180))
            #endif
          }
          //#if os(macOS)
          //  .safeAreaPadding(.top, 22)
          //#endif
          .scrollTargetLayout()
        }
        .maxHeight(.infinity)
        #if os(iOS)
          .bottomAnchored()
          .safeAreaPadding(.bottom, 22)
        #else
          .safeAreaPadding(.top, 22)
          .rotationEffect(.degrees(180))
          .scrollIndicators(.hidden)
        #endif
        .scrollDismissesKeyboard(.interactively)
        #if os(iOS)
          .onAppear {
            NotificationCenter.default.post(
              name: .chatViewShouldScrollToBottom,
              object: ["channelId": self.vm.channelId, "immediate": true]
            )
          }
          .onChange(of: vm.channelId) {
            NotificationCenter.default.post(
              name: .chatViewShouldScrollToBottom,
              object: ["channelId": vm.channelId, "immediate": true]
            )
          }
          .onChange(of: vm.messages.count) { oldValue, newValue in
            if oldValue == 0 && newValue > 0 {
              // first load?
              NotificationCenter.default.post(
                name: .chatViewShouldScrollToBottom,
                object: ["channelId": vm.channelId, "immediate": true]
              )
            }
          }
          .onReceive(
            NotificationCenter.default.publisher(
              for: .chatViewShouldScrollToBottom
            )
          ) { object in
            guard let info = object.object as? [String: Any],
              let channelId = info["channelId"] as? ChannelSnowflake,
              channelId == vm.channelId
            else { return }
            guard (!isNearBottom) || (info["immediate"] as? Bool == true) else {
              return
            }
            scheduleScrollToBottom(
              proxy: proxy,
              lastID: vm.messages.values.last?.id
            )
          }
        #endif
      }
    }
    .safeAreaInset(edge: .bottom, spacing: 0) {
      VStack(spacing: 0) {
        InputBar(vm: vm)
      }
    }
    .background(theme.common.secondaryBackground)
    .toolbar {
      ToolbarItem(placement: .navigation) {
        ChannelHeader(vm: vm)
      }
      //			if let topic = vm.channel?.topic, !topic.isEmpty {
      //				ToolbarItem(placement: .navigation) {
      //					HStack {
      //						ChannelTopic(topic: topic)
      //					}
      //				}
      //			}
    }
  }

  func messageAllowed(_ msg: DiscordChannel.Message) -> Bool {
    // Currently only filters out messages from blocked users
    guard let authorId = msg.author?.id else { return true }

    // check relationship
    if let relationship = gw.user.relationships[authorId] {
      if relationship.type == .blocked || relationship.user_ignored {
        return false
      }
    }

    return true
  }

  private func scheduleScrollToBottom(
    proxy: ScrollViewProxy,
    lastID: DiscordChannel.Message.ID? = nil,
  ) {
    pendingScrollWorkItem?.cancel()
    guard let lastID else { return }

    let workItem = DispatchWorkItem { [proxy] in
      //      withAnimation(accessibilityReduceMotion ? .none : .default) {
      proxy.scrollTo(lastID, anchor: .top)
      //      }
    }
    pendingScrollWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
  }

  @State var ackTask: Task<Void, Error>? = nil
  private func acknowledge() {
    ackTask?.cancel()
    ackTask = Task {
      try? await Task.sleep(for: .seconds(1.5))
      Task.detached {
        try await gw.client.triggerTypingIndicator(channelId: .makeFake())
      }
    }
  }
}

extension View {
  fileprivate func bottomAnchored() -> some View {
    if #available(iOS 18.0, macOS 15.0, *) {
      return
        self
        .defaultScrollAnchor(.bottom, for: .initialOffset)
        .defaultScrollAnchor(.bottom, for: .alignment)
        .defaultScrollAnchor(.bottom, for: .sizeChanges)
    } else {
      return
        self
        .defaultScrollAnchor(.bottom)
    }
  }
}

// add a new notification that channelstore can notify to scroll down in chat
extension Notification.Name {
  static let chatViewShouldScrollToBottom = Notification.Name(
    "chatViewShouldScrollToBottom"
  )
}
