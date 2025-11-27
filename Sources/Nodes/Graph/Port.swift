// Port.swift
// Nodes
//
// Base port class for node connections.

import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Direction of port connection.
public enum PortKind: String, Codable, Sendable {
    case inlet
    case outlet
}

/// Visual layout direction for ports.
public enum PortDirection: String, Codable, Sendable {
    case horizontal
    case vertical
}

/// SwiftUI preference key for tracking port anchor positions.
public struct PortAnchorKey: PreferenceKey {
    public typealias Value = [UUID: Anchor<CGPoint>]
    public static let defaultValue: [UUID: Anchor<CGPoint>] = [:]

    public static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - Drag & Drop Transfer Types

/// Data transferred when dragging from an outlet.
public struct OutletDragData: Codable, Transferable, Sendable {
    public let portID: UUID

    public init(portID: UUID) {
        self.portID = portID
    }

    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .nodesOutletData)
    }
}

/// Data transferred when dragging from an inlet.
public struct InletDragData: Codable, Transferable, Sendable {
    public let portID: UUID

    public init(portID: UUID) {
        self.portID = portID
    }

    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .nodesInletData)
    }
}

extension UTType {
    public static var nodesOutletData: UTType { UTType(exportedAs: "com.nodes.outlet-data") }
    public static var nodesInletData: UTType { UTType(exportedAs: "com.nodes.inlet-data") }
}

// MARK: - Port Base Class

/// Base class for all ports. Do not instantiate directly; use `NodePort<Value>` instead.
@Observable
public class Port: Identifiable, Hashable, Equatable, Codable, CustomDebugStringConvertible, @unchecked Sendable {

    public static func == (lhs: Port, rhs: Port) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }

    public let id: UUID
    public let name: String
    public var published: Bool = false

    @ObservationIgnored public var portType: PortType { fatalError("Subclass must override") }
    @ObservationIgnored public var valueDidChange: Bool = true

    @ObservationIgnored public weak var node: Node?
    public var connections: [Port] = []
    @ObservationIgnored public let kind: PortKind
    @ObservationIgnored public let direction: PortDirection
    @ObservationIgnored public var color: Color
    @ObservationIgnored public var backgroundColor: Color

    public var debugDescription: String {
        "\(String(describing: type(of: self))) \(id)"
    }

    public init(name: String, kind: PortKind, direction: PortDirection = .horizontal, id: UUID = UUID()) {
        self.id = id
        self.kind = kind
        self.name = name
        self.direction = direction
        self.color = .gray
        self.backgroundColor = .gray.opacity(0.7)
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, name, kind, direction, published
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        kind = try container.decode(PortKind.self, forKey: .kind)
        direction = try container.decodeIfPresent(PortDirection.self, forKey: .direction) ?? .horizontal
        published = try container.decodeIfPresent(Bool.self, forKey: .published) ?? false
        color = .gray
        backgroundColor = .gray.opacity(0.7)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(kind, forKey: .kind)
        try container.encode(direction, forKey: .direction)
        try container.encode(published, forKey: .published)
    }

    deinit {}

    // MARK: - Connection Methods (Override in subclass)

    open func connect(to other: Port) { fatalError("Subclass must override") }
    open func disconnect(from other: Port) { fatalError("Subclass must override") }
    open func disconnectAll() { fatalError("Subclass must override") }
    open func teardown() {}
}
