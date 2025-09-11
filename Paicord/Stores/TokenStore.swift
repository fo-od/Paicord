//
//  AuthenticationStorage.swift
//  PaiCord
//
// Created by Lakhan Lothiyi on 01/09/2025.
// Copyright © 2025 Lakhan Lothiyi.
//

import KeychainAccess
import PaicordLib
import Foundation

@Observable
final class TokenStore {
  static let keychain =  Keychain(service: "com.llsc12.Paicord.Accounts")
  
  
  /// If this is nil, there is no logged in account.
  var currentAccountID: UserSnowflake? {
    _currentAccountID ?? accounts.first?.user.id
  }
  var _currentAccountID: UserSnowflake? {
    get {
      guard let str = UserDefaults.standard.string(forKey: "TokenStore.CurrentAccountID") else { return nil }
      return .init(str)
    }
    set {
      if let newValue {
        UserDefaults.standard.set(newValue.rawValue, forKey: "TokenStore.CurrentAccountID")
      } else {
        UserDefaults.standard.removeObject(forKey: "TokenStore.CurrentAccountID")
      }
    }
  }
  
  var accounts: [AccountData] {
    didSet {
      Self.save(accounts)
    }
  }
  
  init() {
    accounts = Self.load()
  }
  
  func addAccount(token: Secret, user: DiscordUser) {
    accounts = accounts + [.init(user: user, token: token)]
  }
  
  func removeAccount(_ account: AccountData) {
    accounts = accounts.filter { $0 != account }
  }
  
  func updateProfile(for id: UserSnowflake, _ data: DiscordUser) {
    // look in accounts, find id
    guard let accIndex = accounts.firstIndex(where: { $0.user.id == id }) else { return } // user didnt exist
    var acc = accounts[accIndex]
    acc.user = data
    accounts[accIndex] = acc
  }
  
  func account(for id: UserSnowflake) -> AccountData {
    accounts.first { $0.user.id == id } ?? accounts.first! // method shouldnt be called if there isnt an id (currentaccid would be nil)
  }
  
  static func load() -> [AccountData] {
    let data = (try? keychain.getData("AccountData")) ?? .init()
    return (try? DiscordGlobalConfiguration.decoder.decode([AccountData].self, from: data)) ?? []
  }
  
  static func save(_ data: [AccountData]) {
    guard let data = try? DiscordGlobalConfiguration.encoder.encode(data) else { return }
    try? keychain.set(data, key: "AccountData")
  }
  
  struct AccountData: Codable, Equatable {
    static func == (lhs: TokenStore.AccountData, rhs: TokenStore.AccountData) -> Bool {
      lhs.user.id == rhs.user.id
    }
    
    var user: DiscordUser
    var token: Secret
  }
}
