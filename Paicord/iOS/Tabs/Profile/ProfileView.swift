//
//  ProfileView.swift
//  PaiCord
//
// Created by Lakhan Lothiyi on 31/08/2025.
// Copyright © 2025 Lakhan Lothiyi.
//

import SwiftUI

struct ProfileView: View {
	@Environment(GatewayStore.self) var gs
		var body: some View {
				VStack {
					Text("Profile View")
					
					AsyncButton("Log out") {
						if let current = gs.accounts.currentAccount {
							gs.accounts.removeAccount(current)
							await gs.logOut()
						}
					} catch: {
						print("failed to logout: \(String(describing: $0))")
					}
				}
		}
}
