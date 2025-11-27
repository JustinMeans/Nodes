// NodeTests.swift
// NodesTests
//
// Tests for Node functionality.

import Testing
import Foundation
@testable import Nodes

@Suite("Node Tests")
struct NodeTests {

    @Test("Node initializes with unique ID")
    func nodeInitializesWithUniqueID() {
        let node1 = TestNode()
        let node2 = TestNode()

        #expect(node1.id != node2.id)
    }

    @Test("Node starts dirty")
    func nodeStartsDirty() {
        let node = TestNode()
        #expect(node.isDirty)
    }

    @Test("Node can be marked clean and dirty")
    func nodeCanBeMarkedCleanAndDirty() {
        let node = TestNode()

        node.markClean()
        #expect(!node.isDirty)

        node.markDirty()
        #expect(node.isDirty)
    }

    @Test("Node has correct class properties")
    func nodeHasCorrectClassProperties() {
        let node = TestNode()

        #expect(node.name == "Test Node")
        #expect(node.executionMode == .processor)
        #expect(node.timeMode == .onDirty)
    }

    @Test("Node registers ports correctly")
    func nodeRegistersPorts() {
        let node = TestNodeWithPorts()

        #expect(node.ports.count == 2)

        let inputPort = node.port(named: "input", as: NodePort<Float>.self)
        #expect(inputPort != nil)
        #expect(inputPort?.kind == .inlet)

        let outputPort = node.port(named: "output", as: NodePort<Float>.self)
        #expect(outputPort != nil)
        #expect(outputPort?.kind == .outlet)
    }

    @Test("Node computes size based on ports")
    func nodeComputesSizeBasedOnPorts() {
        let node = TestNodeWithPorts()
        let size = node.nodeSize

        #expect(size.width >= 150)
        #expect(size.height >= 60)
    }

    @Test("Node selection state")
    func nodeSelectionState() {
        let node = TestNode()

        #expect(!node.isSelected)
        node.isSelected = true
        #expect(node.isSelected)
    }

    @Test("Node dragging state")
    func nodeDraggingState() {
        let node = TestNode()

        #expect(!node.isDragging)
        node.isDragging = true
        #expect(node.isDragging)
    }

    @Test("Node offset can be modified")
    func nodeOffsetCanBeModified() {
        let node = TestNode()

        #expect(node.offset == .zero)
        node.offset = CGSize(width: 100, height: 200)
        #expect(node.offset.width == 100)
        #expect(node.offset.height == 200)
    }
}
