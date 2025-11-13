
import SwiftUI
import CoreLocation // Added CoreLocation

struct ParkingLotView: View {
    let features: [Feature]

    var body: some View {
        Canvas { context, size in
            for feature in features {
                guard feature.geometry.type == "Polygon" else { continue }
                for linearRing in feature.geometry.coordinates {
                    var path = Path()
                    guard let firstPoint = linearRing.first else { continue }
                    path.move(to: CGPoint(x: firstPoint.longitude, y: firstPoint.latitude))
                    for point in linearRing.dropFirst() {
                        path.addLine(to: CGPoint(x: point.longitude, y: point.latitude))
                    }
                    path.closeSubpath()
                    
                    context.stroke(path, with: .color(.gray), lineWidth: 1)
                    context.fill(path, with: .color(.gray.opacity(0.4)))
                }
            }
        }
    }
}
