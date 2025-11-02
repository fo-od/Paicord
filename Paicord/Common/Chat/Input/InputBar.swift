//
//  InputBar.swift
//  Paicord
//
//  Created by Lakhan Lothiyi on 17/10/2025.
//  Copyright © 2025 Lakhan Lothiyi.
//

import PaicordLib
import SwiftUIX

struct InputBar: View {
  @Environment(PaicordAppState.self) var appState
  @Environment(GatewayStore.self) var gw
  var vm: ChannelStore

  @State var text: String = ""

  var body: some View {
    HStack {
      #if os(iOS)
        TextField("Message", text: $text, axis: .vertical)
          .textFieldStyle(.plain)
          .maxHeight(150)
          .fixedSize(horizontal: false, vertical: true)
          .disabled(appState.chatOpen == false)
      #else
        TextView(text: $text)
          .onSubmit(sendMessage)
      #endif

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

#if os(macOS)
  private struct TextView: View {
    @Binding var text: String
    var submit: () -> Void = {}

    func onSubmit(_ action: @escaping () -> Void) -> TextView {
      var copy = self
      copy.submit = action
      return copy
    }

    var body: some View {
      _TextView(text: $text, onSubmit: submit)
        .overlay(alignment: .leading) {
          if text.isEmpty {
            Text("Message")
              .foregroundStyle(.secondary)
              .allowsHitTesting(false)
          }
        }
    }

    private struct _TextView: NSViewRepresentable {
      @Binding var text: String
      var onSubmit: () -> Void
      var maxHeight: CGFloat = 150

      func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.isEditable = true
        textView.isRichText = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = .zero
        textView.delegate = context.coordinator
        textView.drawsBackground = false

        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        return scrollView
      }

      func sizeThatFits(
        _ proposal: ProposedViewSize,
        nsView: NSScrollView,
        context: Context
      ) -> CGSize? {
        guard let textView = nsView.documentView as? NSTextView else {
          return nil
        }
        if let layoutManager = textView.layoutManager,
          let textContainer = textView.textContainer
        {
          layoutManager.ensureLayout(for: textContainer)
          let usedRect = layoutManager.usedRect(for: textContainer)
          let contentHeight =
            usedRect.height + textView.textContainerInset.height * 2
          return CGSize(
            width: proposal.width ?? usedRect.width,
            height: min(contentHeight, maxHeight)
          )
        }
        return nil
      }

      func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else {
          return
        }

        if textView.string != text {
          textView.string = text
        }
      }

      // horrid way of doing this
      func textUpdated(
        oldText: String,
        newText: String
      ) {
        // detect if a new line was added
        if newText.count > oldText.count,
          newText.hasSuffix("\n")
        {
          // return early if shift key is pressed (to allow new lines)
          let shiftPressed = NSEvent.modifierFlags.contains(.shift)
          if shiftPressed { return }
          // trim new lines and submit
          text = newText.trimmingCharacters(in: .newlines)
          onSubmit()
        }
      }

      func makeCoordinator() -> Coordinator {
        Coordinator(self)
      }

      class Coordinator: NSObject, NSTextViewDelegate {
        var parent: _TextView
        private var lastText: String

        init(_ parent: _TextView) {
          self.parent = parent
          self.lastText = parent.text
        }

        func textDidChange(_ notification: Notification) {
          guard let textView = notification.object as? NSTextView else {
            return
          }

          let oldText = lastText
          let newText = textView.string
          lastText = newText

          parent.text = newText

          parent.textUpdated(oldText: oldText, newText: newText)
        }
      }
    }
  }
#endif
