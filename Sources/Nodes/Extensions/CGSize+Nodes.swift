// CGSize+Nodes.swift
// Nodes
//
// CGSize extensions for node graph calculations.

import CoreGraphics
import SwiftUI

extension CGSize {
    public var length: CGFloat {
        hypot(width, height)
    }

    public var squareLength: CGFloat {
        width * width + height * height
    }

    // MARK: - Operators

    public static prefix func - (value: CGSize) -> CGSize {
        CGSize(width: -value.width, height: -value.height)
    }

    public static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }

    public static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }

    public static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }

    public static func / (lhs: CGSize, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
    }

    public static func + (lhs: CGSize, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.width + rhs.x, y: lhs.height + rhs.y)
    }

    public static func + (lhs: CGSize, rhs: CGVector) -> CGSize {
        CGSize(width: lhs.width + rhs.dx, height: lhs.height + rhs.dy)
    }
}
