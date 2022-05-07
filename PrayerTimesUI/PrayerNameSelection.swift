//
//  PrayerNameSelection.swift
//  PrayerTimesUI
//
//  Created by Leptos on 3/22/22.
//

import SwiftUI
import PrayerTimesKit

public struct PrayerNameSelection: View {
    @Binding public var selection: Set<Prayer.Name>
    public let prayerNames: [Prayer.Name]
    
    public init(selection: Binding<Set<Prayer.Name>>, hidden: Set<Prayer.Name>? = nil) {
        _selection = selection
        
        let allCases = Prayer.Name.allCases
        if let hidden = hidden {
            prayerNames = Set(allCases)
                .symmetricDifference(hidden)
                .sorted()
        } else {
            prayerNames = allCases
        }
    }
    
    public init(selection: Binding<Set<Prayer.Name>>, include: Set<Prayer.Name>) {
        _selection = selection
        prayerNames = include.sorted()
    }
    
    public var body: some View {
        ForEach(prayerNames) { name in
            HStack {
                Text(name.localized)
                Spacer()
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
                    .opacity(selection.contains(name) ? 1 : 0)
            }
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel(name.localized)
            .accessibilityAddTraits(selection.contains(name) ? [ .isSelected ] : [])
            .onTapGesture {
                // if name is in selection, remove it, otherwise insert
                if selection.remove(name) == nil {
                    selection.insert(name)
                }
            }
        }
    }
}

extension Prayer.Name: Identifiable {
    public var id: Self { self }
}

struct PrayerNameSelection_Previews: PreviewProvider {
    private struct Client: View {
        @State var selection: Set<Prayer.Name>
        
        var body: some View {
            List {
                PrayerNameSelection(selection: $selection)
            }
        }
    }
    
    static var previews: some View {
        Client(selection: [ .fajr, .maghrib ])
    }
}
