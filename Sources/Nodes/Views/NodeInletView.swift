// NodeInletView.swift
// Nodes
//
// View for rendering an inlet (input) port.

import SwiftUI

/// View for rendering an inlet (input) port on a node.
public struct NodeInletView: View {
    public static let radius: CGFloat = 15

    @Environment(Graph.self) var graph: Graph

    public var port: Port

    public init(port: Port) {
        self.port = port
    }

    public var body: some View {
        HStack {
            Circle()
                .fill(port.color)
                .stroke(Color.red, lineWidth: port.published ? 1.0 : 0.0)
                .frame(width: 15)
                .brightness(port.published ? 0.2 : 0.0)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("graph"))
                        .onChanged { value in
                            graph.dragPreviewSourcePortID = port.id
                            graph.dragPreviewTargetPosition = value.location
                        }
                        .onEnded { value in
                            defer {
                                graph.dragPreviewSourcePortID = nil
                                graph.dragPreviewTargetPosition = nil
                            }

                            guard let targetPortID = findPortAt(position: value.location),
                                  let targetPort = graph.port(forID: targetPortID),
                                  targetPort.id != port.id,
                                  targetPort.kind == .outlet,
                                  targetPort.portType == port.portType else {
                                return
                            }

                            port.connect(to: targetPort)
                        }
                )
                .anchorPreference(
                    key: PortAnchorKey.self,
                    value: .center,
                    transform: { [port.id: $0] }
                )

            Text(port.name)
                .foregroundStyle(Color.secondary)
                .font(.system(size: 9))
                .lineLimit(1)
        }
        .frame(height: 15)
    }

    private func findPortAt(position: CGPoint) -> UUID? {
        let hitRadius: CGFloat = 25
        var closest: (UUID, CGFloat)? = nil

        for (portID, portPosition) in graph.portPositions {
            let distance = hypot(position.x - portPosition.x, position.y - portPosition.y)
            if distance < hitRadius {
                if let (_, currentDist) = closest {
                    if distance < currentDist {
                        closest = (portID, distance)
                    }
                } else {
                    closest = (portID, distance)
                }
            }
        }

        return closest?.0
    }
}
