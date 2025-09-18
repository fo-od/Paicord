//
//  RootView.swift
//  Paicord
//
//  Created by Lakhan Lothiyi on 18/09/2025.
//  Copyright © 2025 Lakhan Lothiyi.
//  

import SwiftUIX

// Handles using phone suitable layout or desktop suitable layout

struct RootView: View {
	let gatewayStore: GatewayStore
	@Bindable var appState: PaicordAppState
	@Environment(Challenges.self) var challenges
	@Environment(\.userInterfaceIdiom) var idiom

	var body: some View {
		Group {
			if gatewayStore.accounts.currentAccountID == nil {
				LoginView()
					.environment(gatewayStore)
					.environment(appState)
			} else if gatewayStore.state != .connected {
				ConnectionStateView(state: gatewayStore.state)
					.transition(.opacity.combined(with: .scale(scale: 1.1)))
					.task { await gatewayStore.connectIfNeeded() }
			} else {
				if idiom == .phone {
					#if os(iOS)
						SmallBaseplate()
					#endif
				} else {
					LargeBaseplate()
				}
			}
		}
		.navigationTitle("")
		.animation(.default, value: gatewayStore.state != .connected)
		.fontDesign(.rounded)
		.modifier(
			PaicordSheetsAlerts(
				gatewayStore: gatewayStore,
				appState: appState
			)
		)
		.environment(gatewayStore)
		.environment(appState)
		.onAppear { setupGatewayCallbacks() }
	}

	// MARK: - Gateway Callbacks

	private func setupGatewayCallbacks() {
		gatewayStore.captchaCallback = { captcha in
			await challenges.presentCaptcha(captcha)
		}
		gatewayStore.mfaCallback = { mfaData in
			await challenges.presentMFA(mfaData)
		}
	}
}
