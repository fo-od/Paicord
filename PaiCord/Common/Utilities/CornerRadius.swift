//
//  CornerRadius.swift
//  PaiCord
//
// Created by Lakhan Lothiyi on 02/09/2025.
// Copyright © 2025 Lakhan Lothiyi.
//

import SwiftUI

#if canImport(UIKit)
extension View {
	func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
		clipShape(RoundedCorner(radius: radius, corners: corners))
	}
}

struct RoundedCorner: Shape {
	let radius: CGFloat
	let corners: UIRectCorner

	init(radius: CGFloat = .infinity, corners: UIRectCorner = .allCorners) {
		self.radius = radius
		self.corners = corners
	}

	func path(in rect: CGRect) -> Path {
		let path = UIBezierPath(
			roundedRect: rect,
			byRoundingCorners: corners,
			cornerRadii: CGSize(width: radius, height: radius)
		)
		return Path(path.cgPath)
	}
}
#elseif canImport(AppKit)

struct RoundedCorner: Shape {
	let radius: CGFloat
	let corners: CACornerMask

	init(radius: CGFloat = .infinity, corners: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]) {
		self.radius = radius
		self.corners = corners
	}

	func path(in rect: CGRect) -> Path {
		let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
		return Path(path.cgPath)
	}
}
#endif
