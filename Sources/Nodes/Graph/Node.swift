// Node.swift
// Nodes
//
// Base class for all nodes in a graph.

import Foundation
import SwiftUI
import Combine

/// Execution mode determines when a node is evaluated.
public enum NodeExecutionMode: String, Codable, Sendable {
    case provider
    case processor
    case consumer
}

/// Time mode for execution scheduling.
public enum NodeTimeMode: String, Codable, Sendable {
    case always
    case onDirty
    case manual
}

/// Base class for nodes in a graph. Subclass this to create custom nodes.
@Observable
public class Node: Codable, Equatable, Identifiable, Hashable, @unchecked Sendable {

    // MARK: - Class Properties (Override in subclasses)

    open class var name: String { fatalError("Subclass must implement name") }
    open class var nodeDescription: String { "" }
    open class var nodeExecutionMode: NodeExecutionMode { .processor }
    open class var nodeTimeMode: NodeTimeMode { .onDirty }

    /// Override to declare this node's ports.
    open class func registerPorts() -> [(name: String, port: Port)] { [] }

    // MARK: - Instance Properties

    public let id: UUID
    @ObservationIgnored private let registry = PortRegistry()

    public var ports: [Port] { registry.all() }
    public private(set) var inputNodes: [Node] = []
    public private(set) var outputNodes: [Node] = []

    public var isSelected: Bool = false
    public var isDragging: Bool = false
    public var offset: CGSize = .zero

    @ObservationIgnored public private(set) var isDirty: Bool = true
    @ObservationIgnored public weak var graph: Graph?

    public var name: String { Self.name }
    public var executionMode: NodeExecutionMode { Self.nodeExecutionMode }
    public var timeMode: NodeTimeMode { Self.nodeTimeMode }

    /// Computed node size based on port count.
    public var nodeSize: CGSize {
        let inletCount = ports.filter { $0.kind == .inlet && $0.direction == .horizontal }.count
        let outletCount = ports.filter { $0.kind == .outlet && $0.direction == .horizontal }.count
        let maxPorts = max(inletCount, outletCount)
        let height = 40 + CGFloat(maxPorts) * 25
        return CGSize(width: max(150, 20), height: max(height, 60))
    }

    // MARK: - Hashable / Equatable

    public static func == (lhs: Node, rhs: Node) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Initialization

    public init() {
        self.id = UUID()
        let declared = Self.registerPorts()
        for (name, port) in declared {
            registry.register(port, name: name, owner: self)
        }
        for port in ports {
            port.node = self
        }
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, nodeOffset, ports
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        offset = try container.decode(CGSize.self, forKey: .nodeOffset)

        let declared = Self.registerPorts()
        for (name, port) in declared {
            registry.register(port, name: name, owner: self)
        }
        for port in ports {
            port.node = self
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(offset, forKey: .nodeOffset)
        try container.encode(registry.encode(), forKey: .ports)
    }

    deinit {}

    // MARK: - Teardown

    public func teardown() {
        inputNodes.removeAll()
        outputNodes.removeAll()
        for port in ports {
            port.disconnectAll()
            port.teardown()
        }
    }

    // MARK: - Port Access

    public func port<T: Port>(named name: String, as type: T.Type = T.self) -> T? {
        registry.port(named: name) as? T
    }

    public func addDynamicPort(_ port: Port) {
        registry.addDynamic(port, owner: self)
    }

    public func removePort(_ port: Port) {
        registry.remove(port)
    }

    public func publishedPorts() -> [Port] {
        ports.filter { $0.published }
    }

    // MARK: - Connection Callbacks

    public func didConnectToNode(_ node: Node) {
        inputNodes = calcInputNodes()
        outputNodes = calcOutputNodes()
    }

    public func didDisconnectFromNode(_ node: Node) {
        inputNodes = calcInputNodes()
        outputNodes = calcOutputNodes()
    }

    private func calcInputNodes() -> [Node] {
        ports.filter { $0.kind == .inlet }
            .flatMap { $0.connections.compactMap(\.node) }
    }

    private func calcOutputNodes() -> [Node] {
        ports.filter { $0.kind == .outlet }
            .flatMap { $0.connections.compactMap(\.node) }
    }

    // MARK: - Dirty State

    public func markClean() {
        isDirty = false
        for port in ports {
            port.valueDidChange = false
        }
    }

    public func markDirty() {
        isDirty = true
    }

    // MARK: - Execution (Override in subclasses)

    open func execute() {}
}
