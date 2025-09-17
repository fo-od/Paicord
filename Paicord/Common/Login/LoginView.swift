//
//  LoginView.swift
//  PaiCord
//
// Created by Lakhan Lothiyi on 05/09/2025.
// Copyright © 2025 Lakhan Lothiyi.
//

import PaicordLib
import SDWebImageSwiftUI
import SwiftUI

struct LoginView: View {
	@Environment(GatewayStore.self) var gw
	@Environment(PaicordAppState.self) var appState

	@State var loginClient: (any DiscordClient)! = nil
	@AppStorage("Authentication.Fingerprint") var fingerprint: String?

	@State var addingNewAccount = false

	@State var login: String = ""
	@FocusState private var loginFocused: Bool
	@State var password: String = ""
	@FocusState private var passwordFocused: Bool

	@State var handleMFA: UserAuthentication? = nil

	@State var forgotPasswordPopover = false
	@State var forgotPasswordSent = false

	var body: some View {
		ZStack {
			MeshGradientBackground()
				.frame(maxWidth: .infinity, maxHeight: .infinity)

			if loginClient != nil {
				VStack {
					// if we have no accounts, show login.
					// if we have accounts, show a list or show login if addingNewAccount is true
					if gw.accounts.accounts.isEmpty || addingNewAccount {
						if let handleMFA, let fingerprint {
							MFAView(
								loginClient: loginClient, fingerprint: fingerprint,
								authentication: handleMFA
							) { token in
								defer { self.handleMFA = nil }
								if let token {
									Task {
										do {
											let user = try await TokenStore.getSelf(token: token)
											gw.accounts.addAccount(token: token, user: user)
										} catch {
											self.appState.error = error
										}
									}
								}
							}
						} else {
							loginForm
						}
					} else {
						accountPicker
					}
				}
				.padding(20)
				.frame(maxWidth: 400)
				.background(.tabBarBackground.opacity(0.75))
				.clipShape(.rounded)
				.shadow(radius: 10)
				.padding(5)
				.transition(.scale(scale: 0.8).combined(with: .opacity))
			}
		}
		.ignoresSafeArea()
		.task {
			let loginClient = gw.client
			defer { self.loginClient = loginClient }
			do {
				if self.fingerprint == nil {
					let request = try await loginClient.getExperiments()
					try request.guardSuccess()
					let data = try request.decode()
					self.fingerprint = data.fingerprint
				}
			} catch {
				self.appState.error = error
			}
		}
		.animation(.default, value: loginClient == nil)
		.animation(.default, value: handleMFA == nil)
		.animation(.default, value: gw.accounts.accounts.isEmpty)
		.animation(.default, value: addingNewAccount)
	}

	@ViewBuilder var loginForm: some View {
		Text("Welcome Back!")
			.font(.largeTitle)
			.padding(.bottom, 4)
		Text("We're so excited to see you again!")
			.padding(.bottom)

		VStack(alignment: .leading, spacing: 5) {
			Text("Email or Phone Number")
			TextField("", text: $login)
				.textFieldStyle(.plain)
				.padding(10)
				.frame(maxWidth: .infinity)
				.focused($loginFocused)
				.background(.appBackground.opacity(0.75))
				.clipShape(.rounded)
				.overlay {
					RoundedRectangle()
						.stroke(loginFocused ? .primaryButton : .clear, lineWidth: 1)
						.fill(.clear)
				}
				.padding(.bottom, 10)

			Text("Password")
			SecureField("", text: $password)
				.textFieldStyle(.plain)
				.padding(10)
				.frame(maxWidth: .infinity)
				.focused($passwordFocused)
				.background(.appBackground.opacity(0.75))
				.clipShape(.rect(cornerSize: .init(10)))
				.overlay {
					RoundedRectangle()
						.stroke(
							passwordFocused ? .primaryButton : .clear, lineWidth: 1
						)
						.fill(.clear)
				}

			AsyncButton {
				guard let fingerprint else {
					throw "A tracking fingerprint couldn't be generated."
				}
				let login = self.login
				let res = try await self.loginClient.forgotPassword(
					fingerprint: fingerprint, login: login
				)
				if let error = res.asError() {
					throw error
				}
				self.forgotPasswordSent.toggle()
			} catch: { error in
				self.appState.error = error
			} label: {
				Text("Forgot your password?")
			}
			.buttonStyle(.borderless)
			.foregroundStyle(.hyperlink)
			.disabled(login.isEmpty)
			.onHover { self.forgotPasswordPopover = login.isEmpty ? $0 : false }
			.popover(isPresented: $forgotPasswordPopover) {
				Text("Enter a valid login above to send a reset link!")
					.padding()
			}
			.alert(
				"Forgot Password", isPresented: $forgotPasswordSent,
				actions: {
					Button("Dismiss", role: .cancel) {}
				},
				message: {
					Text("You will receive a password reset form shortly!")
				}
			)
			.padding(.bottom, 10)
		}

		AsyncButton {
			let login = self.login
			let password = self.password
			guard let fingerprint else {
				throw "A tracking fingerprint couldn't be generated."
			}

			let request = try await self.loginClient.userLogin(
				login: login, password: password, fingerprint: fingerprint)
			if let error = request.asError() {
				throw error
			}
			let data = try request.decode()
			if data.mfa == true {
				// handle mfa
				self.handleMFA = data
			} else {
				// token should exist then
				guard let token = data.token else {
					throw
						"No authentication token was sent despite MFA not being required."
				}

				let user = try await TokenStore.getSelf(token: token)
				gw.accounts.addAccount(token: token, user: user)
				// the app will switch to the main view automatically
			}

		} catch: { error in
			self.appState.error = error
		} label: {
			Text("Log In")
				.frame(maxWidth: .infinity)
				.padding(10)
				.background(.primaryButton)
				.clipShape(.rounded)
				.font(.title3)
		}
		.buttonStyle(.borderless)
	}

