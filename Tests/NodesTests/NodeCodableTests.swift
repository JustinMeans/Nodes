// NodeCodableTests.swift
// NodesTests
//
// Tests for Node/Graph serialization paths, dynamic port management,
// graph execution, and SelectionDirection angle mapping.

import Testing
import Foundation
@testable import Nodes

// MARK: - Helpers

private final class SimpleProcessorNode: Node, @unchecked Sendable {
    var executeCallCount = 0

    override class var name: String { "SimpleProcessor" }
    override class var nodeExecutionMode: NodeExecutionMode { .processor }
    override class var nodeTimeMode: NodeTimeMode { .onDirty }

    override func execute() {
        executeCallCount += 1
    }
}

private final class DualPortNode: Node, @unchecked Sendable {
    override class var name: String { "DualPort" }
    override class var nodeExecutionMode: NodeExecutionMode { .processor }
    override class var nodeTimeMode: NodeTimeMode { .onDirty }

    override class func registerPorts() -> [(name: String, port: Nodes.Port)] {
        [
            ("input", NodePort<Float>(name: "Input", kind: .inlet)),
            ("output", NodePort<Float>(name: "Output", kind: .outlet))
        ]
    }
}

// MARK: - Node Codable Tests

@Suite("Node Codable")
struct NodeCodableTests {

    @Test("Node encodes and decodes id and offset")
    func nodeEncodesAndDecodesIdentity() throws {
        let node = SimpleProcessorNode()
        node.offset = CGSize(width: 42, height: 99)

        let encoder = JSONEncoder()
        let data = try encoder.encode(node)

        let decoder = JSONDecoder()
        let restored = try decoder.decode(SimpleProcessorNode.self, from: data)

        #expect(restored.id == node.id)
        #expect(restored.offset.width == 42)
        #expect(restored.offset.height == 99)
    }

    @Test("Node decode preserves registered ports")
    func nodeDecodePreservesPorts() throws {
        let node = DualPortNode()
        let encoder = JSONEncoder()
        let data = try encoder.encode(node)

        let decoder = JSONDecoder()
        let restored = try decoder.decode(DualPortNode.self, from: data)

        #expect(restored.ports.count == 2)
        let input = restored.port(named: "input", as: NodePort<Float>.self)
        let output = restored.port(named: "output", as: NodePort<Float>.self)
        #expect(input != nil)
        #expect(input?.kind == .inlet)
        #expect(output != nil)
        #expect(output?.kind == .outlet)
    }

    @Test("Node encode produces valid JSON with expected keys")
    func nodeEncodeProducesJSON() throws {
        let node = SimpleProcessorNode()
        node.offset = CGSize(width: 10, height: 20)

        let encoder = JSONEncoder()
        let data = try encoder.encode(node)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["id"] != nil)
        #expect(json?["nodeOffset"] != nil)
    }
}

// MARK: - Dynamic Port Tests

@Suite("Dynamic Port Management")
struct DynamicPortTests {

    @Test("Node can add dynamic ports at runtime")
    func nodeCanAddDynamicPorts() {
        let node = SimpleProcessorNode()
        #expect(node.ports.isEmpty)

        let extra = NodePort<Int>(name: "Dynamic", kind: .inlet)
        node.addDynamicPort(extra)

        #expect(node.ports.count == 1)
        let found = node.port(named: "Dynamic", as: NodePort<Int>.self)
        #expect(found != nil)
        #expect(found?.kind == .inlet)
    }

    @Test("Node can remove a dynamic port")
    func nodeCanRemoveDynamicPort() {
        let node = SimpleProcessorNode()
        let extra = NodePort<Int>(name: "Dynamic", kind: .inlet)
        node.addDynamicPort(extra)
        #expect(node.ports.count == 1)

        node.removePort(extra)
        #expect(node.ports.isEmpty)
    }

    @Test("Removing a dynamic port disconnects it first")
    func removingPortDisconnects() {
        let graph = Graph()
        let nodeA = DualPortNode()
        let nodeB = DualPortNode()
        graph.addNode(nodeA)
        graph.addNode(nodeB)

        let outlet = nodeA.port(named: "output", as: NodePort<Float>.self)!
        let inlet = nodeB.port(named: "input", as: NodePort<Float>.self)!
        outlet.connect(to: inlet)
        #expect(outlet.connections.count == 1)

        nodeA.removePort(outlet)
        #expect(outlet.connections.isEmpty)
        #expect(inlet.connections.isEmpty)
    }
}

