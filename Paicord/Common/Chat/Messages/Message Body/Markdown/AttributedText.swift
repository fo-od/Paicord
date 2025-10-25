//
//  AttributedText.swift
//  Paicord
//
//  Created by Lakhan Lothiyi on 15/10/2025.
//  Copyright © 2025 Lakhan Lothiyi.
//

import SwiftUI

struct AttributedText: View {
  var attributedString: NSAttributedString? = nil
  var body: some View {
    VStack {
      if let attributedString {
        _AttributedTextView(
          attributedString: attributedString
        )
        .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        EmptyView()
      }
    }
  }
}

#if os(macOS)
  import AppKit

  private struct _AttributedTextView: NSViewRepresentable {
    var attributedString: NSAttributedString
    @Environment(\.lineLimit) private var lineLimit
    @Environment(\.openURL) private var openURL  // needed so we can signal that links were tapped.

    func makeCoordinator() -> Coordinator {
      Coordinator(openURL: openURL)
    }

    func makeNSView(context: Context) -> ModifiedCopyingTextView {
      let textView = ModifiedCopyingTextView()
      textView.customCoordinator = context.coordinator
      textView.isEditable = false
      textView.isSelectable = true
      textView.drawsBackground = false
      textView.textContainer?.lineFragmentPadding = 0
      textView.textContainer?.maximumNumberOfLines = lineLimit ?? 0
      textView.textStorage?.setAttributedString(attributedString)
      textView.isAutomaticLinkDetectionEnabled = true
      return textView
    }

    func updateNSView(_ nsView: ModifiedCopyingTextView, context: Context) {
      nsView.customCoordinator = context.coordinator
      nsView.textStorage?.setAttributedString(attributedString)
      nsView.textContainer?.maximumNumberOfLines = lineLimit ?? 0
      nsView.layoutManager?.ensureLayout(for: nsView.textContainer!)
    }

    func sizeThatFits(
      _ proposal: ProposedViewSize,
      nsView: ModifiedCopyingTextView,
      context: Context
    ) -> CGSize? {
      let targetWidth = proposal.width ?? 400
      guard let layoutManager = nsView.layoutManager,
        let textContainer = nsView.textContainer
      else {
        return nil
      }

      textContainer.containerSize = CGSize(
        width: targetWidth,
        height: .greatestFiniteMagnitude
      )
      layoutManager.ensureLayout(for: textContainer)

      let usedRect = layoutManager.usedRect(for: textContainer)
      return CGSize(width: targetWidth, height: usedRect.height)
    }

    // Coordinator holds the SwiftUI OpenURLAction so native clicks can trigger it.
    final class Coordinator: NSObject {
      let openURL: OpenURLAction
      init(openURL: OpenURLAction) {
        self.openURL = openURL
      }
    }
  }

  // NSTextView subclass that preserves copy-behaviour and forwards clicks to coordinator.
  class ModifiedCopyingTextView: NSTextView {
    weak fileprivate var customCoordinator: _AttributedTextView.Coordinator?

    override func clicked(onLink link: Any, at charIndex: Int) {
      if let url = link as? URL {
        customCoordinator?.openURL(url)
      } else {
        super.clicked(onLink: link, at: charIndex)
      }
    }

    override func writeSelection(
      to pboard: NSPasteboard,
      type: NSPasteboard.PasteboardType
    ) -> Bool {
      let selectedAttributedString = attributedString().attributedSubstring(
        from: selectedRange()
      )
      let selectedAttributedStringCopy = NSMutableAttributedString(
        attributedString: selectedAttributedString
      )

      selectedAttributedStringCopy.enumerateAttribute(
        NSAttributedString.Key.attachment,
        in: NSMakeRange(0, (selectedAttributedString.string.count)),
        options: .reverse,
        using: {
          (
            _ value: Any?,
            _ range: NSRange,
            _ stop: UnsafeMutablePointer<ObjCBool>
          ) -> Void in

          if let textAttachment = value as? NSTextAttachment,
            let textAttachmentCell = textAttachment.attachmentCell
              as? MarkdownRendererVM.EmojiAttachmentCell
          {
            var range2: NSRange = NSRange(location: 0, length: 0)
            let attributes = selectedAttributedStringCopy.attributes(
              at: range.location,
              effectiveRange: &range2
            )

            selectedAttributedStringCopy.replaceCharacters(
              in: range,
              with: NSMutableAttributedString(
                string: textAttachmentCell.copyText
              )
            )
            selectedAttributedStringCopy.addAttributes(attributes, range: range)
          }
        }
      )

      pboard.clearContents()
      pboard.writeObjects([selectedAttributedStringCopy])

      return true
    }
  }
#elseif os(iOS)
  import UIKit

  private struct _AttributedTextView: UIViewRepresentable {
    var attributedString: NSAttributedString
    @Environment(\.lineLimit) private var lineLimit
    @Environment(\.openURL) private var openURL  // needed so we can signal that links were tapped.

    func makeCoordinator() -> Coordinator {
      Coordinator(openURL: openURL)
    }

    func makeUIView(context: Context) -> UITextView {
      let textView = UITextView()
      textView.delegate = context.coordinator
      textView.isEditable = false
      textView.isSelectable = true
      textView.isScrollEnabled = false
      textView.backgroundColor = .clear
      textView.textContainerInset = .zero
      textView.textContainer.lineFragmentPadding = 0
      textView.textContainer.maximumNumberOfLines = lineLimit ?? 0

      textView.textStorage.setAttributedString(attributedString)
      textView.layoutManager.ensureLayout(for: textView.textContainer)
      textView.dataDetectorTypes = [.link]
      textView.isUserInteractionEnabled = true
      textView.isScrollEnabled = false
      // allow links, but we'll intercept via delegate
      textView.isEditable = false
      textView.isSelectable = true
      return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
      uiView.attributedText = attributedString
      uiView.textContainer.maximumNumberOfLines = lineLimit ?? 0
      uiView.layoutManager.ensureLayout(for: uiView.textContainer)
      uiView.delegate = context.coordinator
    }

    func sizeThatFits(
      _ proposal: ProposedViewSize,
      uiView: UITextView,
      context: Context
    ) -> CGSize? {
      let targetWidth = proposal.width ?? UIScreen.main.bounds.width
      let fittingSize = CGSize(
        width: targetWidth,
        height: .greatestFiniteMagnitude
      )
      let size = uiView.sizeThatFits(fittingSize)
      return CGSize(width: targetWidth, height: size.height)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
      let openURL: OpenURLAction
      init(openURL: OpenURLAction) {
        self.openURL = openURL
      }

      // Intercept link taps. If it's a paicord:// link, forward to SwiftUI's openURL and return false
      func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
      ) -> Bool {
        openURL(URL)
        return true
      }
    }
  }

#endif
