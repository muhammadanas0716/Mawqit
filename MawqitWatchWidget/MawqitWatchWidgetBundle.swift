//
//  MawqitWatchWidgetBundle.swift
//  MawqitWatchWidget
//

import WidgetKit
import SwiftUI

@main
struct MawqitWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        MawqitWatchHijriWidget()
        MawqitWatchUpcomingWidget()
    }
}
