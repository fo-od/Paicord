//
//  PaicordAppState.swift
//  Paicord
//
//  Created by Lakhan Lothiyi on 18/09/2025.
//  Copyright © 2025 Lakhan Lothiyi.
//

import Foundation
import PaicordLib

// Will probably expand this later

@Observable
final class PaicordAppState {
	var selectedServer: GuildSnowflake? = nil
	var selectedChannel: ChannelSnowflake? = nil

	var showingError = false
	var showingErrorSheet = false
	var error: Error? = nil {
		didSet { showingError = error != nil }
	}
}
