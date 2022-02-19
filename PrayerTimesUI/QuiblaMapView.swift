//
//  QuiblaMapView.swift
//  PrayerTimesUI
//
//  Created by Leptos on 2/19/22.
//

import SwiftUI
import MapKit
import PrayerTimesKit

#if os(iOS) || os(tvOS)

public struct QuiblaMapView: View {
    public let sourceCoordinate: CLLocationCoordinate2D
    
    public init(sourceCoordinate: CLLocationCoordinate2D) {
        self.sourceCoordinate = sourceCoordinate
    }
    
    private var source: MKPointAnnotation {
        let point = MKPointAnnotation()
        point.coordinate = sourceCoordinate
        point.subtitle = "Current Location"
        return point
    }
    
    private var kaaba: MKPointAnnotation {
        let point = MKPointAnnotation()
        point.coordinate = .kaaba
        point.title = "Kaaba"
        return point
    }
    
    public var body: some View {
        CourseMapView(source: source, destination: kaaba)
    }
}

private struct CourseMapView: UIViewRepresentable {
    let source: MKPointAnnotation
    let destination: MKPointAnnotation
    
    var geodesicLine: MKGeodesicPolyline {
        MKGeodesicPolyline(coordinates: [ source.coordinate, destination.coordinate ])
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let view = MKMapView()
        view.delegate = context.coordinator
        view.mapType = .satelliteFlyover
        view.showsCompass = true
        return view
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        if let previousSource = context.coordinator.source {
            view.removeAnnotation(previousSource)
        }
        if let previousDestination = context.coordinator.destination {
            view.removeAnnotation(previousDestination)
        }
        if let previousGeodesicLine = context.coordinator.geodesicLine {
            view.removeOverlay(previousGeodesicLine)
        }
        
        let source = self.source
        let destination = self.destination
        let geodesicLine = self.geodesicLine
        
        view.addAnnotation(source)
        view.addAnnotation(destination)
        view.addOverlay(geodesicLine, level: .aboveRoads)
        
        context.coordinator.source = source
        context.coordinator.destination = destination
        context.coordinator.geodesicLine = geodesicLine
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var source: MKPointAnnotation?
        var destination: MKPointAnnotation?
        var geodesicLine: MKGeodesicPolyline?
        
#if !targetEnvironment(simulator) /* in the simulator this causes errors to be constantly printed */
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemOrange
                renderer.alpha = 0.7
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
#endif
    }
}

extension MKGeodesicPolyline {
    convenience init(coordinates coords: [CLLocationCoordinate2D]) {
        self.init(coordinates: coords, count: coords.count)
    }
}

struct QuiblaMapView_Previews: PreviewProvider {
    static var previews: some View {
        QuiblaMapView(sourceCoordinate: CLLocationCoordinate2D(latitude: 41.01180, longitude: 28.97543))
    }
}

#endif
