// NodeView.swift
// Nodes
//
// View for rendering a single node.

import SwiftUI

/// View for rendering a single node in the graph.
public struct NodeView: View {
    @Environment(Graph.self) var graph: Graph

    public let node: Node
    public var nodeColor: Color
    public var selectedColor: Color
    public var backgroundColor: Color
    public var selectedBackgroundColor: Color

    public init(
        node: Node,
        nodeColor: Color = .blue,
        selectedColor: Color = .blue.opacity(0.8),
        backgroundColor: Color = Color(white: 0.15),
        selectedBackgroundColor: Color = Color(white: 0.2)
    ) {
        self.node = node
        self.nodeColor = nodeColor
        self.selectedColor = selectedColor
        self.backgroundColor = backgroundColor
        self.selectedBackgroundColor = selectedBackgroundColor
    }

    public var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .topLeading) {
                // Background
                node.isSelected ? selectedBackgroundColor : backgroundColor

                // Title bar
                Rectangle()
                    .fill((node.isSelected ? selectedColor : nodeColor).gradient)
                    .frame(height: 30)

                // Inlet ports (left side)
                VStack(alignment: .leading, spacing: 10) {
                    Text(node.name)
                        .font(.system(size: 9))
                        .bold()
                        .foregroundStyle(.primary)
                        .frame(maxHeight: 20)
                        .padding(.top, 5)
                        .padding(.horizontal, 20)

                    ForEach(node.ports.filter { $0.kind == .inlet && $0.direction == .horizontal }, id: \.id) { port in
                        NodeInletView(port: port)
                    }
                    Spacer(minLength: 0)
                }
                .frame(width: node.nodeSize.width + NodeInletView.radius, alignment: .leading)

                // Outlet ports (right side)
                VStack(alignment: .trailing, spacing: 10) {
                    Spacer(minLength: 0)
                        .frame(height: 25)

                    ForEach(node.ports.filter { $0.kind == .outlet && $0.direction == .horizontal }, id: \.id) { port in
                        NodeOutletView(port: port)
                    }
                    Spacer(minLength: 0)
                }
                .frame(width: node.nodeSize.width + NodeInletView.radius, alignment: .trailing)
            }
            .frame(width: node.nodeSize.width, height: node.nodeSize.height)
            .cornerRadius(15)
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(.gray, lineWidth: 1.0)
            }
            .contextMenu {
                ForEach(node.ports, id: \.id) { port in
                    Button {
                        port.published.toggle()
                    } label: {
                        Text(port.published ? "Unpublish Port: \(port.name)" : "Publish Port: \(port.name)")
                    }
                }
            }
        }
    }
}
