//
//  CoordinatePicker.swift
//  PrayerTimes
//
//  Created by Leptos on 3/29/22.
//

import SwiftUI
import MapKit

struct CoordinatePicker: UIViewRepresentable {
    @Binding var coordinate: CLLocationCoordinate2D?
    
    func makeUIView(context: Context) -> MKMapView {
        let view = MKMapView()
        view.delegate = context.coordinator
        view.showsCompass = false
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.didLongPress(_:)))
        view.addGestureRecognizer(gestureRecognizer)
        
        return view
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        let point = context.coordinator.point
        
        view.removeAnnotation(point)
        
        if let coordinate = coordinate {
            point.coordinate = coordinate
            view.addAnnotation(point)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(coordinate: $coordinate)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        @Binding var coordinate: CLLocationCoordinate2D?
        let point = MKPointAnnotation()
        
        private let pointAnnotationView: MKAnnotationView
        
        init(coordinate: Binding<CLLocationCoordinate2D?>) {
            self._coordinate = coordinate
            
            let annotationView = MKMarkerAnnotationView(annotation: point, reuseIdentifier: nil)
            annotationView.animatesWhenAdded = true
            pointAnnotationView = annotationView
            
            super.init()
        }
        
        @objc func didLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
            guard gestureRecognizer.state == .began,
                  let view = gestureRecognizer.view as? MKMapView else { return }
            let touch = gestureRecognizer.location(in: view)
            coordinate = view.convert(touch, toCoordinateFrom: view)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            precondition(annotation === point)
            return pointAnnotationView
        }
    }
}

struct CoordinatePicker_Previews: PreviewProvider {
    private struct Client: View {
        @State var coordinate: CLLocationCoordinate2D?
        
        var body: some View {
            CoordinatePicker(coordinate: $coordinate)
        }
    }
    
    static var previews: some View {
        Client()
    }
}
