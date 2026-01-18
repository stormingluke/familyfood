//
//  FamilyMember.swift
//  frindr
//
//  Created by Luke Caradine on 17/01/2026.
//

import SwiftUI

struct FamilyMember: Identifiable, Codable {
    let id: UUID
    var name: String
    var role: String
    var age: Int
    var icon: String
    var gradientColors: [CodableColor]
    var activities: [String]
    var preferences: String
    var favoriteMealIds: [UUID]
    var allergens: [String]
    var favoriteDrinks: [String]
    var lastModified: Date
    var syncStatus: ItemSyncStatus

    init(
        id: UUID = UUID(),
        name: String,
        role: String,
        age: Int,
        icon: String,
        gradientColors: [Color],
        activities: [String],
        preferences: String,
        favoriteMealIds: [UUID] = [],
        allergens: [String] = [],
        favoriteDrinks: [String] = [],
        lastModified: Date = Date(),
        syncStatus: ItemSyncStatus = .pendingCreate
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.age = age
        self.icon = icon
        self.gradientColors = gradientColors.map { CodableColor(color: $0) }
        self.activities = activities
        self.preferences = preferences
        self.favoriteMealIds = favoriteMealIds
        self.allergens = allergens
        self.favoriteDrinks = favoriteDrinks
        self.lastModified = lastModified
        self.syncStatus = syncStatus
    }

    var colors: [Color] {
        gradientColors.map { $0.color }
    }
}
