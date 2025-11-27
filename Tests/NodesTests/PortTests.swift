// PortTests.swift
// NodesTests
//
// Tests for Port functionality.

import Testing
import Foundation
@testable import Nodes

@Suite("Port Tests")
struct PortTests {

    @Test("NodePort initializes correctly")
    func nodePortInitializes() {
        let port = NodePort<Float>(name: "Test", kind: .inlet)

        #expect(port.name == "Test")
        #expect(port.kind == .inlet)
        #expect(port.value == nil)
        #expect(!port.published)
    }

    @Test("NodePort can store and retrieve values")
    func nodePortCanStoreValues() {
        let port = NodePort<Float>(name: "Test", kind: .inlet)

        port.value = 42.0
        #expect(port.value == 42.0)

        port.value = 3.14
        #expect(port.value == 3.14)
    }

    @Test("NodePort tracks value changes")
    func nodePortTracksValueChanges() {
        let port = NodePort<Float>(name: "Test", kind: .inlet)

        port.valueDidChange = false
        port.value = 1.0
        #expect(port.valueDidChange)
    }

    @Test("NodePort has correct portType")
    func nodePortHasCorrectPortType() {
        let floatPort = NodePort<Float>(name: "Float", kind: .inlet)
        #expect(floatPort.portType == .float)

        let intPort = NodePort<Int>(name: "Int", kind: .inlet)
        #expect(intPort.portType == .int)

        let stringPort = NodePort<String>(name: "String", kind: .inlet)
        #expect(stringPort.portType == .string)
    }

    @Test("Ports can connect")
    func portsCanConnect() {
        let graph = Graph()
        let node1 = TestNodeWithPorts()
        let node2 = TestNodeWithPorts()

        graph.addNode(node1)
        graph.addNode(node2)

        let outlet = node1.port(named: "output", as: NodePort<Float>.self)!
        let inlet = node2.port(named: "input", as: NodePort<Float>.self)!

        outlet.connect(to: inlet)

        #expect(outlet.connections.count == 1)
        #expect(inlet.connections.count == 1)
        #expect(outlet.connections.first?.id == inlet.id)
    }

    @Test("Ports can disconnect")
    func portsCanDisconnect() {
        let graph = Graph()
        let node1 = TestNodeWithPorts()
        let node2 = TestNodeWithPorts()

        graph.addNode(node1)
        graph.addNode(node2)

        let outlet = node1.port(named: "output", as: NodePort<Float>.self)!
        let inlet = node2.port(named: "input", as: NodePort<Float>.self)!

        outlet.connect(to: inlet)
        outlet.disconnect(from: inlet)

        #expect(outlet.connections.isEmpty)
        #expect(inlet.connections.isEmpty)
    }

    @Test("Connected ports transmit values")
    func connectedPortsTransmitValues() {
        let graph = Graph()
        let node1 = TestNodeWithPorts()
        let node2 = TestNodeWithPorts()

        graph.addNode(node1)
        graph.addNode(node2)

        let outlet = node1.port(named: "output", as: NodePort<Float>.self)!
        let inlet = node2.port(named: "input", as: NodePort<Float>.self)!

        outlet.connect(to: inlet)
        outlet.send(42.0)

        #expect(inlet.value == 42.0)
    }

    @Test("Inlet can only have one connection")
    func inletCanOnlyHaveOneConnection() {
        let graph = Graph()
        let node1 = TestNodeWithPorts()
        let node2 = TestNodeWithPorts()
        let node3 = TestNodeWithPorts()

        graph.addNode(node1)
        graph.addNode(node2)
        graph.addNode(node3)

        let outlet1 = node1.port(named: "output", as: NodePort<Float>.self)!
        let outlet2 = node2.port(named: "output", as: NodePort<Float>.self)!
        let inlet = node3.port(named: "input", as: NodePort<Float>.self)!

        outlet1.connect(to: inlet)
        #expect(inlet.connections.count == 1)

        outlet2.connect(to: inlet)
        #expect(inlet.connections.count == 1)
        #expect(inlet.connections.first?.id == outlet2.id)
    }

    @Test("Port published state")
    func portPublishedState() {
        let port = NodePort<Float>(name: "Test", kind: .inlet)

        #expect(!port.published)
        port.published = true
        #expect(port.published)
    }
}