	@ViewBuilder var accountPicker: some View {
		Text("Choose an account")
			.font(.largeTitle)
			.padding(.bottom, 4)
		Text("Select an account to continue or add a new one.")
			.padding(.bottom)

		VStack(spacing: 10) {
			ScrollView {
				VStack(spacing: 10) {
					ForEach(gw.accounts.accounts) { account in
						Button {
							gw.accounts.currentAccountID = account.user.id
						} label: {
							HStack {
								Text(account.user.username)
									.font(.title3)
								Spacer()
							}
							.padding(10)
							.frame(maxWidth: .infinity)
							.background(.primaryButtonBackground)
							.clipShape(.rounded)
						}
						.buttonStyle(.borderless)
					}
				}
			}
			.frame(maxHeight: 200)

			Button {
				withAnimation {
					self.addingNewAccount = true
				}
			} label: {
				HStack {
					Image(systemName: "plus")
					Text("Add Account")
						.font(.title3)
				}
				.frame(maxWidth: .infinity)
				.padding(10)
				.background(.primaryButton)
				.clipShape(.rounded)
			}
			.buttonStyle(.borderless)
			.padding(.top, 10)
		}
	}
}

struct MFAView: View {
	let authentication: UserAuthentication
	let onFinish: (Secret?) -> Void
	let options: [Payloads.MFASubmitData.MFAKind]
	let fingerprint: String
	let loginClient: any DiscordClient

	init(
		loginClient: any DiscordClient, fingerprint: String,
		authentication: UserAuthentication, onFinish: @escaping (Secret?) -> Void
	) {
		self.loginClient = loginClient
		self.fingerprint = fingerprint
		self.authentication = authentication
		self.onFinish = onFinish
		self.options = Self.Options(from: authentication)
	}

	@Environment(PaicordAppState.self) var appState

	@State var mfaTask: Task<Void, Never>? = nil
	@State var taskInProgress: Bool = false

	@State var chosenMethod: Payloads.MFASubmitData.MFAKind? = nil
	@State var input: String = ""

	var body: some View {
		ZStack {
			VStack {
				Text("Multi-Factor Authentication")
					.font(.title2)
					.bold()
				Text("Login requires MFA to continue.")

				VStack {
					if chosenMethod == nil {
						ForEach(options, id: \.self) { method in
							Button {
								chosenMethod = method
							} label: {
								userFriendlyName(for: method)
									.frame(maxWidth: .infinity)
									.padding(10)
									.background(.primaryButton)
									.clipShape(.rounded)
									.font(.title3)
							}
							.buttonStyle(.borderless)
						}
						.transition(.offset(x: -100).combined(with: .opacity))
					}
					if chosenMethod != nil {
						form
							.transition(.offset(x: 100).combined(with: .opacity))
					}
				}
				.padding(25)
			}
		}
		.padding()
		.padding(.top, 15)
		.minHeight(200)
		.maxWidth(.infinity)
		.overlay(alignment: .topLeading) {
			Button {
				if chosenMethod == nil {
					// cancel
					onFinish(nil)
				} else {
					// go back to choosing method
					chosenMethod = nil
					input = ""
				}
			} label: {
				// chevron left
				Image(systemName: chosenMethod != nil ? "chevron.left" : "xmark")
					.padding(10)
					.background(.primaryButtonBackground)
					.clipShape(.circle)
					.contentTransition(.symbolEffect(.replace))
			}
			.buttonStyle(.borderless)
		}
		.animation(.default, value: chosenMethod == nil)
	}

	func userFriendlyName(for type: Payloads.MFASubmitData.MFAKind) -> (
		some View
	)? {
		return switch type {
		case .sms:
			Label("SMS", systemImage: "message")
		case .totp:
			Label("Authenticator App", systemImage: "lock.rotation")
		case .backup:
			Label("Backup Code", systemImage: "key")
		default: Label("Unimplemented", systemImage: "key")
		}
	}

	@ViewBuilder var form: some View {
		VStack {
			switch chosenMethod {
			case .totp:
				VStack {
					Text("Enter your authentication code")
						.foregroundStyle(.secondary)
						.font(.caption)

					SixDigitInput(input: $input) {
						let input = $0
						self.taskInProgress = true
						self.mfaTask = .init {
							defer { self.taskInProgress = false }
							do {
								let req = try await loginClient.verifyMFALogin(
									type: chosenMethod!,
									code: input, ticket: authentication.ticket!,
									fingerprint: fingerprint)
								if let error = req.asError() {
									throw error
								}
								let data = try req.decode()
								guard let token = data.token else {
									throw
										"No authentication token was sent despite MFA being completed."
								}
								onFinish(token)
							} catch {
								self.appState.error = error
							}
						}
					}
					.disabled(taskInProgress)
				}
			default:
				Text("wip bro go do totp")
			}
		}
	}

	static func Options(from auth: UserAuthentication) -> [Payloads.MFASubmitData
		.MFAKind]
	{
		var options: [Payloads.MFASubmitData.MFAKind] = []
		if auth.totp == true { options.append(.totp) }
		if auth.backup == true { options.append(.backup) }
		if auth.sms == true { options.append(.sms) }
		return options
	}
}

#Preview {
	LoginView()
}
