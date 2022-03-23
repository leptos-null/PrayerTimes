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
    public var disable: Set<Prayer.Name>
    
    public init(selection: Binding<Set<Prayer.Name>>, disable: Set<Prayer.Name> = Set()) {
        _selection = selection
        self.disable = disable
    }
    
    public var body: some View {
        ForEach(Prayer.Name.allCases) { name in
            HStack {
                Text(name.localized)
                Spacer()
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
                    .opacity(selection.contains(name) ? 1 : 0)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // if name is in selection, remove it, otherwise insert
                if selection.remove(name) == nil {
                    selection.insert(name)
                }
            }
            .disabled(disable.contains(name))
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
