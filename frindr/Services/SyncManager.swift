//
//  SyncManager.swift
//  frindr
//
//  Coordinates data sync between local cache and remote API
//

import Foundation
import SwiftUI

enum SyncStatus: Equatable {
    case idle
    case syncing
    case error(String)
    case offline
}

@MainActor
@Observable
class SyncManager {
    private(set) var status: SyncStatus = .idle
    private(set) var lastSyncDate: Date?
    private(set) var pendingMutationCount: Int = 0

    private let apiClient = APIClient.shared
    private let cache = CacheManager.shared

    private weak var mealService: MealService?
    private weak var familyMemberService: FamilyMemberService?

    func configure(mealService: MealService, familyMemberService: FamilyMemberService) {
        self.mealService = mealService
        self.familyMemberService = familyMemberService
    }

    // MARK: - Full Sync

    func syncAll() async {
        guard status != .syncing else { return }
        status = .syncing

        do {
            // 1. Process pending mutations first (offline queue)
            try await processPendingMutations()

            // 2. Fetch fresh data from server
            guard let mealService = mealService,
                  let familyMemberService = familyMemberService else {
                status = .error("Services not configured")
                return
            }

            let remoteMeals = try await mealService.fetchFromRemote()
            let remoteMembers = try await familyMemberService.fetchFromRemote()

            // 3. Merge with local (remote wins)
            try await mealService.mergeRemote(remoteMeals)
            try await familyMemberService.mergeRemote(remoteMembers)

            lastSyncDate = Date()
            status = .idle

        } catch {
            if isNetworkError(error) {
                status = .offline
            } else {
                status = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - Process Pending Mutations

    func processPendingMutations() async throws {
        let mutations = try await cache.loadPendingMutations()
        pendingMutationCount = mutations.count

        guard !mutations.isEmpty else { return }

        let decoder = JSONDecoder()

        for mutation in mutations {
            do {
                switch mutation.entityType {
                case .meal:
                    try await processMealMutation(mutation, decoder: decoder)
                case .familyMember:
                    try await processFamilyMemberMutation(mutation, decoder: decoder)
                case .favorite:
                    // Handle favorite mutations if needed
                    break
                case .mealEaten:
                    // Handle meal eaten mutations if needed
                    break
                }

                // Remove successfully processed mutation
                try await cache.removePendingMutation(id: mutation.id)
                pendingMutationCount -= 1

            } catch {
                if !isNetworkError(error) {
                    // Remove mutation on non-network errors to prevent retry loops
                    try await cache.removePendingMutation(id: mutation.id)
                    pendingMutationCount -= 1
                } else {
                    // Stop processing on network error
                    throw error
                }
            }
        }
    }

    private func processMealMutation(_ mutation: PendingMutation, decoder: JSONDecoder) async throws {
        let meal = try decoder.decode(Meal.self, from: mutation.payload)

        switch mutation.type {
        case .create:
            // Load image data if present
            var imageData: Data? = nil
            if mutation.imageDataPath != nil {
                imageData = try await cache.loadImageData(for: meal.id)
            }

            // Upload image if present
            var imageURL: String? = nil
            if let imageData = imageData {
                let uploadResult = try await ImageService.shared.uploadImage(imageData, for: meal.id)
                imageURL = uploadResult.url
            }

            // Create on server
            var mealToCreate = meal
            mealToCreate.imageURL = imageURL
            let _: MealDTO = try await apiClient.request(
                endpoint: .meals,
                method: .POST,
                body: CreateMealRequest.from(mealToCreate)
            )

        case .update:
            let _: MealDTO = try await apiClient.request(
                endpoint: .meal(meal.id),
                method: .PUT,
                body: MealDTO.from(meal)
            )

        case .delete:
            try await apiClient.requestNoContent(
                endpoint: .meal(meal.id),
                method: .DELETE
            )
        }
    }

    private func processFamilyMemberMutation(_ mutation: PendingMutation, decoder: JSONDecoder) async throws {
        let member = try decoder.decode(FamilyMember.self, from: mutation.payload)

        switch mutation.type {
        case .create:
            let _: FamilyMemberDTO = try await apiClient.request(
                endpoint: .familyMembers,
                method: .POST,
                body: CreateFamilyMemberRequest.from(member)
            )

        case .update:
            let _: FamilyMemberDTO = try await apiClient.request(
                endpoint: .familyMember(member.id),
                method: .PUT,
                body: FamilyMemberDTO.from(member)
            )

        case .delete:
            try await apiClient.requestNoContent(
                endpoint: .familyMember(member.id),
                method: .DELETE
            )
        }
    }

    // MARK: - Helpers

    private func isNetworkError(_ error: Error) -> Bool {
        if let apiError = error as? APIError {
            return apiError.isNetworkError
        }
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain
    }

    func updatePendingCount() async {
        do {
            let mutations = try await cache.loadPendingMutations()
            pendingMutationCount = mutations.count
        } catch {
            pendingMutationCount = 0
        }
    }
}
