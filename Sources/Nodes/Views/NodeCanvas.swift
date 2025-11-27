// NodeCanvas.swift
// Nodes
//
// Main canvas view for displaying and editing a node graph.

import SwiftUI

/// Main canvas view for displaying and interacting with a node graph.
public struct NodeCanvas: View {
    @Environment(Graph.self) var graph: Graph

    @State private var initialOffsets: [UUID: CGSize] = [:]
    @State private var activeDragAnchor: UUID? = nil

    /// Optional background view. If nil, uses default tiled pattern.
    public var background: AnyView?

    public init(background: AnyView? = nil) {
        self.background = background
    }

    public var body: some View {
        GeometryReader { geom in
            ZStack {
                // Background
                if let background {
                    background
                } else {
                    defaultBackground
                        .offset(-geom.size / 2)
                }

                let targetGraph = graph.activeSubGraph ?? graph

                // Nodes
                ForEach(targetGraph.nodes, id: \.id) { currentNode in
                    NodeView(node: currentNode)
                        .offset(currentNode.offset)
                        .highPriorityGesture(
                            TapGesture(count: 1)
                                .modifiers(.shift)
                                .onEnded {
                                    targetGraph.selectNode(node: currentNode, expandSelection: true)
                                }
                        )
                        .gesture(
                            SimultaneousGesture(
                                DragGesture(minimumDistance: 3)
                                    .onChanged { value in
                                        handleDragChanged(value: value, currentNode: currentNode, graph: targetGraph)
                                    }
                                    .onEnded { _ in
                                        handleDragEnded(graph: targetGraph)
                                    },
                                TapGesture(count: 1)
                                    .onEnded {
                                        targetGraph.deselectAllNodes()
                                        currentNode.isSelected.toggle()
                                    }
                            )
                        )
                }
            }
            .offset(geom.size / 2)
            .clipShape(Rectangle())
            .contentShape(Rectangle())
            .coordinateSpace(name: "graph")
            .onPreferenceChange(PortAnchorKey.self) { portAnchors in
                var positions: [UUID: CGPoint] = [:]
                for (portID, anchor) in portAnchors {
                    positions[portID] = geom[anchor]
                }
                graph.portPositions = positions
            }
            .overlayPreferenceValue(PortAnchorKey.self) { portAnchors in
                connectionLines(portAnchors: portAnchors, geom: geom)
            }
            .focusable(true, interactions: .edit)
            .focusEffectDisabled()
            .onDeleteCommand {
                let targetGraph = graph.activeSubGraph ?? graph
                targetGraph.nodes.filter(\.isSelected).forEach { targetGraph.delete(node: $0) }
            }
            .onTapGesture {
                (graph.activeSubGraph ?? graph).deselectAllNodes()
            }
            .id(graph.activeSubGraph?.shouldUpdateConnections ?? graph.shouldUpdateConnections)
        }
    }

    // MARK: - Background

    private var defaultBackground: some View {
        Canvas { context, size in
            let gridSize: CGFloat = 20
            let dotRadius: CGFloat = 1

            for x in stride(from: 0, through: size.width * 2, by: gridSize) {
                for y in stride(from: 0, through: size.height * 2, by: gridSize) {
                    let rect = CGRect(x: x - dotRadius, y: y - dotRadius,
                                      width: dotRadius * 2, height: dotRadius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(.gray.opacity(0.3)))
                }
            }
        }
    }

    // MARK: - Drag Handling

    private func handleDragChanged(value: DragGesture.Value, currentNode: Node, graph: Graph) {
        if activeDragAnchor == nil {
            activeDragAnchor = currentNode.id

            if !currentNode.isSelected {
                graph.selectNode(node: currentNode, expandSelection: false)
            }

            initialOffsets = Dictionary(
                uniqueKeysWithValues: graph.nodes
                    .filter(\.isSelected)
                    .map { ($0.id, $0.offset) }
            )

            graph.nodes.filter(\.isSelected).forEach { $0.isDragging = true }
        }

        let translation = value.translation
        graph.nodes.filter(\.isSelected).forEach { node in
            if let base = initialOffsets[node.id] {
                node.offset = base + translation
            }
        }
    }

