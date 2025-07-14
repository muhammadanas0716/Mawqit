//
//  MawqitWidgetLiveActivity.swift
//  MawqitWidget
//
//  Created by Muhammad Anas on 14/07/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MawqitWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct MawqitWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MawqitWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension MawqitWidgetAttributes {
    fileprivate static var preview: MawqitWidgetAttributes {
        MawqitWidgetAttributes(name: "World")
    }
}

extension MawqitWidgetAttributes.ContentState {
    fileprivate static var smiley: MawqitWidgetAttributes.ContentState {
        MawqitWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: MawqitWidgetAttributes.ContentState {
         MawqitWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: MawqitWidgetAttributes.preview) {
   MawqitWidgetLiveActivity()
} contentStates: {
    MawqitWidgetAttributes.ContentState.smiley
    MawqitWidgetAttributes.ContentState.starEyes
}
