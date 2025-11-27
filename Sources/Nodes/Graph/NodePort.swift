// NodePort.swift
// Nodes
//
// Generic typed port for transmitting values between nodes.

import Foundation
import SwiftUI
import simd

/// A typed port that carries values of type `Value` between nodes.
public class NodePort<Value: PortValue>: Port, @unchecked Sendable {
    public var value: Value? {
        didSet {
            if oldValue != value {
                valueDidChange = true
                node?.markDirty()
            }
        }
    }

    public var valueType: Any.Type { Value.self }

    @ObservationIgnored
    override public var portType: PortType {
        PortType.from(valueType)
    }

    public override init(name: String, kind: PortKind, direction: PortDirection = .horizontal, id: UUID = UUID()) {
        super.init(name: name, kind: kind, direction: direction, id: id)
        self.color = Self.portColor(for: Value.self)
        self.backgroundColor = Self.portColor(for: Value.self).opacity(0.7)
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        self.color = Self.portColor(for: Value.self)
        self.backgroundColor = Self.portColor(for: Value.self).opacity(0.7)
    }

    override public func teardown() {
        super.teardown()
        value = nil
    }

    deinit {}

    // MARK: - Disconnect

    override public func disconnectAll() {
        let currentConnections = connections
        for connection in currentConnections {
            disconnect(from: connection)
        }
    }

    override public func disconnect(from other: Port) {
        guard let other = other as? NodePort<Value> else { return }
        send(nil, to: other, force: true)
        performDisconnect(from: other)
    }

    private func performDisconnect(from other: Port) {
        if let node = self.node, let otherNode = other.node {
            node.didDisconnectFromNode(otherNode)
        }

        if other.kind == .inlet {
            other.connections.removeAll()
        } else {
            other.connections.removeAll { $0.id == self.id }
        }

        if kind == .inlet {
            connections.removeAll()
        } else {
            connections.removeAll { $0.id == other.id }
        }

        node?.graph?.shouldUpdateConnections.toggle()
    }

    // MARK: - Connect

    override public func connect(to other: Port) {
        guard let other = other as? NodePort<Value> else { return }
        performConnect(to: other)
    }

    private func performConnect(to other: Port) {
        guard kind != other.kind else { return }

        if kind == .inlet && other.kind == .outlet {
            let currentConnections = connections
            for connection in currentConnections {
                connection.disconnect(from: self)
            }
            connections.removeAll()
            connections.append(other)
            other.connections.append(self)
        } else if kind == .outlet && other.kind == .inlet {
            let otherConnections = other.connections
            for connection in otherConnections {
                connection.disconnect(from: other)
            }
            other.connections.removeAll()
            other.connections.append(self)
            connections.append(other)
        }

        if let node = self.node, let otherNode = other.node {
            node.didConnectToNode(otherNode)
        }

        send(value, force: true)
        node?.graph?.shouldUpdateConnections.toggle()
    }

    // MARK: - Send

    public func send(_ v: Value?, force: Bool = false) {
        if value != v || force {
            value = v
            for p in connections {
                if let p = p as? NodePort<Value> {
                    send(v, to: p, force: force)
                }
            }
        }
    }

    private func send(_ v: Value?, to other: NodePort<Value>, force: Bool = false) {
        if other.value != v || force {
            other.value = v
        }
    }

    // MARK: - Color Mapping

    private static func portColor(for type: Any.Type) -> Color {
        switch type {
        case is Bool.Type: .blue
        case is Int.Type: .cyan
        case is Float.Type, is Double.Type: .green
        case is String.Type: .orange
        case is simd_float2.Type: .purple
        case is simd_float3.Type: .pink
        case is simd_float4.Type: .red
        case is simd_quatf.Type: .yellow
        default: .gray
        }
    }
}
