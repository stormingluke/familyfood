//
//  FamilyMemberDTO.swift
//  frindr
//
//  API Data Transfer Object for FamilyMember
//

import Foundation
import SwiftUI

struct GradientColorDTO: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double

    func toCodableColor() -> CodableColor {
        CodableColor(red: red, green: green, blue: blue, opacity: opacity)
    }

    static func from(_ color: CodableColor) -> GradientColorDTO {
        GradientColorDTO(
            red: color.red,
            green: color.green,
            blue: color.blue,
            opacity: color.opacity
        )
    }
}

struct FamilyMemberDTO: Codable {
    let id: String
    let name: String
    let role: String
    let age: Int
    let icon: String
    let gradientColors: [GradientColorDTO]
    let activities: [String]
    let preferences: String
    let favoriteMealIds: [String]
    let allergens: [String]
    let favoriteDrinks: [String]

    func toFamilyMember() -> FamilyMember {
        FamilyMember(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            role: role,
            age: age,
            icon: icon,
            gradientColors: gradientColors.map { $0.toCodableColor().color },
            activities: activities,
            preferences: preferences,
            favoriteMealIds: favoriteMealIds.compactMap { UUID(uuidString: $0) },
            allergens: allergens,
            favoriteDrinks: favoriteDrinks,
            lastModified: Date(),
            syncStatus: .synced
        )
    }

    static func from(_ member: FamilyMember) -> FamilyMemberDTO {
        FamilyMemberDTO(
            id: member.id.uuidString,
            name: member.name,
            role: member.role,
            age: member.age,
            icon: member.icon,
            gradientColors: member.gradientColors.map { GradientColorDTO.from($0) },
            activities: member.activities,
            preferences: member.preferences,
            favoriteMealIds: member.favoriteMealIds.map { $0.uuidString },
            allergens: member.allergens,
            favoriteDrinks: member.favoriteDrinks
        )
    }
}

struct CreateFamilyMemberRequest: Codable {
    let name: String
    let role: String
    let age: Int
    let icon: String
    let gradientColors: [GradientColorDTO]
    let activities: [String]
    let preferences: String
    let allergens: [String]
    let favoriteDrinks: [String]

    static func from(_ member: FamilyMember) -> CreateFamilyMemberRequest {
        CreateFamilyMemberRequest(
            name: member.name,
            role: member.role,
            age: member.age,
            icon: member.icon,
            gradientColors: member.gradientColors.map { GradientColorDTO.from($0) },
            activities: member.activities,
            preferences: member.preferences,
            allergens: member.allergens,
            favoriteDrinks: member.favoriteDrinks
        )
    }
}
