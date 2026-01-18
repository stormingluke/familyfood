//
//  Meal.swift
//  frindr
//
//  Created by Luke Caradine on 17/01/2026.
//

import Foundation

enum ItemSyncStatus: String, Codable {
    case synced
    case pendingCreate
    case pendingUpdate
    case pendingDelete
}

struct Meal: Identifiable, Codable {
    let id: UUID
    var name: String
    var cuisineType: String
    var prepTime: PrepTime
    var imageData: Data?
    var imageURL: String?
    var lastEaten: Date?
    var timesEaten: Int
    var eatenBy: [UUID]
    var createdDate: Date
    var notes: String?
    var lastModified: Date
    var syncStatus: ItemSyncStatus

    init(
        id: UUID = UUID(),
        name: String,
        cuisineType: String,
        prepTime: PrepTime,
        imageData: Data? = nil,
        imageURL: String? = nil,
        lastEaten: Date? = nil,
        timesEaten: Int = 0,
        eatenBy: [UUID] = [],
        createdDate: Date = Date(),
        notes: String? = nil,
        lastModified: Date = Date(),
        syncStatus: ItemSyncStatus = .pendingCreate
    ) {
        self.id = id
        self.name = name
        self.cuisineType = cuisineType
        self.prepTime = prepTime
        self.imageData = imageData
        self.imageURL = imageURL
        self.lastEaten = lastEaten
        self.timesEaten = timesEaten
        self.eatenBy = eatenBy
        self.createdDate = createdDate
        self.notes = notes
        self.lastModified = lastModified
        self.syncStatus = syncStatus
    }

    enum PrepTime: String, Codable, CaseIterable {
        case short = "Short (15-30 min)"
        case medium = "Medium (30-60 min)"
        case long = "Long (1-2 hrs)"
        case veryLong = "Very Long (2+ hrs)"

        var displayTime: String {
            switch self {
            case .short: return "15-30 min"
            case .medium: return "30-60 min"
            case .long: return "1-2 hrs"
            case .veryLong: return "2+ hrs"
            }
        }

        var icon: String {
            switch self {
            case .short: return "clock"
            case .medium: return "clock.fill"
            case .long: return "hourglass"
            case .veryLong: return "hourglass.bottomhalf.filled"
            }
        }
    }

    var relativeLastEaten: String {
        guard let lastEaten = lastEaten else { return "Never eaten" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastEaten, relativeTo: Date())
    }
}
