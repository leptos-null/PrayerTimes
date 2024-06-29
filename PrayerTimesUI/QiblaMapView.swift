//
//  QiblaMapView.swift
//  PrayerTimesUI
//
//  Created by Leptos on 2/19/22.
//

import SwiftUI
import MapKit
import PrayerTimesKit

#if (canImport(UIKit) || canImport(AppKit)) && !os(watchOS)

public struct QiblaMapView: View {
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

private struct CourseMapView {
    let source: MKPointAnnotation
    let destination: MKPointAnnotation
    
    var geodesicLine: MKGeodesicPolyline {
        MKGeodesicPolyline(coordinates: [ source.coordinate, destination.coordinate ])
    }
    
    func makeView(context: Context) -> MKMapView {
        let view = MKMapView()
        view.delegate = context.coordinator
        view.mapType = .satelliteFlyover
#if !os(tvOS)
        view.showsCompass = false
#endif
        return view
    }
    
    func updateView(_ view: MKMapView, context: Context) {
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
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var source: MKPointAnnotation?
        var destination: MKPointAnnotation?
        var geodesicLine: MKGeodesicPolyline?
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemOrange
                renderer.alpha = 0.7
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

#if canImport(UIKit)
extension CourseMapView: UIViewRepresentable {
    func makeUIView(context: Context) -> MKMapView {
        makeView(context: context)
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        updateView(view, context: context)
    }
}
#elseif canImport(AppKit)
extension CourseMapView: NSViewRepresentable {
    func makeNSView(context: Context) -> MKMapView {
        makeView(context: context)
    }
    
    func updateNSView(_ view: MKMapView, context: Context) {
        updateView(view, context: context)
    }
}
#endif

extension MKGeodesicPolyline {
    convenience init(coordinates coords: [CLLocationCoordinate2D]) {
        self.init(coordinates: coords, count: coords.count)
    }
}

struct QiblaMapView_Previews: PreviewProvider {
    static var previews: some View {
        QiblaMapView(sourceCoordinate: CLLocationCoordinate2D(latitude: 41.01180, longitude: 28.97543))
    }
}

#endif
