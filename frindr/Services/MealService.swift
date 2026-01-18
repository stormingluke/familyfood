//
//  MealService.swift
//  frindr
//
//  Meal CRUD operations with local caching and API sync
//

import Foundation
import SwiftUI

@MainActor
@Observable
class MealService {
    private(set) var meals: [Meal] = []
    private(set) var isLoading = false

    private let apiClient = APIClient.shared
    private let cache = CacheManager.shared
    private let imageService = ImageService.shared

    // MARK: - Load from Cache

    func loadFromCache() {
        Task {
            do {
                let cachedMeals = try await cache.loadMeals()
                self.meals = cachedMeals
            } catch {
                print("Failed to load meals from cache: \(error)")
            }
        }
    }

    // MARK: - Create

    func create(_ meal: Meal, imageData: Data?) async throws {
        var newMeal = meal
        newMeal.syncStatus = .pendingCreate
        newMeal.lastModified = Date()

        // 1. Save locally immediately for responsive UI
        meals.append(newMeal)
        try await cache.saveMeals(meals)

        // 2. Save image locally if present
        if let imageData = imageData {
            try await cache.saveImageData(imageData, for: newMeal.id)
        }

        // 3. Attempt remote sync
        do {
            // Upload image first if present
            if let imageData = imageData {
                let uploadResult = try await imageService.uploadImage(imageData, for: newMeal.id)
                newMeal.imageURL = uploadResult.url
                newMeal.imageData = nil  // Clear local data after successful upload
            }

            // Create on server
            let remoteMeal: MealDTO = try await apiClient.request(
                endpoint: .meals,
                method: .POST,
                body: CreateMealRequest.from(newMeal)
            )

            // Update local with server response
            newMeal = remoteMeal.toMeal()
            newMeal.syncStatus = .synced
            updateLocal(newMeal)

        } catch {
            if isNetworkError(error) {
                // Queue for later sync - already saved locally
                try await queueMutation(.create, meal: newMeal, imageData: imageData)
            } else {
                // Remove from local on other errors
                meals.removeAll { $0.id == newMeal.id }
                try await cache.saveMeals(meals)
                throw error
            }
        }
    }

    // MARK: - Update

    func update(_ meal: Meal) async throws {
        var updatedMeal = meal
        updatedMeal.syncStatus = .pendingUpdate
        updatedMeal.lastModified = Date()

        // 1. Optimistic local update
        updateLocal(updatedMeal)

        // 2. Attempt remote sync
        do {
            let remoteMeal: MealDTO = try await apiClient.request(
                endpoint: .meal(meal.id),
                method: .PUT,
                body: MealDTO.from(updatedMeal)
            )

            updatedMeal = remoteMeal.toMeal()
            updatedMeal.syncStatus = .synced
            updateLocal(updatedMeal)

        } catch {
            if isNetworkError(error) {
                try await queueMutation(.update, meal: updatedMeal, imageData: nil)
            } else {
                throw error
            }
        }
    }

    // MARK: - Delete

    func delete(_ mealId: UUID) async throws {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }
        var meal = meals[index]

        // 1. Mark as pending delete locally
        meal.syncStatus = .pendingDelete
        updateLocal(meal)

        // 2. Attempt remote delete
        do {
            try await apiClient.requestNoContent(
                endpoint: .meal(mealId),
                method: .DELETE
            )

            // Remove from local on success
            meals.removeAll { $0.id == mealId }
            try await cache.saveMeals(meals)
            try await cache.deleteImageData(for: mealId)

        } catch {
            if isNetworkError(error) {
                try await queueMutation(.delete, meal: meal, imageData: nil)
            } else {
                // Revert on error
                meal.syncStatus = .synced
                updateLocal(meal)
                throw error
            }
        }
    }

    // MARK: - Record Eaten

    func recordEaten(_ mealId: UUID, by memberIds: [UUID]) async throws {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }
        var meal = meals[index]

        // 1. Optimistic local update
        meal.lastEaten = Date()
        meal.timesEaten += 1
        for memberId in memberIds {
            if !meal.eatenBy.contains(memberId) {
                meal.eatenBy.append(memberId)
            }
        }
        meal.lastModified = Date()
        updateLocal(meal)

        // 2. Sync to server
        do {
            let request = RecordEatenRequest(familyMemberIds: memberIds.map { $0.uuidString })
            let remoteMeal: MealDTO = try await apiClient.request(
                endpoint: .mealEaten(mealId),
                method: .POST,
                body: request
            )

            var syncedMeal = remoteMeal.toMeal()
            syncedMeal.syncStatus = .synced
            updateLocal(syncedMeal)

        } catch {
            // Keep local changes even on network error
            if !isNetworkError(error) {
                throw error
            }
        }
    }

    // MARK: - Fetch from Remote

    func fetchFromRemote() async throws -> [Meal] {
        let remoteMeals: [MealDTO] = try await apiClient.request(
            endpoint: .meals,
            method: .GET
        )
        return remoteMeals.map { $0.toMeal() }
    }

    // MARK: - Merge Remote Data

    func mergeRemote(_ remoteMeals: [Meal]) async throws {
        let remoteDict = Dictionary(uniqueKeysWithValues: remoteMeals.map { ($0.id, $0) })
        var mergedMeals: [Meal] = []

        // Add all remote meals (they win)
        for remoteMeal in remoteMeals {
            var meal = remoteMeal
            meal.syncStatus = .synced
            mergedMeals.append(meal)
        }

        // Keep local meals that have pending mutations (not yet synced)
        for localMeal in meals {
            if localMeal.syncStatus != .synced && remoteDict[localMeal.id] == nil {
                mergedMeals.append(localMeal)
            }
        }

        meals = mergedMeals
        try await cache.saveMeals(meals)
    }

    // MARK: - Private Helpers

    private func updateLocal(_ meal: Meal) {
        if let index = meals.firstIndex(where: { $0.id == meal.id }) {
            meals[index] = meal
        }
        Task {
            try? await cache.saveMeals(meals)
        }
    }

    private func queueMutation(_ type: PendingMutation.MutationType, meal: Meal, imageData: Data?) async throws {
        let payload = try JSONEncoder().encode(meal)
        var imagePath: String? = nil

        if imageData != nil {
            imagePath = meal.id.uuidString
        }

        let mutation = PendingMutation(
            type: type,
            entityType: .meal,
            entityId: meal.id,
            payload: payload,
            imageDataPath: imagePath
        )
        try await cache.appendPendingMutation(mutation)
    }

    private func isNetworkError(_ error: Error) -> Bool {
        if let apiError = error as? APIError {
            return apiError.isNetworkError
        }
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain
    }
}
