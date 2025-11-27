// PortType.swift
// Nodes
//
// Enumeration of built-in port value types for serialization and type matching.

import Foundation
import simd

/// Describes the type of value a port carries. Used for type checking and serialization.
public indirect enum PortType: RawRepresentable, Codable, Equatable, CaseIterable, Sendable {
    public typealias RawValue = String

    case bool
    case float
    case double
    case int
    case string
    case vector2
    case vector3
    case vector4
    case quaternion
    case matrix2x2
    case matrix3x3
    case matrix4x4
    case array(element: PortType)
    case custom(name: String)

    public static var allCases: [PortType] {
        [.bool, .float, .double, .int, .string, .vector2, .vector3, .vector4,
         .quaternion, .matrix2x2, .matrix3x3, .matrix4x4]
    }

    // MARK: - Type Mapping

    /// Returns the Swift type for this port type.
    public var swiftType: Any.Type {
        switch self {
        case .bool: Bool.self
        case .float: Float.self
        case .double: Double.self
        case .int: Int.self
        case .string: String.self
        case .vector2: simd_float2.self
        case .vector3: simd_float3.self
        case .vector4: simd_float4.self
        case .quaternion: simd_quatf.self
        case .matrix2x2: simd_float2x2.self
        case .matrix3x3: simd_float3x3.self
        case .matrix4x4: simd_float4x4.self
        case .array(let element): arrayType(for: element)
        case .custom: Any.self
        }
    }

    /// Creates a PortType from a Swift metatype.
    public static func from(_ type: Any.Type) -> PortType {
        let unwrapped = unwrapOptional(type)

        switch unwrapped {
        case is Bool.Type: return .bool
        case is Float.Type: return .float
        case is Double.Type: return .double
        case is Int.Type: return .int
        case is String.Type: return .string
        case is simd_float2.Type: return .vector2
        case is simd_float3.Type: return .vector3
        case is simd_float4.Type: return .vector4
        case is simd_quatf.Type: return .quaternion
        case is simd_float2x2.Type: return .matrix2x2
        case is simd_float3x3.Type: return .matrix3x3
        case is simd_float4x4.Type: return .matrix4x4
        default:
            if let elementType = arrayElementType(of: unwrapped) {
                return .array(element: PortType.from(elementType))
            }
            return .custom(name: String(describing: unwrapped))
        }
    }

    // MARK: - RawRepresentable

    public init?(rawValue: String) {
        let s = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        switch s {
        case "Bool": self = .bool
        case "Float": self = .float
        case "Double": self = .double
        case "Int": self = .int
        case "String": self = .string
        case "Vector2": self = .vector2
        case "Vector3": self = .vector3
        case "Vector4": self = .vector4
        case "Quaternion": self = .quaternion
        case "Matrix2x2": self = .matrix2x2
        case "Matrix3x3": self = .matrix3x3
        case "Matrix4x4": self = .matrix4x4
        default:
            if s.hasPrefix("Array<"), s.hasSuffix(">") {
                let inner = String(s.dropFirst(6).dropLast(1))
                if let innerType = PortType(rawValue: inner) {
                    self = .array(element: innerType)
                    return
                }
            }
            if s.hasPrefix("Custom:") {
                self = .custom(name: String(s.dropFirst(7)))
                return
            }
            return nil
        }
    }

    public var rawValue: String {
        switch self {
        case .bool: "Bool"
        case .float: "Float"
        case .double: "Double"
        case .int: "Int"
        case .string: "String"
        case .vector2: "Vector2"
        case .vector3: "Vector3"
        case .vector4: "Vector4"
        case .quaternion: "Quaternion"
        case .matrix2x2: "Matrix2x2"
        case .matrix3x3: "Matrix3x3"
        case .matrix4x4: "Matrix4x4"
        case .array(let element): "Array<\(element.rawValue)>"
        case .custom(let name): "Custom:\(name)"
        }
    }
}

// MARK: - Private Helpers

private protocol OptionalProtocol {
    static var wrappedType: Any.Type { get }
}

extension Optional: OptionalProtocol {
    static var wrappedType: Any.Type { Wrapped.self }
}

private func unwrapOptional(_ type: Any.Type) -> Any.Type {
    (type as? OptionalProtocol.Type)?.wrappedType ?? type
}

private protocol ArrayElementProvider {
    static var elementType: Any.Type { get }
}

extension Array: ArrayElementProvider {
    static var elementType: Any.Type { Element.self }
}

extension ContiguousArray: ArrayElementProvider {
    static var elementType: Any.Type { Element.self }
}

private func arrayElementType(of type: Any.Type) -> Any.Type? {
    (type as? ArrayElementProvider.Type)?.elementType
}

private func arrayType(for element: PortType) -> Any.Type {
    switch element {
    case .bool: [Bool].self
    case .float: [Float].self
    case .double: [Double].self
    case .int: [Int].self
    case .string: [String].self
    case .vector2: [simd_float2].self
    case .vector3: [simd_float3].self
    case .vector4: [simd_float4].self
    case .quaternion: [simd_quatf].self
    case .matrix2x2: [simd_float2x2].self
    case .matrix3x3: [simd_float3x3].self
    case .matrix4x4: [simd_float4x4].self
    case .array, .custom: [Any].self
    }
}
