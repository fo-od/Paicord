//
//  PaiCordApp.swift
//  PaiCord
//
// Created by Lakhan Lothiyi on 31/08/2025.
// Copyright © 2025 Lakhan Lothiyi.
//

import PaicordLib
import SDWebImageSVGCoder
import SwiftUI

@main
struct PaiCordApp: App {
	let gatewayStore: GatewayStore

	// captcha handling
	@State private var captchaChallenge: CaptchaChallengeData?
	@State private var captchaContinuation:
		CheckedContinuation<CaptchaSubmitData, Never>?

	init() {
		let SVGCoder = SDImageSVGCoder.shared
		SDImageCodersManager.shared.addCoder(SVGCoder)

		let store = GatewayStore()
		self.gatewayStore = store
	}
	var body: some Scene {
		WindowGroup {
			Group {
				//			ContentView()
				LoginView()
			}
			.fontDesign(.rounded)
			.environment(gatewayStore)
			.onAppear {
				gatewayStore.captchaCallback = { captcha in
					await withCheckedContinuation { continuation in
						captchaChallenge = captcha
						captchaContinuation = continuation
					}
				}
			}
			.sheet(item: $captchaChallenge) { challenge in
				CaptchaSheet(challenge: challenge)
				{ submitData in
					// Resume continuation with solution or empty if nil
					if let submitData {
						captchaContinuation?.resume(returning: submitData)
					} else {
						captchaContinuation?.resume(
							returning: CaptchaSubmitData(challenge: challenge, token: ""))
					}
					captchaContinuation = nil
					captchaChallenge = nil
				}
				.frame(idealWidth: 400, idealHeight: 400)
			}
		}
		.windowStyle(.hiddenTitleBar)
	}
}

struct ContentView: View {
	var body: some View {
		#if os(iOS)
			SmallBaseplate()
		#else
			LargeBaseplate()
		#endif
	}
}

#Preview {
	ContentView()
}
