//
//  MessageDrainStore.swift
//  Paicord
//
//  Created by Lakhan Lothiyi on 31/10/2025.
//  Copyright © 2025 Lakhan Lothiyi.
//

import Collections
import Foundation
import PaicordLib
import PhotosUI

@Observable
class MessageDrainStore: DiscordDataStore {
  var gateway: GatewayStore?
  var eventTask: Task<Void, Never>?

  init() {}

  // MARK: - Protocol Methods

  func setupEventHandling() {
    guard let gateway = gateway?.gateway else { return }

    eventTask = Task { @MainActor in
      for await event in await gateway.events {
        switch event.data {
        case .messageCreate(let message):
          // when a message is created, we check if its in pendingMessages, and its nonce matches.
          // the nonce of the message received will match a key of pendingMessages if its one we sent.
          if let nonce = message.nonce?.asString,
            let messageNonceSnowflake = Optional(MessageSnowflake(nonce))
          {
            // remove from pending as its been sent successfully
            pendingMessages[message.channel_id, default: [:]].removeValue(
              forKey: messageNonceSnowflake
            )
            // also remove from failed messages if it was there
            failedMessages.removeValue(forKey: messageNonceSnowflake)
            // also remove from message tasks if it was there
            messageTasks.removeValue(forKey: messageNonceSnowflake)
          }
          break
        default:
          break
        }
      }
    }
  }

  // Messages get sent innit, but heres how it works.
  // If a message is in the pendingMessages dict, it wil lexist in all of the dictionaries below.
  // When a message is sent, it has a temporary snowflake assigned to it which is a generated nonce with the current timestamp.
  // When the message is successfully sent, it is removed from all dictionaries.
  // If a failure occurs, it is kept in pendingMessages and an error is added to failedMessages.
  // when a message send does fail, the messageTasks queue is halted, and all remaining messages stay in limbo until the failed message is retried.
  // If a message is retried, the error is removed from failedMessages and the send task is re-executed.

  var pendingMessages = [
    ChannelSnowflake: OrderedDictionary<
      MessageSnowflake, Payloads.CreateMessage
    >
  ]()
  var failedMessages: [MessageSnowflake: Error?] = [:]

  var messageSendQueueTask: Task<Void, Never>?
  var messageTasks: [MessageSnowflake: @Sendable () async throws -> Void] = [:]
  {
    didSet {
      guard messageSendQueueTask == nil else { return }
      setupQueueTask()
    }
  }

  func setupQueueTask() {
    messageSendQueueTask?.cancel()
    messageSendQueueTask = Task { @MainActor [weak self] in
      guard let self else { return }
      defer { self.messageSendQueueTask = nil }
      guard !self.messageTasks.isEmpty else { return }
      let (id, task) = self.messageTasks.first!
      do {
        try await task()
        self.messageTasks.removeValue(forKey: id)
        self.failedMessages.removeValue(forKey: id)

        // continue to next message
        self.setupQueueTask()
      } catch {
        // halt the queue on first failure.
        return
      }
    }
  }

  // key methods

