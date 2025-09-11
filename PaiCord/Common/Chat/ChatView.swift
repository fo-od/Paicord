//
//  ChatView.swift
//  PaiCord
//
// Created by Lakhan Lothiyi on 31/08/2025.
// Copyright © 2025 Lakhan Lothiyi.
//

import Observation
import SwiftUI

//struct ChatView: View {
//	var viewModel = ChatViewModel()
//	var body: some View {
//		List {
//			ForEach(viewModel.messages) { message in
//				HStack {
//					Circle()
//						.fill(Color.blue)
//						.frame(width: 50, height: 50)
//					VStack(alignment: .leading) {
//						Text("User \(message.id.uuidString.prefix(4))")
//							.font(.headline)
//						Text(message.text)
//							.font(.subheadline)
//							.foregroundColor(.gray)
//					}
//					Spacer()
//					Text(message.date, style: .time)
//						.font(.caption)
//						.foregroundColor(.gray)
//				}
//				.padding(.vertical, 8)
//			}
////			Text("soon")
//		}
//		.scrollContentBackground(.hidden)
//		.background(.tableBackground)
//		.listStyle(.plain)
//	}
//}
//
//@Observable
//class ChatViewModel {
//	var messages: [Message] = [.init(text: "wagwan"), .init(text: "hello"), .init(text: "hi"), .init(text: "how are you?")]
//
//	func addMessage(_ text: String) {
//		messages.append(.init(text: "gm"))
//	}
//
//	struct Message: Identifiable {
//		let id = UUID()
//		let date: Date = .now
//		let text: String
//	}
//}
//
//#Preview {
//	ContentView()
//}

import SwiftUI

// MARK: - Simple Message model
struct Message: Identifiable {
		let id = UUID()
		let text: String
}

// MARK: - Tiny ViewModel
@MainActor
final class ChatViewModel: ObservableObject {
		@Published var messages: [Message] = [
				Message(text: "Welcome to ChatView 👋")
		]
		
		init() {
				// Simulate new incoming messages every 2 seconds
				Task {
						let sample = [
								"Hey there!",
								"This is a test message.",
								"SwiftUI on iOS 17 is great.",
								"Bottom anchored scrolling ✅",
								"No more rotation hacks!",
								"🚀"
						]
						
						while true {
								try? await Task.sleep(for: .seconds(2))
								let msg = Message(text: sample.randomElement() ?? "...")
								messages.append(msg)
						}
				}
		}
}

// MARK: - ChatView
struct ChatView: View {
		@StateObject private var vm = ChatViewModel()
		
		var body: some View {
				ScrollView {
						LazyVStack(alignment: .leading, spacing: 8) {
								ForEach(vm.messages) { msg in
										Text(msg.text)
												.padding(8)
												.background(.blue.opacity(0.1))
												.clipShape(RoundedRectangle(cornerRadius: 8))
												.frame(maxWidth: .infinity, alignment: .leading)
								}
						}
						.padding()
						.scrollTargetLayout() // 👈 mark children as scroll targets
				}
				.scrollTargetBehavior(.viewAligned)
				.defaultScrollAnchor(.bottom) // 👈 anchor at bottom
		}
}

// MARK: - Preview
#Preview {
		ChatView()
}
