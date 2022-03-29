//
//  LocationManagerView.swift
//  PrayerTimesUI
//
//  Created by Leptos on 2/5/22.
//

import SwiftUI
import PrayerTimesKit
import MapKit

public struct LocationManagerView: View {
    @ObservedObject var locationManager: LocationManager
    
#if os(iOS) || os(macOS) || os(tvOS)
    private var annotations: [MKAnnotation] {
        var annotations: [MKAnnotation] = []
        if let location = locationManager.location {
            let point = MKPointAnnotation()
            point.coordinate = location.coordinate
            point.title = "location"
            annotations.append(point)
        }
        if let placemark = locationManager.stapledLocation?.placemark?.location {
            let point = MKPointAnnotation()
            point.coordinate = placemark.coordinate
            point.title = "placemark"
            annotations.append(point)
        }
        return annotations
    }
    
    private var overlays: [MKOverlay] {
        var overlays: [MKOverlay] = []
        if let region = locationManager.stapledLocation?.placemark?.region as? CLCircularRegion {
            let circle = MKCircle(center: region.center, radius: region.radius)
            circle.title = "region"
            overlays.append(circle)
        }
        return overlays
    }
#endif
    
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
            if let placemark = locationManager.stapledLocation?.placemark {
                VStack {
                    Text("placemark")
                        .font(.headline)
                    PlacemarkProperties(placemark: placemark)
                }
                .padding()
            }
#if os(iOS) || os(macOS) || os(tvOS)
            Spacer()
            MapView(annotations: annotations, overlays: overlays)
#endif
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

struct PlacemarkProperties: View {
    let placemark: CLPlacemark
    
    var body: some View {
        if let location = placemark.location {
            LocationProperties(location: location)
        }
        
        VStack(alignment: .innerLeading) {
            if let region = placemark.region as? CLCircularRegion {
                TitleDetailView(title: "region") {
                    Text("(\(region.center.latitude.formatted(.number.precision(.fractionLength(4)))), \(region.center.longitude.formatted(.number.precision(.fractionLength(4))))) ± (\(region.radius.formatted(.number.precision(.fractionLength(4)))))")
                }
            }
            if let timeZone = placemark.timeZone {
                TitleDetailView(title: "timeZone") {
                    Text("\(timeZone.identifier) (GMT \((timeZone.secondsFromGMT()/(60 * 60)).formatted(.number.sign(strategy: .always(includingZero: true)))))")
                }
            }
            
            Spacer()
                .frame(height: 16)
            
            if let name = placemark.name {
                TitleDetailView(title: "name") {
                    Text(name)
                }
            }
            Group {
                if let thoroughfare = placemark.thoroughfare {
                    TitleDetailView(title: "thoroughfare") {
                        Text(thoroughfare)
                    }
                }
                if let subThoroughfare = placemark.subThoroughfare {
                    TitleDetailView(title: "subThoroughfare") {
                        Text(subThoroughfare)
                    }
                }
                if let locality = placemark.locality {
                    TitleDetailView(title: "locality") {
                        Text(locality)
                    }
                }
                if let subLocality = placemark.subLocality {
                    TitleDetailView(title: "subLocality") {
                        Text(subLocality)
                    }
                }
                if let administrativeArea = placemark.administrativeArea {
                    TitleDetailView(title: "administrativeArea") {
                        Text(administrativeArea)
                    }
                }
                if let subAdministrativeArea = placemark.subAdministrativeArea {
                    TitleDetailView(title: "subAdministrativeArea") {
                        Text(subAdministrativeArea)
                    }
                }
            }
            Group {
                if let postalCode = placemark.postalCode {
                    TitleDetailView(title: "postalCode") {
                        Text(postalCode)
                    }
                }
                if let isoCountryCode = placemark.isoCountryCode {
                    TitleDetailView(title: "isoCountryCode") {
                        Text(isoCountryCode)
                    }
                }
                if let country = placemark.country {
                    TitleDetailView(title: "country") {
                        Text(country)
                    }
                }
                if let inlandWater = placemark.inlandWater {
                    TitleDetailView(title: "inlandWater") {
                        Text(inlandWater)
                    }
                }
                if let ocean = placemark.ocean {
                    TitleDetailView(title: "ocean") {
                        Text(ocean)
                    }
                }
            }
            if let areasOfInterest = placemark.areasOfInterest {
                TitleDetailView(title: "areasOfInterest") {
                    VStack(alignment: .leading) {
                        ForEach(areasOfInterest, id: \.self) {
                            Text($0)
                        }
                    }
                }
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
        HStack(alignment: .firstTextBaseline) {
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

#if os(iOS) || os(macOS) || os(tvOS)
private struct MapView {
    let annotations: [MKAnnotation]
    let overlays: [MKOverlay]
    
    func makeView(context: Context) -> MKMapView {
        let view = MKMapView()
        view.showsUserLocation = true
        view.delegate = context.coordinator
        view.userTrackingMode = .follow
        return view
    }
    
    func updateView(_ view: MKMapView, context: Context) {
        view.removeAnnotations(view.annotations)
        view.removeOverlays(view.overlays)
        
        view.addAnnotations(annotations)
        view.addOverlays(overlays)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
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
#endif

#if os(iOS) || os(tvOS)
extension MapView: UIViewRepresentable {
    func makeUIView(context: Context) -> MKMapView {
        makeView(context: context)
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        updateView(view, context: context)
    }
}
#elseif os(macOS)
extension MapView: NSViewRepresentable {
    func makeNSView(context: Context) -> MKMapView {
        makeView(context: context)
    }
    
    func updateNSView(_ view: MKMapView, context: Context) {
        updateView(view, context: context)
    }
}
#endif
