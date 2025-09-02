//
//  AuthenticationStorage.swift
//  PaiCord
//
//  Created by Lakhan Lothiyi on 01/09/2025.
//

import KeychainAccess
import Foundation

@Observable
class AuthenticationStorage {
	static let session = Keychain(service: Bundle.main.bundleIdentifier ?? "com.llsc12.PaiCord")
	
	init() {
		// load auth data from keychain
		
	}
	
	var accessToken: String? {
		didSet {
			
		}
	}
}
