//
//  Markdown.swift
//  Paicord
//
//  Created by Lakhan Lothiyi on 13/09/2025.
//  Copyright © 2025 Lakhan Lothiyi.
//

import SwiftUI

@Observable
class MarkdownModel {
	var parsedText: AttributedString = ""

	func parse(_ markdown: String) async throws {
		// parse markdown here

		parsedText = try AttributedString(markdown: markdown)
	}
}

struct MarkdownView: View {
	var model: MarkdownModel = .init()
	let markdownText: String

	var body: some View {
		Text(model.parsedText)
			.task(id: markdownText) {
				do {
					try await model.parse(markdownText)
				} catch {
					print(
						"""
						--------------------------------------------
						Failed to parse markdown! Error: \(error).
						Markdown: \n\(markdownText)
						--------------------------------------------\n
						"""
					)
				}
			}
	}
}

#Preview {
	ScrollView {
		MarkdownView(
			markdownText:
				"""
				# Headers

				# big header
				## smaller header
				### small header
				-# subtext or footnote or whatever!

				# Text Formatting
				*italics* _italics_
				__underline__ __*underlining my italics*__
				***bold italics*** and __***bold underlined italics***__!
				~~strikethrough~~

				# Masked Links
				[wagwan](https://llsc12.me)

				# Lists
				* unordered list with asterisk
				* unordered list with asterisk 2
				- unordered list with hyphen
				- unordered list with hyphen 2
					- unordered list hyphen indented
					- unordered list hyphen indented 2
						- unordered list hyphen double indent
							- unordered list hyphen triple indent
				- unordered list with hyphen 3

				1. Step 1
				2. Step 2
						1. Substep 1
						2. Substep 2
				3. Step 3?

				# Code Blocks
				`inline code`
				```
				code block
				1
				2
				3
				```
				```swift
				// code block with a language specified
				@main
				struct Tool {
					static func main() async throws {
						print("hi mom")
						try? await Task.sleep(for: .seconds(1))
						print("process ending")
						exit(0)
					}
				}
				```
				> Block quote
				> It can contain buncha inline things too
				> ```swift
				> // like code
				> ```
				> # and headers
				> ||and spoilers! boo!||
				<https://google.com> is a link with no embed. just remove the angle brackets, embed wont appear at all.

				[tooltip link](https://example.org "tooltips?")
				[no embed tooltip link](<https://example.org> "tooltip and no embed")

				<email@email.com>
				<mailto:email@email.com>
				<+999123456789>
				<tel:+999123456789>
				<sms:+999123456789>

				user mentions <@snowflake>
				channel mentions <#snowflake>
				role mentions <&snowflake>
				custom emojis <emojiname:snowflake> or <a:emojiname:snowflake>

				all date stamp formats
				Relative <t:1757847540:R>
				Short time <t:1757847540:t>
				Long time <t:1757847540:T>
				Short date <t:1757847540:d>
				Long date <t:1757847540:D>
				Long date short time <t:1757847540:f>
				Long date with day of week short time <t:1757847540:F>

				multiline block quotes >>> that follow through to the end of the document
				"""
		)
		.frame(maxWidth: 600)
	}
}
