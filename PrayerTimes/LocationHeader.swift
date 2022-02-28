//
//  LocationHeader.swift
//  PrayerTimes
//
//  Created by Leptos on 2/26/22.
//

import SwiftUI

struct LocationHeader: View {
    let title: String
    
    var body: some View {
        Spacer()
            .frame(height: 48)
        Text(title)
            .font(.title2)
    }
}

struct LocationHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            LocationHeader(title: "Location Title")
        }
    }
}
