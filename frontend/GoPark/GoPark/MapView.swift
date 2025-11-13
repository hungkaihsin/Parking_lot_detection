
import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let features: [Feature] // Changed from stalls: [Stall] to features: [Feature]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(region, animated: true)
        uiView.removeOverlays(uiView.overlays)
        let polygons = features.flatMap { feature -> [MKPolygon] in
            guard feature.geometry.type == "Polygon" else { return [] }
            return feature.geometry.coordinates.map { linearRing -> MKPolygon in
                var coordinates = linearRing // Make it a var
                return MKPolygon(coordinates: &coordinates, count: coordinates.count)
            }
        }
        uiView.addOverlays(polygons)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.gray.withAlphaComponent(0.4)
                renderer.strokeColor = UIColor.gray
                renderer.lineWidth = 1
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}
