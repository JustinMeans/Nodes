// PortTypeTests.swift
// NodesTests
//
// Tests for PortType functionality.

import Testing
import Foundation
import simd
@testable import Nodes

@Suite("PortType Tests")
struct PortTypeTests {

    @Test("PortType from Swift types")
    func portTypeFromSwiftTypes() {
        #expect(PortType.from(Bool.self) == .bool)
        #expect(PortType.from(Float.self) == .float)
        #expect(PortType.from(Double.self) == .double)
        #expect(PortType.from(Int.self) == .int)
        #expect(PortType.from(String.self) == .string)
        #expect(PortType.from(simd_float2.self) == .vector2)
        #expect(PortType.from(simd_float3.self) == .vector3)
        #expect(PortType.from(simd_float4.self) == .vector4)
        #expect(PortType.from(simd_quatf.self) == .quaternion)
    }

    @Test("PortType rawValue roundtrip")
    func portTypeRawValueRoundtrip() {
        for portType in PortType.allCases {
            let raw = portType.rawValue
            let restored = PortType(rawValue: raw)
            #expect(restored == portType)
        }
    }

    @Test("PortType swiftType mapping")
    func portTypeSwiftTypeMapping() {
        // Test type mappings using ObjectIdentifier for comparison
        #expect(ObjectIdentifier(PortType.bool.swiftType) == ObjectIdentifier(Bool.self))
        #expect(ObjectIdentifier(PortType.float.swiftType) == ObjectIdentifier(Float.self))
        #expect(ObjectIdentifier(PortType.double.swiftType) == ObjectIdentifier(Double.self))
        #expect(ObjectIdentifier(PortType.int.swiftType) == ObjectIdentifier(Int.self))
        #expect(ObjectIdentifier(PortType.string.swiftType) == ObjectIdentifier(String.self))
        #expect(ObjectIdentifier(PortType.vector2.swiftType) == ObjectIdentifier(simd_float2.self))
        #expect(ObjectIdentifier(PortType.vector3.swiftType) == ObjectIdentifier(simd_float3.self))
        #expect(ObjectIdentifier(PortType.vector4.swiftType) == ObjectIdentifier(simd_float4.self))
        #expect(ObjectIdentifier(PortType.quaternion.swiftType) == ObjectIdentifier(simd_quatf.self))
    }

    @Test("PortType array handling")
    func portTypeArrayHandling() {
        let arrayType = PortType.from([Float].self)
        #expect(arrayType == .array(element: .float))

        let nestedType = PortType.array(element: .int)
        #expect(nestedType.rawValue == "Array<Int>")
    }

    @Test("PortType custom type handling")
    func portTypeCustomTypeHandling() {
        struct CustomType: PortValue {}
        let customType = PortType.from(CustomType.self)

        if case .custom(let name) = customType {
            #expect(name.contains("CustomType"))
        } else {
            Issue.record("Expected custom type")
        }
    }

    @Test("PortType rawValue roundtrip for array and custom cases")
    func portTypeRawValueRoundtripParametric() {
        // `allCases` deliberately omits the parametric `.array` and `.custom`
        // cases, yet both are serialized via `PortRegistry.Snapshot`. Lock in
        // their `rawValue` <-> `init?(rawValue:)` round-trip explicitly.
        let cases: [PortType] = [
            .array(element: .float),
            .array(element: .string),
            .array(element: .vector3),
            .array(element: .array(element: .int)),
            .array(element: .custom(name: "Foo")),
            .custom(name: "MyType"),
            .custom(name: "Module.Nested")
        ]

        for portType in cases {
            let raw = portType.rawValue
            let restored = PortType(rawValue: raw)
            #expect(restored == portType, "Round-trip failed for \(raw)")
        }
    }

    @Test("PortType survives Codable round-trip including parametric cases")
    func portTypeCodableRoundtrip() throws {
        let cases: [PortType] = PortType.allCases + [
            .array(element: .double),
            .array(element: .array(element: .bool)),
            .custom(name: "Custom")
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for portType in cases {
            let data = try encoder.encode(portType)
            let restored = try decoder.decode(PortType.self, from: data)
            #expect(restored == portType)
        }
    }
}
