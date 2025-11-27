// PortValue.swift
// Nodes
//
// Generic protocol for values that can be transmitted through ports.

import Foundation
import simd

/// Protocol for types that can be sent through node ports.
/// Conform your custom types to this protocol to use them in the node graph.
public protocol PortValue: Equatable, Sendable {}

// MARK: - Standard Library Conformances

extension Bool: PortValue {}
extension Float: PortValue {}
extension Double: PortValue {}
extension Int: PortValue {}
extension String: PortValue {}

// MARK: - SIMD Conformances

extension simd_float2: PortValue {}
extension simd_float3: PortValue {}
extension simd_float4: PortValue {}
extension simd_quatf: PortValue {}
extension simd_float2x2: PortValue {}
extension simd_float3x3: PortValue {}
extension simd_float4x4: PortValue {}

// MARK: - Collection Conformances

extension Array: PortValue where Element: PortValue {}
extension ContiguousArray: PortValue where Element: PortValue {}