    private func handleDragEnded(graph: Graph) {
        graph.nodes.filter(\.isSelected).forEach { $0.isDragging = false }
        activeDragAnchor = nil
        initialOffsets.removeAll()
    }

    // MARK: - Connection Lines

    @ViewBuilder
    private func connectionLines(portAnchors: [UUID: Anchor<CGPoint>], geom: GeometryProxy) -> some View {
        let targetGraph = graph.activeSubGraph ?? graph
        let ports = targetGraph.nodes.flatMap(\.ports)

        ForEach(ports.filter { $0.kind == .outlet }, id: \.id) { port in
            ForEach(port.connections.filter { $0.kind == .inlet }, id: \.id) { connectedPort in
                if let sourceAnchor = portAnchors[port.id],
                   let destAnchor = portAnchors[connectedPort.id] {
                    let start = geom[sourceAnchor]
                    let end = geom[destAnchor]
                    let path = connectionPath(port: port, start: start, end: end)

                    path.stroke(port.backgroundColor, lineWidth: 2)
                        .contentShape(path.stroke(style: StrokeStyle(lineWidth: 5)))
                        .onTapGesture(count: 2) {
                            port.disconnect(from: connectedPort)
                            targetGraph.shouldUpdateConnections.toggle()
                        }
                }
            }
        }

        // Drag preview line
        if let sourcePortID = targetGraph.dragPreviewSourcePortID,
           let targetPosition = targetGraph.dragPreviewTargetPosition,
           let sourceAnchor = portAnchors[sourcePortID],
           let sourcePort = targetGraph.port(forID: sourcePortID) {
            let start = geom[sourceAnchor]
            let path = connectionPath(port: sourcePort, start: start, end: targetPosition)

            path.stroke(
                sourcePort.backgroundColor.opacity(0.6),
                style: StrokeStyle(lineWidth: 2, dash: [5, 3])
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: targetPosition)
        }
    }

    // MARK: - Path Calculation

    private func connectionPath(port: Port, start: CGPoint, end: CGPoint) -> Path {
        let distance = hypot(end.x - start.x, end.y - start.y)
        let stemOffset = min(max(distance / 4, 5), 10)

        switch port.direction {
        case .vertical:
            return verticalPath(start: start, end: end, stemOffset: stemOffset)
        case .horizontal:
            return horizontalPath(start: start, end: end, stemOffset: stemOffset)
        }
    }

    private func horizontalPath(start: CGPoint, end: CGPoint, stemOffset: CGFloat) -> Path {
        let stemHeight = min(max(abs(end.x - start.x) / 4, 5), 10)
        let start1 = CGPoint(x: start.x + stemHeight, y: start.y)
        let end1 = CGPoint(x: end.x - stemHeight, y: end.y)
        let controlOffset = max(stemHeight + stemOffset, abs(end1.x - start1.x) / 2.4)
        let control1 = CGPoint(x: start1.x + controlOffset, y: start1.y)
        let control2 = CGPoint(x: end1.x - controlOffset, y: end1.y)

        return Path { path in
            path.move(to: start)
            path.addLine(to: start1)
            path.addCurve(to: end1, control1: control1, control2: control2)
            path.addLine(to: end)
        }
    }

    private func verticalPath(start: CGPoint, end: CGPoint, stemOffset: CGFloat) -> Path {
        let stemHeight = min(max(abs(end.y - start.y) / 4, 5), 10)
        let start1 = CGPoint(x: start.x, y: start.y + stemHeight)
        let end1 = CGPoint(x: end.x, y: end.y - stemHeight)
        let controlOffset = max(stemHeight + stemOffset, abs(end1.y - start1.y) / 2.4)
        let control1 = CGPoint(x: start1.x, y: start1.y + controlOffset)
        let control2 = CGPoint(x: end1.x, y: end1.y - controlOffset)

        return Path { path in
            path.move(to: start)
            path.addLine(to: start1)
            path.addCurve(to: end1, control1: control1, control2: control2)
            path.addLine(to: end)
        }
    }
}
