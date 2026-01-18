//
//  MealDTO.swift
//  frindr
//
//  API Data Transfer Object for Meal
//

import Foundation

struct MealDTO: Codable {
    let id: String
    let name: String
    let cuisineType: String
    let prepTime: String
    let imageUrl: String?
    let lastEaten: Date?
    let timesEaten: Int
    let eatenBy: [String]
    let createdDate: Date
    let notes: String?

    func toMeal() -> Meal {
        Meal(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            cuisineType: cuisineType,
            prepTime: Meal.PrepTime(rawValue: prepTime) ?? .medium,
            imageData: nil,
            imageURL: imageUrl,
            lastEaten: lastEaten,
            timesEaten: timesEaten,
            eatenBy: eatenBy.compactMap { UUID(uuidString: $0) },
            createdDate: createdDate,
            notes: notes,
            lastModified: Date(),
            syncStatus: .synced
        )
    }

    static func from(_ meal: Meal) -> MealDTO {
        MealDTO(
            id: meal.id.uuidString,
            name: meal.name,
            cuisineType: meal.cuisineType,
            prepTime: meal.prepTime.apiValue,
            imageUrl: meal.imageURL,
            lastEaten: meal.lastEaten,
            timesEaten: meal.timesEaten,
            eatenBy: meal.eatenBy.map { $0.uuidString },
            createdDate: meal.createdDate,
            notes: meal.notes
        )
    }
}

struct CreateMealRequest: Codable {
    let name: String
    let cuisineType: String
    let prepTime: String
    let imageUrl: String?
    let notes: String?

    static func from(_ meal: Meal) -> CreateMealRequest {
        CreateMealRequest(
            name: meal.name,
            cuisineType: meal.cuisineType,
            prepTime: meal.prepTime.apiValue,
            imageUrl: meal.imageURL,
            notes: meal.notes
        )
    }
}

struct RecordEatenRequest: Codable {
    let familyMemberIds: [String]
}

extension Meal.PrepTime {
    var apiValue: String {
        switch self {
        case .short: return "short"
        case .medium: return "medium"
        case .long: return "long"
        case .veryLong: return "veryLong"
        }
    }

    init?(rawValue: String) {
        switch rawValue {
        case "short": self = .short
        case "medium": self = .medium
        case "long": self = .long
        case "veryLong": self = .veryLong
        default: return nil
        }
    }
}
