//
//  LoginView.swift
//  PaiCord
//
//  Created by Lakhan Lothiyi on 05/09/2025.
//

import SDWebImageSwiftUI
import SwiftUI
import DiscordClientLib

struct LoginView: View {
  @State var loginClient: DefaultDiscordClient!
  @AppStorage("Authentication.Fingerprint") var fingerprint: String?
  
//  @State var loginTask: Task<>
  
  @State var login: String = ""
  @FocusState private var loginFocused: Bool
  @State var password: String = ""
  @FocusState private var passwordFocused: Bool

  @State var forgotPasswordPopover = false
  @State var forgotPasswordSent = false
  @State var error: Error? = nil
  
  var body: some View {
    ZStack {
	  MeshGradientBackground()
      .frame(minWidth: 500)
      .frame(minHeight: 500)

      if loginClient != nil {
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
              .background(.appBackground.opacity(0.75))
              .clipShape(.rounded)
              .overlay {
                RoundedRectangle()
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
              .background(.appBackground.opacity(0.75))
              .clipShape(.rect(cornerSize: .init(10)))
              .overlay {
                RoundedRectangle()
                  .stroke(passwordFocused ? .primaryButton : .clear, lineWidth: 1)
                  .fill(.clear)
              }
            Button("Forgot your password?") {
              Task {
                do {
                  let login = self.login
                  try await self.loginClient.forgotPassword(login: login).guardSuccess()
                  self.forgotPasswordSent.toggle()
                } catch {
                  self.error = error
                }
              }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.hyperlink)
            .disabled(login.isEmpty)
            .onHover { self.forgotPasswordPopover = login.isEmpty ? $0 : false }
            .popover(isPresented: $forgotPasswordPopover) {
              Text("Enter a valid login above to send a reset link!")
                .padding()
            }
            .alert("Forgot Password", isPresented: $forgotPasswordSent, actions: {
              Button("Dismiss", role: .cancel) { }
            }, message: { Text("You will receive a password reset form shortly!") })
            .padding(.bottom)
            
            if let error {
              Text(error.localizedDescription)
                .foregroundStyle(.red)
                .padding(.top, -15)
            }
          }
          
          Button {
            Task {
              do {
                let login = self.login
                let password = self.password
                guard let fingerprint else {
                  throw "A tracking fingerprint couldn't be generated."
                }
                
                throw "meow"
              } catch {
                self.error = error
              }
            }
          } label: {
            Text("Log In")
              .frame(maxWidth: .infinity)
              .padding()
              .background(.primaryButton)
              .clipShape(.rounded)
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
        .clipShape(.rounded)
        .shadow(radius: 10)
        .opacity(0.75)
        .transition(.scale(scale: 0.8).combined(with: .opacity))
      }
    }
	.ignoresSafeArea()
    .task {
      let loginClient = await DefaultDiscordClient(token: .none)
      defer { self.loginClient = loginClient }
      do {
        if self.fingerprint == nil {
          let request = try await loginClient.getExperiments()
          try request.guardSuccess()
          let data = try request.decode()
          self.fingerprint = data.fingerprint
        }
      } catch {
        self.error = error
      }
    }
    .animation(.default, value: loginClient == nil)
  }
}

#Preview {
  LoginView()
}
