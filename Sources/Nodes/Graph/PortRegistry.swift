// PortRegistry.swift
// Nodes
//
// Dynamic port management for nodes.

import Foundation

/// Manages a node's ports with indexed access by name, ID, and order.
/// Provides the dynamic property-like access that Swift lacks natively.
public final class PortRegistry: @unchecked Sendable {
    private(set) var ordered: [Port] = []
    private var byName: [String: Port] = [:]
    private var byID: [UUID: Port] = [:]

    public init() {}

    public func register(_ port: Port, name: String, owner: Node) {
        port.node = owner
        ordered.append(port)
        byName[name] = port
        byID[port.id] = port
    }

    public func addDynamic(_ port: Port, owner: Node) {
        register(port, name: port.name, owner: owner)
    }

    public func remove(_ port: Port) {
        port.disconnectAll()
        byID[port.id] = nil
        if let i = ordered.firstIndex(where: { $0.id == port.id }) {
            ordered.remove(at: i)
        }
        byName[port.name] = nil
    }

    public func port(named name: String) -> Port? {
        byName[name]
    }

    public func port(byID id: UUID) -> Port? {
        byID[id]
    }

    public func all() -> [Port] {
        ordered
    }

    // MARK: - Serialization

    public struct Snapshot: Codable, Sendable {
        public var name: String
        public var portType: PortType
        public var portData: Data

        public init(name: String, portType: PortType, portData: Data) {
            self.name = name
            self.portType = portType
            self.portData = portData
        }
    }

    public func encode() throws -> [Snapshot] {
        let encoder = JSONEncoder()
        return try ordered.compactMap { port in
            let name = byName.first { $0.value.id == port.id }?.key ?? port.name
            let data = try encoder.encode(port)
            return Snapshot(name: name, portType: port.portType, portData: data)
        }
    }
}
