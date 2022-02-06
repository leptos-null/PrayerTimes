//
//  LocationManagerProperties.swift
//  PrayerTimesUI
//
//  Created by Leptos on 2/5/22.
//

import SwiftUI
import PrayerTimesKit
import MapKit

public struct LocationManagerProperties: View {
    @ObservedObject var locationManager: LocationManager
    
    private var annotations: [MKAnnotation] {
        var annotations: [MKAnnotation] = []
        if let location = locationManager.location {
            let point = MKPointAnnotation()
            point.coordinate = location.coordinate
            point.title = "location"
            annotations.append(point)
        }
        if let placemark = locationManager.placemark?.location {
            let point = MKPointAnnotation()
            point.coordinate = placemark.coordinate
            point.title = "placemark"
            annotations.append(point)
        }
        return annotations
    }
    
    private var overlays: [MKOverlay] {
        var overlays: [MKOverlay] = []
        if let region = locationManager.placemark?.region as? CLCircularRegion {
            let circle = MKCircle(center: region.center, radius: region.radius)
            circle.title = "region"
            overlays.append(circle)
        }
        return overlays
    }
    
    public init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }
    
    public var body: some View {
        VStack {
            if let location = locationManager.location {
                VStack {
                    Text("location")
                        .font(.headline)
                    LocationProperties(location: location)
                }
                .padding()
            }
            if let location = locationManager.placemark?.location {
                VStack {
                    Text("placemark")
                        .font(.headline)
                    LocationProperties(location: location)
                }
                .padding()
            }
            Spacer()
            MapView(annotations: annotations, overlays: overlays)
        }
    }
}

struct LocationProperties: View {
    let location: CLLocation
    
    var body: some View {
        VStack(alignment: .innerLeading) {
            TitleDetailView(title: "timestamp") {
                Text(location.timestamp.formatted(date: .numeric, time: .standard))
            }
            TitleDetailView(title: "coordiante") {
                Text("(\(location.coordinate.latitude.formatted(.number.precision(.fractionLength(4)))), \(location.coordinate.longitude.formatted(.number.precision(.fractionLength(4))))) ± (\(location.horizontalAccuracy.formatted()))")
            }
            LocationProperty(title: "altitude",
                             value: location.altitude,
                             accuracy: location.verticalAccuracy,
                             unit: UnitLength.meters
            )
            LocationProperty(title: "speed",
                             value: location.speed,
                             accuracy: location.speedAccuracy,
                             unit: UnitSpeed.metersPerSecond)
            
            LocationProperty(title: "course",
                             value: location.course,
                             accuracy: location.courseAccuracy,
                             unit: UnitAngle.degrees)
        }
    }
}

struct LocationProperty<T: Dimension>: View {
    let title: String
    
    let value: Double
    let accuracy: Double
    let unit: T
    
    private func measurement(_ value: Double) -> Measurement<T> {
        Measurement(value: value, unit: unit)
    }
    
    var body: some View {
        if accuracy >= 0 {
            TitleDetailView(title: title) {
                Text("\(measurement(value).formatted()) ± \(measurement(accuracy).formatted())")
            }
        }
    }
}

struct TitleDetailView<Content: View>: View {
    let title: String
    let detail: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.detail = content()
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            detail
                .alignmentGuide(.innerLeading) { d in
                    d[.leading]
                }
        }
    }
}

struct LocationProperties_Previews: PreviewProvider {
    static var previews: some View {
        LocationProperties(location: CLLocation())
    }
}

private extension HorizontalAlignment {
    enum InnerLeading: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[.leading]
        }
    }
    static let innerLeading = HorizontalAlignment(InnerLeading.self)
}

private struct MapView: UIViewRepresentable {
    let annotations: [MKAnnotation]
    let overlays: [MKOverlay]
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let view = MKMapView()
        view.showsUserLocation = true
        view.delegate = context.coordinator
        view.userTrackingMode = .follow
        return view
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        view.removeAnnotations(view.annotations)
        view.removeOverlays(view.overlays)
        
        view.addAnnotations(annotations)
        view.addOverlays(overlays)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
#if !targetEnvironment(simulator) /* in the simulator this causes errors to be constantly printed */
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circle = overlay as? MKCircle {
                let renderer = MKCircleRenderer(circle: circle)
                renderer.fillColor = .systemBlue.withAlphaComponent(0.6)
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
#endif
    }
}
