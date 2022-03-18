//
//  ComplicationController.swift
//  PrayerTimesWatch WatchKit Extension
//
//  Created by Leptos on 3/18/22.
//

import ClockKit


class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Complication Configuration
    
    func complicationDescriptors() async -> [CLKComplicationDescriptor] {
        let descriptors = [
            CLKComplicationDescriptor(identifier: "complication", displayName: "PrayerTimes", supportedFamilies: CLKComplicationFamily.allCases)
            // Multiple complication support can be added here with more descriptors
        ]
        return descriptors
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors
    }
    
    // MARK: - Timeline Configuration
    
    func timelineEndDate(for complication: CLKComplication) async -> Date? {
        // Return the last entry date you can currently provide or nil if you can't support future timelines
        return nil
    }
    
    func privacyBehavior(for complication: CLKComplication) async -> CLKComplicationPrivacyBehavior {
        // Return your desired behavior when the device is locked
        return .showOnLockScreen
    }
    
    // MARK: - Timeline Population
    
    func currentTimelineEntry(for complication: CLKComplication) async -> CLKComplicationTimelineEntry? {
        return nil
    }
    
    func timelineEntries(for complication: CLKComplication, after date: Date, limit: Int) async -> [CLKComplicationTimelineEntry]? {
        return nil
    }
    
    // MARK: - Sample Templates
    
    func localizableSampleTemplate(for complication: CLKComplication) async -> CLKComplicationTemplate? {
        // This method will be called once per supported complication, and the results will be cached
        return nil
    }
}
