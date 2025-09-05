//
//  LoginView.swift
//  PaiCord
//
//  Created by Lakhan Lothiyi on 05/09/2025.
//

import SDWebImageSwiftUI
import SwiftUI

struct LoginView: View {
  @State var login: String = ""
  @FocusState private var loginFocused: Bool
  @State var password: String = ""
  @FocusState private var passwordFocused: Bool

  @State var forgotPasswordPopover = false
  var body: some View {
    ZStack {
	  MeshGradientBackground()
      .frame(minWidth: 500)
      .frame(minHeight: 500)

      VStack {
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
            .background(.appBackground)
            .clipShape(.rect(cornerSize: .init(10)))
            .overlay {
              RoundedRectangle(cornerSize: .init(10))
				.stroke(loginFocused ? .primaryButton : .clear, lineWidth: 1)
                .fill(.clear)
            }
            .padding(.bottom, 10)

          Text("Password")
          TextField("", text: $password)
            .textFieldStyle(.plain)
            .padding(10)
            .frame(maxWidth: .infinity)
            .focused($passwordFocused)
            .background(.appBackground)
            .clipShape(.rect(cornerSize: .init(10)))
            .overlay {
              RoundedRectangle(cornerSize: .init(10))
				.stroke(passwordFocused ? .primaryButton : .clear, lineWidth: 1)
                .fill(.clear)
            }
          Button("Forgot your password?") {
			
          }
          .buttonStyle(.plain)
          .foregroundStyle(.hyperlink)
          .disabled(login.isEmpty)
		  .onHover { self.forgotPasswordPopover = login.isEmpty ? $0 : false }
          .popover(isPresented: $forgotPasswordPopover) {
            Text("Enter a valid login above to send a reset link!")
              .padding()
          }
          .padding(.bottom)
        }

        Button {
          // Handle login action
          print("Logging in with \(login) and \(password)")
        } label: {
          Text("Log In")
            .frame(maxWidth: .infinity)
            .padding()
            .background(.primaryButton)
            .clipShape(.rect(cornerSize: .init(10)))
            .font(.title3)
        }
        .buttonStyle(.plain)

        Spacer()
      }
      .padding(.horizontal, 20)
      .padding(.top, 20)
      .frame(maxWidth: 400)
      .frame(maxHeight: 350)
	  .background(.tabBarBackground)
      .clipShape(.rect(cornerSize: .init(10)))
	  .shadow(radius: 10)
	  .opacity(0.75)
    }
	.ignoresSafeArea()
  }
}

#Preview {
  LoginView()
}