  func send(_ vm: ChatView.InputBar.InputVM, in channel: ChannelSnowflake) {
    // the message instance will die inside the task
    guard let gateway = gateway?.gateway else { return }
    // the swiftui side inits the message with a nonce already btw
    // set our message up
    let nonce: MessageSnowflake = try! .makeFake(date: .now)
    let message = Payloads.CreateMessage(
      content: vm.content,
      nonce: .string(nonce.rawValue)
    )
    let task: @Sendable () async throws -> Void = { [weak self] in
      guard let self else { return }
      do {
        var message = self.pendingMessages[channel, default: [:]][nonce]!
        message.attachments = []  // nil by default, allows appends
        if !vm.uploadItems.isEmpty {
          let uploadAttachments = try await withThrowingTaskGroup(
            of: Payloads.CreateAttachments.UploadAttachment.self,
            returning: [Payloads.CreateAttachments.UploadAttachment].self
          ) { group in
            for item in vm.uploadItems {
              group.addTask {
                // get local url
                switch item {
                case .pickerItem(let id, let pickerItem):
                  let filename =
                    "\(pickerItem.itemIdentifier ?? UUID().uuidString).png"
                  let filesize = await item.filesize() ?? 0
                  return Payloads.CreateAttachments.UploadAttachment.init(
                    id: id.uuidString,
                    filename: filename,
                    file_size: filesize
                  )
                case .file(let id, let url, let size):
                  let filename = url.lastPathComponent
                  let filesize = size
                  return Payloads.CreateAttachments.UploadAttachment.init(
                    id: id.uuidString,
                    filename: filename,
                    file_size: Int(filesize)
                  )
                case .cameraPhoto(let id, _):
                  let filename = "\(UUID().uuidString).png"
                  let filesize = await item.filesize() ?? 0
                  return Payloads.CreateAttachments.UploadAttachment.init(
                    id: id.uuidString,
                    filename: filename,
                    file_size: filesize
                  )
                case .cameraVideo(let id, let url):
                  let filename = url.lastPathComponent
                  let filesize = await item.filesize() ?? 0
                  return Payloads.CreateAttachments.UploadAttachment.init(
                    id: id.uuidString,
                    filename: filename,
                    file_size: filesize
                  )
                }
              }
            }
            var results: [Payloads.CreateAttachments.UploadAttachment] = []
            for try await attachments in group {
              results.append(attachments)
            }
            return results
          }
          // make attachments specifying filename and size to discord, the returned urls will be used to upload the files via HTTP PUT
          let createdAttachmentsReq = try await self
            .gateway!.client
            .createAttachments(
              channelID: channel,
              payload: .init(files: uploadAttachments)
            )
          try createdAttachmentsReq.guardSuccess()
          let createdAttachments: [UUID: Gateway.CloudAttachment] =
            try createdAttachmentsReq.decode()
            .reduce(into: [:]) { partialResult, attachment in
              let id: UUID = UUID(uuidString: attachment.id!)!
              partialResult[id] = attachment
            }

          // upload files
          await withThrowingTaskGroup { group in
            for (id, attachment) in createdAttachments {
              let item = vm.uploadItems.first(where: {
                $0.id == id
              })!
              let index = vm.uploadItems.firstIndex(where: {
                $0.id == id
              })!
              group.addTask {
                // upload to url
                switch item {
                case .pickerItem(_, let pickerItem):
                  let data = try await pickerItem.loadTransferable(
                    type: Data.self
                  )
                  guard let data else {
                    throw "Failed to load attachment data."
                  }
                  var req = URLRequest(
                    url: .init(string: attachment.upload_url)!
                  )
                  req.httpMethod = "PUT"
                  let (_, res) = try await URLSession.shared.upload(
                    for: req,
                    from: data
                  )
                  guard (res as? HTTPURLResponse)?.statusCode == 200 else {
                    throw "Failed to upload attachment."
                  }
                case .file(_, let fileURL, _):
                  var req = URLRequest(
                    url: .init(string: attachment.upload_url)!
                  )
                  req.httpMethod = "PUT"
                  let (_, res) = try await URLSession.shared.upload(
                    for: req,
                    fromFile: fileURL
                  )
                  guard (res as? HTTPURLResponse)?.statusCode == 200 else {
                    throw "Failed to upload attachment."
                  }
                case .cameraPhoto(_, let image):
                  let data = image.pngData()!
                  var req = URLRequest(
                    url: .init(string: attachment.upload_url)!
                  )
                  req.httpMethod = "PUT"
                  let (_, res) = try await URLSession.shared.upload(
                    for: req,
                    from: data
                  )
                  guard (res as? HTTPURLResponse)?.statusCode == 200 else {
                    throw "Failed to upload attachment."
                  }
                case .cameraVideo(_, let videoURL):
                  var req = URLRequest(
                    url: .init(string: attachment.upload_url)!
                  )
                  req.httpMethod = "PUT"
                  let (_, res) = try await URLSession.shared.upload(
                    for: req,
                    fromFile: videoURL
                  )
                  guard (res as? HTTPURLResponse)?.statusCode == 200 else {
                    throw "Failed to upload attachment."
                  }
                }
                // add attachment to message payload
                message.attachments?.append(
                  .init(
                    index: index,
                    filename: URL(string: createdAttachments[id]!.upload_url)!
                      .lastPathComponent,
                    uploaded_filename: createdAttachments[id]!.upload_filename
                  )
                )

              }
            }
          }
        }

        try await gateway.client.createMessage(
          channelId: channel,
          payload: message
        )
        .guardSuccess()
      } catch {
        // mark as failed
        print("[MessageDrainStore] Message send failed \(nonce): \(error)")
        self.failedMessages[nonce] = error
        throw error
      }
      // remove from pending and failed
      self.pendingMessages[channel, default: [:]].removeValue(forKey: nonce)
      self.failedMessages.removeValue(forKey: nonce)
      self.messageTasks.removeValue(forKey: nonce)
    }

    // store in pending
    pendingMessages[channel, default: [:]].updateValueAndMoveToFront(
      message,
      forKey: nonce
    )
    // store task
    messageTasks[nonce] = task
  }

  /// Removes an enqueued message from all tracking dictionaries, usually used to give up on a message.
  /// - Parameters:
  ///   - nonce: The nonce of the message to remove.
  ///   - channel: The channel the message is in.
  func removeEnqueuedMessage(
    nonce: MessageSnowflake,
    in channel: ChannelSnowflake
  ) {
    // remove from all dicts
    pendingMessages[channel]?.removeValue(forKey: nonce)
    failedMessages.removeValue(forKey: nonce)
    messageTasks.removeValue(forKey: nonce)
  }
}
