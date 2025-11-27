// CGPoint+Nodes.swift
// Nodes
//
// CGPoint extensions for node graph calculations.

import CoreGraphics

extension CGPoint {
    public var length: CGFloat {
        hypot(x, y)
    }

    public var squareLength: CGFloat {
        x * x + y * y
    }

    public var unit: CGPoint {
        self * (1.0 / length)
    }

    public func distance(from point: CGPoint) -> CGFloat {
        (self - point).length
    }

    public func angle(to other: CGPoint) -> CGFloat {
        let dx = other.x - x
        let dy = other.y - y
        let radians = atan2(dy, dx)
        let degrees = radians * 180 / .pi
        return degrees >= 0 ? degrees : degrees + 360
    }

    public func dot(_ other: CGPoint) -> CGFloat {
        x * other.x + y * other.y
    }

    // MARK: - Operators

    public static prefix func - (value: CGPoint) -> CGPoint {
        CGPoint(x: -value.x, y: -value.y)
    }

    public static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    public static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    public static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }

    public static func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }

    public static func + (lhs: CGPoint, rhs: CGSize) -> CGPoint {
        CGPoint(x: lhs.x + rhs.width, y: lhs.y + rhs.height)
    }

    public static func - (lhs: CGPoint, rhs: CGSize) -> CGPoint {
        CGPoint(x: lhs.x - rhs.width, y: lhs.y - rhs.height)
    }
}
