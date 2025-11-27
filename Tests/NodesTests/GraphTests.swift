// GraphTests.swift
// NodesTests
//
// Tests for Graph functionality.

import Testing
import Foundation
@testable import Nodes

@Suite("Graph Tests")
struct GraphTests {

    @Test("Graph initializes with empty nodes")
    func graphInitializesEmpty() {
        let graph = Graph()
        #expect(graph.nodes.isEmpty)
        #expect(graph.version == .v1)
    }

    @Test("Graph can add nodes")
    func graphCanAddNodes() {
        let graph = Graph()
        let node = TestNode()

        graph.addNode(node)

        #expect(graph.nodes.count == 1)
        #expect(graph.nodes.first?.id == node.id)
        #expect(node.graph === graph)
    }

    @Test("Graph can delete nodes")
    func graphCanDeleteNodes() {
        let graph = Graph()
        let node = TestNode()

        graph.addNode(node)
        #expect(graph.nodes.count == 1)

        graph.delete(node: node)
        #expect(graph.nodes.isEmpty)
    }

    @Test("Graph can find node by ID")
    func graphCanFindNodeByID() {
        let graph = Graph()
        let node1 = TestNode()
        let node2 = TestNode()

        graph.addNode(node1)
        graph.addNode(node2)

        let found = graph.node(forID: node1.id)
        #expect(found === node1)
    }

    @Test("Graph can find port by ID")
    func graphCanFindPortByID() {
        let graph = Graph()
        let node = TestNodeWithPorts()

        graph.addNode(node)

        let port = node.ports.first!
        let found = graph.port(forID: port.id)
        #expect(found === port)
    }

    @Test("Graph selection works")
    func graphSelectionWorks() {
        let graph = Graph()
        let node1 = TestNode()
        let node2 = TestNode()

        graph.addNode(node1)
        graph.addNode(node2)

        graph.selectNode(node: node1, expandSelection: false)
        #expect(node1.isSelected)
        #expect(!node2.isSelected)

        graph.selectNode(node: node2, expandSelection: true)
        #expect(node1.isSelected)
        #expect(node2.isSelected)

        graph.deselectAllNodes()
        #expect(!node1.isSelected)
        #expect(!node2.isSelected)
    }

    @Test("Graph needsExecution reflects dirty state")
    func graphNeedsExecution() {
        let graph = Graph()
        let node = TestNode()

        graph.addNode(node)
        #expect(graph.needsExecution)

        node.markClean()
        #expect(!graph.needsExecution)

        node.markDirty()
        #expect(graph.needsExecution)
    }
}

// MARK: - Test Helpers

final class TestNode: Node, @unchecked Sendable {
    override class var name: String { "Test Node" }
    override class var nodeExecutionMode: NodeExecutionMode { .processor }
    override class var nodeTimeMode: NodeTimeMode { .onDirty }
}

final class TestNodeWithPorts: Node, @unchecked Sendable {
    override class var name: String { "Test Node With Ports" }
    override class var nodeExecutionMode: NodeExecutionMode { .processor }
    override class var nodeTimeMode: NodeTimeMode { .onDirty }

    override class func registerPorts() -> [(name: String, port: Nodes.Port)] {
        [
            ("input", NodePort<Float>(name: "Input", kind: .inlet)),
            ("output", NodePort<Float>(name: "Output", kind: .outlet))
        ]
    }
}
