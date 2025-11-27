// ExtensionTests.swift
// NodesTests
//
// Tests for CGPoint and CGSize extensions.

import Testing
import Foundation
import CoreGraphics
@testable import Nodes

@Suite("Extension Tests")
struct ExtensionTests {

    // MARK: - CGPoint Tests

    @Test("CGPoint length calculation")
    func cgPointLength() {
        let point = CGPoint(x: 3, y: 4)
        #expect(point.length == 5.0)
    }

    @Test("CGPoint distance calculation")
    func cgPointDistance() {
        let point1 = CGPoint(x: 0, y: 0)
        let point2 = CGPoint(x: 3, y: 4)
        #expect(point1.distance(from: point2) == 5.0)
    }

    @Test("CGPoint angle calculation")
    func cgPointAngle() {
        let origin = CGPoint(x: 0, y: 0)
        let right = CGPoint(x: 1, y: 0)
        let up = CGPoint(x: 0, y: 1)

        #expect(origin.angle(to: right) == 0)
        #expect(origin.angle(to: up) == 90)
    }

    @Test("CGPoint arithmetic operators")
    func cgPointArithmetic() {
        let a = CGPoint(x: 10, y: 20)
        let b = CGPoint(x: 5, y: 10)

        let sum = a + b
        #expect(sum.x == 15)
        #expect(sum.y == 30)

        let diff = a - b
        #expect(diff.x == 5)
        #expect(diff.y == 10)

        let scaled = a * 2.0
        #expect(scaled.x == 20)
        #expect(scaled.y == 40)

        let divided = a / 2.0
        #expect(divided.x == 5)
        #expect(divided.y == 10)
    }

    @Test("CGPoint negation")
    func cgPointNegation() {
        let point = CGPoint(x: 10, y: -20)
        let negated = -point

        #expect(negated.x == -10)
        #expect(negated.y == 20)
    }

    @Test("CGPoint with CGSize arithmetic")
    func cgPointWithCGSize() {
        let point = CGPoint(x: 10, y: 20)
        let size = CGSize(width: 5, height: 10)

        let sum = point + size
        #expect(sum.x == 15)
        #expect(sum.y == 30)

        let diff = point - size
        #expect(diff.x == 5)
        #expect(diff.y == 10)
    }

    // MARK: - CGSize Tests

    @Test("CGSize length calculation")
    func cgSizeLength() {
        let size = CGSize(width: 3, height: 4)
        #expect(size.length == 5.0)
    }

    @Test("CGSize arithmetic operators")
    func cgSizeArithmetic() {
        let a = CGSize(width: 10, height: 20)
        let b = CGSize(width: 5, height: 10)

        let sum = a + b
        #expect(sum.width == 15)
        #expect(sum.height == 30)

        let diff = a - b
        #expect(diff.width == 5)
        #expect(diff.height == 10)

        let scaled = a * 2.0
        #expect(scaled.width == 20)
        #expect(scaled.height == 40)

        let divided = a / 2.0
        #expect(divided.width == 5)
        #expect(divided.height == 10)
    }

    @Test("CGSize negation")
    func cgSizeNegation() {
        let size = CGSize(width: 10, height: -20)
        let negated = -size

        #expect(negated.width == -10)
        #expect(negated.height == 20)
    }
}
