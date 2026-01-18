//
//  frindrApp.swift
//  frindr
//
//  Created by Luke Caradine on 17/01/2026.
//

import SwiftUI
import Sentry


@main
struct frindrApp: App {
    init() {
        SentrySDK.start { options in
            options.dsn = "https://36e0e686f047fff15ed40c9801811f29@o4510209551237120.ingest.de.sentry.io/4510731765416016"

            // Adds IP for users.
            // For more information, visit: https://docs.sentry.io/platforms/apple/data-management/data-collected/
            options.sendDefaultPii = true

            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0

            // Configure profiling. Visit https://docs.sentry.io/platforms/apple/profiling/ to learn more.
            options.configureProfiling = {
                $0.sessionSampleRate = 1.0 // We recommend adjusting this value in production.
                $0.lifecycle = .trace
            }

            // Uncomment the following lines to add more data to your events
            // options.attachScreenshot = true // This adds a screenshot to the error events
            // options.attachViewHierarchy = true // This adds the view hierarchy to the error events
            
            // Enable experimental logging features
            options.experimental.enableLogs = true
        }
        // Remove the next line after confirming that your Sentry integration is working.
        SentrySDK.capture(message: "This app uses Sentry! :)")
    }
    @State private var mealService = MealService()
    @State private var familyMemberService = FamilyMemberService()
    @State private var syncManager = SyncManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(mealService)
                .environment(familyMemberService)
                .environment(syncManager)
                .onAppear {
                    syncManager.configure(
                        mealService: mealService,
                        familyMemberService: familyMemberService
                    )
                }
        }
    }
}
