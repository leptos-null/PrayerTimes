//
//  DateSubtitle.swift
//  PrayerTimes
//
//  Created by Leptos on 5/21/22.
//

import SwiftUI

struct DateSubtitle: View {
    let date: Date
    
    @Environment(\.calendar) private var calendar
    private let ummAlQura = Calendar(identifier: .islamicUmmAlQura)
    
    var body: some View {
        if calendar.identifier != ummAlQura.identifier {
            Text(date, style: .date)
                .font(.callout)
                .environment(\.calendar, ummAlQura)
                .foregroundColor(.secondary)
        }
    }
}

struct DateSubtitle_Previews: PreviewProvider {
    static var previews: some View {
        DateSubtitle(date: .now)
    }
}
