//
//  DateTitle.swift
//  PrayerTimes
//
//  Created by Leptos on 5/21/22.
//

import SwiftUI

struct DateTitle: View {
    let date: Date
    
    var body: some View {
        Text(date, style: .date)
            .font(.title3)
    }
}

struct DateTitle_Previews: PreviewProvider {
    static var previews: some View {
        DateTitle(date: .now)
    }
}
