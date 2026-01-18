//
//  frindrApp.swift
//  frindr
//
//  Created by Luke Caradine on 17/01/2026.
//

import SwiftUI

@main
struct frindrApp: App {
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
