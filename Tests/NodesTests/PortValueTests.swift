// PortValueTests.swift
// NodesTests
//
// Tests for PortValue protocol conformance.

import Testing
import Foundation
import simd
@testable import Nodes

@Suite("PortValue Tests")
struct PortValueTests {

    @Test("Standard types conform to PortValue and can be used in ports")
    func standardTypesConformToPortValue() {
        let boolPort = NodePort<Bool>(name: "Bool", kind: .inlet)
        boolPort.value = true
        #expect(boolPort.value == true)

        let floatPort = NodePort<Float>(name: "Float", kind: .inlet)
        floatPort.value = 42.0
        #expect(floatPort.value == 42.0)

        let doublePort = NodePort<Double>(name: "Double", kind: .inlet)
        doublePort.value = 3.14159
        #expect(doublePort.value == 3.14159)

        let intPort = NodePort<Int>(name: "Int", kind: .inlet)
        intPort.value = 42
        #expect(intPort.value == 42)

        let stringPort = NodePort<String>(name: "String", kind: .inlet)
        stringPort.value = "hello"
        #expect(stringPort.value == "hello")
    }

    @Test("SIMD types conform to PortValue and can be used in ports")
    func simdTypesConformToPortValue() {
        let vec2Port = NodePort<simd_float2>(name: "Vec2", kind: .inlet)
        vec2Port.value = simd_float2(1, 2)
        #expect(vec2Port.value?.x == 1)
        #expect(vec2Port.value?.y == 2)

        let vec3Port = NodePort<simd_float3>(name: "Vec3", kind: .inlet)
        vec3Port.value = simd_float3(1, 2, 3)
        #expect(vec3Port.value?.x == 1)
        #expect(vec3Port.value?.z == 3)

        let vec4Port = NodePort<simd_float4>(name: "Vec4", kind: .inlet)
        vec4Port.value = simd_float4(1, 2, 3, 4)
        #expect(vec4Port.value?.w == 4)

        let quatPort = NodePort<simd_quatf>(name: "Quat", kind: .inlet)
        quatPort.value = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
        #expect(quatPort.value?.real == 1)
    }

    @Test("Arrays of PortValue conform to PortValue")
    func arraysConformToPortValue() {
        let floatArrayPort = NodePort<[Float]>(name: "FloatArray", kind: .inlet)
        floatArrayPort.value = [1.0, 2.0, 3.0]
        #expect(floatArrayPort.value?.count == 3)
        #expect(floatArrayPort.value?[1] == 2.0)

        let intArrayPort = NodePort<[Int]>(name: "IntArray", kind: .inlet)
        intArrayPort.value = [1, 2, 3]
        #expect(intArrayPort.value?.count == 3)

        let stringArrayPort = NodePort<[String]>(name: "StringArray", kind: .inlet)
        stringArrayPort.value = ["a", "b", "c"]
        #expect(stringArrayPort.value?[0] == "a")
    }

    @Test("Custom types can conform to PortValue")
    func customTypesCanConform() {
        struct MyCustomType: PortValue {
            var value: Int
        }

        let customPort = NodePort<MyCustomType>(name: "Custom", kind: .inlet)
        customPort.value = MyCustomType(value: 42)
        #expect(customPort.value?.value == 42)
    }

    @Test("PortValue types are Equatable")
    func portValueTypesAreEquatable() {
        let port1 = NodePort<Float>(name: "Port1", kind: .inlet)
        let port2 = NodePort<Float>(name: "Port2", kind: .inlet)

        port1.value = 42.0
        port2.value = 42.0
        #expect(port1.value == port2.value)

        port2.value = 43.0
        #expect(port1.value != port2.value)
    }

    @Test("PortValue types correctly identify their PortType")
    func portValueTypesIdentifyPortType() {
        let boolPort = NodePort<Bool>(name: "Bool", kind: .inlet)
        #expect(boolPort.portType == .bool)

        let floatPort = NodePort<Float>(name: "Float", kind: .inlet)
        #expect(floatPort.portType == .float)

        let vec3Port = NodePort<simd_float3>(name: "Vec3", kind: .inlet)
        #expect(vec3Port.portType == .vector3)

        let arrayPort = NodePort<[Float]>(name: "Array", kind: .inlet)
        #expect(arrayPort.portType == .array(element: .float))
    }
}