// MARK: - Graph Execution Tests

@Suite("Graph Execution")
struct GraphExecutionTests {

    @Test("Graph execute calls execute on dirty nodes")
    func graphExecuteCallsNodeExecute() {
        let graph = Graph()
        let node = SimpleProcessorNode()
        graph.addNode(node)

        #expect(node.isDirty)
        graph.execute()

        #expect(node.executeCallCount == 1)
    }

    @Test("Graph execute marks nodes clean afterwards")
    func graphExecuteMarksNodesClean() {
        let graph = Graph()
        let node = SimpleProcessorNode()
        graph.addNode(node)

        graph.execute()

        #expect(!node.isDirty)
    }

    @Test("Graph execute skips already-clean nodes")
    func graphExecuteSkipsCleanNodes() {
        let graph = Graph()
        let node = SimpleProcessorNode()
        graph.addNode(node)

        node.markClean()
        graph.execute()

        #expect(node.executeCallCount == 0)
    }

    @Test("Graph execute runs all dirty nodes")
    func graphExecuteRunsAllDirtyNodes() {
        let graph = Graph()
        let nodeA = SimpleProcessorNode()
        let nodeB = SimpleProcessorNode()
        graph.addNode(nodeA)
        graph.addNode(nodeB)

        graph.execute()

        #expect(nodeA.executeCallCount == 1)
        #expect(nodeB.executeCallCount == 1)
        #expect(!nodeA.isDirty)
        #expect(!nodeB.isDirty)
    }
}

// MARK: - SelectionDirection Tests

@Suite("Graph SelectionDirection")
struct SelectionDirectionTests {

    @Test("SelectionDirection right maps to angles near 0 and 360")
    func selectionDirectionRight() {
        #expect(Graph.SelectionDirection.from(angle: 0) == .right)
        #expect(Graph.SelectionDirection.from(angle: 10) == .right)
        #expect(Graph.SelectionDirection.from(angle: 350) == .right)
        #expect(Graph.SelectionDirection.from(angle: 359) == .right)
    }

    @Test("SelectionDirection up maps to angles 45-135")
    func selectionDirectionUp() {
        #expect(Graph.SelectionDirection.from(angle: 45) == .up)
        #expect(Graph.SelectionDirection.from(angle: 90) == .up)
        #expect(Graph.SelectionDirection.from(angle: 134) == .up)
    }

    @Test("SelectionDirection left maps to angles 135-225")
    func selectionDirectionLeft() {
        #expect(Graph.SelectionDirection.from(angle: 135) == .left)
        #expect(Graph.SelectionDirection.from(angle: 180) == .left)
        #expect(Graph.SelectionDirection.from(angle: 224) == .left)
    }

    @Test("SelectionDirection down maps to angles 225-315")
    func selectionDirectionDown() {
        #expect(Graph.SelectionDirection.from(angle: 225) == .down)
        #expect(Graph.SelectionDirection.from(angle: 270) == .down)
        #expect(Graph.SelectionDirection.from(angle: 314) == .down)
    }

    @Test("SelectionDirection handles negative angle input via truncatingRemainder")
    func selectionDirectionNegativeAngles() {
        // -90 mod 360 = 270 in real math, but Swift truncatingRemainder keeps sign
        // The implementation adds 360 when result is negative, so -90 -> 270 -> down
        #expect(Graph.SelectionDirection.from(angle: -90) == .down)
        #expect(Graph.SelectionDirection.from(angle: -180) == .left)
    }
}

// MARK: - PortRegistry Snapshot Tests

@Suite("PortRegistry Snapshot")
struct PortRegistrySnapshotTests {

    @Test("PortRegistry encode produces one snapshot per port")
    func portRegistryEncodesSnapshots() throws {
        let node = DualPortNode()
        let snapshots = try node.ports.isEmpty ? [] : {
            // Access registry through the node's encode path
            let encoder = JSONEncoder()
            let data = try encoder.encode(node)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return (json?["ports"] as? [[String: Any]]) ?? []
        }()

        #expect(snapshots.count == 2)
    }

    @Test("PortRegistry Snapshot has correct portType for each port")
    func portRegistrySnapshotHasCorrectPortType() throws {
        let node = DualPortNode()
        let encoder = JSONEncoder()
        let data = try encoder.encode(node)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let ports = json?["ports"] as? [[String: Any]] ?? []

        #expect(ports.count == 2)
        let portTypes = ports.compactMap { $0["portType"] as? String }
        #expect(portTypes.contains("Float"))
    }
}
