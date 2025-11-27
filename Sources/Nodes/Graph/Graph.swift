// Graph.swift
// Nodes
//
// Container for a collection of connected nodes.

import Foundation
import SwiftUI

/// A graph containing nodes and their connections.
@Observable
public class Graph: Codable, Identifiable, Hashable, Equatable, @unchecked Sendable {

    public enum Version: String, Codable, Sendable {
        case v1
    }

    public let id: UUID
    public let version: Version
    public private(set) var nodes: [Node]

    @ObservationIgnored public weak var undoManager: UndoManager?

    /// Toggles to trigger view updates when connections change.
    public var shouldUpdateConnections = false

    /// Drag preview state for connection drawing.
    public var dragPreviewSourcePortID: UUID? = nil
    public var dragPreviewTargetPosition: CGPoint? = nil
    @ObservationIgnored public var portPositions: [UUID: CGPoint] = [:]

    @ObservationIgnored weak var lastNode: Node? = nil

    /// For nested graph / macro support.
    public weak var activeSubGraph: Graph? = nil

    // MARK: - Hashable / Equatable

    public static func == (lhs: Graph, rhs: Graph) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Initialization

    public init() {
        self.id = UUID()
        self.version = .v1
        self.nodes = []
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, version, nodes, portConnectionMap
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        version = try container.decode(Version.self, forKey: .version)
        nodes = []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(version, forKey: .version)

        let portMap = nodes.flatMap(\.ports).reduce(into: [UUID: [UUID]]()) { map, port in
            guard !port.connections.isEmpty else { return }
            map[port.id] = port.connections.map(\.id)
        }
        try container.encode(portMap, forKey: .portConnectionMap)
    }

    deinit {
        nodes.forEach { $0.teardown() }
    }

    // MARK: - Node Management

    public func addNode(_ node: Node) {
        if let activeSubGraph {
            activeSubGraph.addNode(node)
            return
        }

        nodes.append(node)
        node.graph = self
        shouldUpdateConnections.toggle()
    }

    public func delete(node: Node) {
        node.ports.forEach { $0.disconnectAll() }

        if let activeSubGraph {
            activeSubGraph.delete(node: node)
            return
        }

        nodes.removeAll { $0.id == node.id }
        shouldUpdateConnections.toggle()
    }

    public func node(forID id: UUID) -> Node? {
        let target = activeSubGraph ?? self
        return target.nodes.first { $0.id == id }
    }

    public func port(forID id: UUID) -> Port? {
        let target = activeSubGraph ?? self
        return target.nodes.flatMap(\.ports).first { $0.id == id }
    }

    // MARK: - Selection

    public enum SelectionDirection: Equatable, Sendable {
        case up, down, left, right

        static func from(angle: CGFloat) -> SelectionDirection {
            let normalized = angle.truncatingRemainder(dividingBy: 360)
            let angle360 = normalized >= 0 ? normalized : normalized + 360

            switch angle360 {
            case 45..<135: return .up
            case 135..<225: return .left
            case 225..<315: return .down
            default: return .right
            }
        }
    }

    public func selectNextNode(inDirection direction: SelectionDirection, expandSelection: Bool = false) {
        guard let referenceNode = lastNode ?? nodes.first else { return }
        let referencePoint = CGPoint(x: referenceNode.offset.width, y: referenceNode.offset.height)

        let candidates = nodes.filter { $0.id != referenceNode.id }
            .map { node -> (distance: CGFloat, direction: SelectionDirection, node: Node) in
                let point = CGPoint(x: node.offset.width, y: node.offset.height)
                let distance = hypot(point.x - referencePoint.x, point.y - referencePoint.y)
                let angle = atan2(point.y - referencePoint.y, point.x - referencePoint.x) * 180 / .pi
                var dir = SelectionDirection.from(angle: angle >= 0 ? angle : angle + 360)
                if dir == .up { dir = .down } else if dir == .down { dir = .up }
                return (distance, dir, node)
            }
            .filter { $0.direction == direction }
            .sorted { $0.distance < $1.distance }

        if let closest = candidates.first {
            selectNode(node: closest.node, expandSelection: expandSelection)
        }
    }

    public func selectNode(node: Node, expandSelection: Bool) {
        if !expandSelection {
            nodes.forEach { $0.isSelected = false }
        }
        lastNode = node
        node.isSelected = true
    }

    public func deselectAllNodes() {
        nodes.forEach { $0.isSelected = false }
    }

    // MARK: - Execution

    public var needsExecution: Bool {
        nodes.reduce(false) { $0 || $1.isDirty }
    }

    public func execute() {
        for node in nodes where node.isDirty {
            node.execute()
            node.markClean()
        }
    }
}
