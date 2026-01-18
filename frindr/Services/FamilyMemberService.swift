//
//  FamilyMemberService.swift
//  frindr
//
//  FamilyMember CRUD operations with local caching and API sync
//

import Foundation
import SwiftUI

@MainActor
@Observable
class FamilyMemberService {
    private(set) var members: [FamilyMember] = []
    private(set) var isLoading = false

    private let apiClient = APIClient.shared
    private let cache = CacheManager.shared

    // MARK: - Load from Cache

    func loadFromCache() {
        Task {
            do {
                let cachedMembers = try await cache.loadFamilyMembers()
                self.members = cachedMembers
            } catch {
                print("Failed to load family members from cache: \(error)")
            }
        }
    }

    // MARK: - Create

    func create(_ member: FamilyMember) async throws {
        var newMember = member
        newMember.syncStatus = .pendingCreate
        newMember.lastModified = Date()

        // 1. Save locally immediately
        members.append(newMember)
        try await cache.saveFamilyMembers(members)

        // 2. Attempt remote sync
        do {
            let remoteMember: FamilyMemberDTO = try await apiClient.request(
                endpoint: .familyMembers,
                method: .POST,
                body: CreateFamilyMemberRequest.from(newMember)
            )

            newMember = remoteMember.toFamilyMember()
            newMember.syncStatus = .synced
            updateLocal(newMember)

        } catch {
            if isNetworkError(error) {
                try await queueMutation(.create, member: newMember)
            } else {
                members.removeAll { $0.id == newMember.id }
                try await cache.saveFamilyMembers(members)
                throw error
            }
        }
    }

    // MARK: - Update

    func update(_ member: FamilyMember) async throws {
        var updatedMember = member
        updatedMember.syncStatus = .pendingUpdate
        updatedMember.lastModified = Date()

        // 1. Optimistic local update
        updateLocal(updatedMember)

        // 2. Attempt remote sync
        do {
            let remoteMember: FamilyMemberDTO = try await apiClient.request(
                endpoint: .familyMember(member.id),
                method: .PUT,
                body: FamilyMemberDTO.from(updatedMember)
            )

            updatedMember = remoteMember.toFamilyMember()
            updatedMember.syncStatus = .synced
            updateLocal(updatedMember)

        } catch {
            if isNetworkError(error) {
                try await queueMutation(.update, member: updatedMember)
            } else {
                throw error
            }
        }
    }

    // MARK: - Delete

    func delete(_ memberId: UUID) async throws {
        guard let index = members.firstIndex(where: { $0.id == memberId }) else { return }
        var member = members[index]

        member.syncStatus = .pendingDelete
        updateLocal(member)

        do {
            try await apiClient.requestNoContent(
                endpoint: .familyMember(memberId),
                method: .DELETE
            )

            members.removeAll { $0.id == memberId }
            try await cache.saveFamilyMembers(members)

        } catch {
            if isNetworkError(error) {
                try await queueMutation(.delete, member: member)
            } else {
                member.syncStatus = .synced
                updateLocal(member)
                throw error
            }
        }
    }

    // MARK: - Favorites

    func addFavorite(memberId: UUID, mealId: UUID) async throws {
        guard let index = members.firstIndex(where: { $0.id == memberId }) else { return }
        var member = members[index]

        // 1. Optimistic local update
        if !member.favoriteMealIds.contains(mealId) {
            member.favoriteMealIds.append(mealId)
            member.lastModified = Date()
            updateLocal(member)
        }

        // 2. Sync to server
        do {
            try await apiClient.requestNoContent(
                endpoint: .favorites(familyMemberId: memberId, mealId: mealId),
                method: .POST
            )
        } catch {
            if !isNetworkError(error) {
                // Revert on non-network error
                member.favoriteMealIds.removeAll { $0 == mealId }
                updateLocal(member)
                throw error
            }
        }
    }

    func removeFavorite(memberId: UUID, mealId: UUID) async throws {
        guard let index = members.firstIndex(where: { $0.id == memberId }) else { return }
        var member = members[index]

        // 1. Optimistic local update
        member.favoriteMealIds.removeAll { $0 == mealId }
        member.lastModified = Date()
        updateLocal(member)

        // 2. Sync to server
        do {
            try await apiClient.requestNoContent(
                endpoint: .favorites(familyMemberId: memberId, mealId: mealId),
                method: .DELETE
            )
        } catch {
            if !isNetworkError(error) {
                // Revert on non-network error
                member.favoriteMealIds.append(mealId)
                updateLocal(member)
                throw error
            }
        }
    }

    // MARK: - Fetch from Remote

    func fetchFromRemote() async throws -> [FamilyMember] {
        let remoteMembers: [FamilyMemberDTO] = try await apiClient.request(
            endpoint: .familyMembers,
            method: .GET
        )
        return remoteMembers.map { $0.toFamilyMember() }
    }

    // MARK: - Merge Remote Data

    func mergeRemote(_ remoteMembers: [FamilyMember]) async throws {
        let remoteDict = Dictionary(uniqueKeysWithValues: remoteMembers.map { ($0.id, $0) })
        var mergedMembers: [FamilyMember] = []

        // Add all remote members (they win)
        for remoteMember in remoteMembers {
            var member = remoteMember
            member.syncStatus = .synced
            mergedMembers.append(member)
        }

        // Keep local members that have pending mutations
        for localMember in members {
            if localMember.syncStatus != .synced && remoteDict[localMember.id] == nil {
                mergedMembers.append(localMember)
            }
        }

        members = mergedMembers
        try await cache.saveFamilyMembers(members)
    }

    // MARK: - Private Helpers

    private func updateLocal(_ member: FamilyMember) {
        if let index = members.firstIndex(where: { $0.id == member.id }) {
            members[index] = member
        }
        Task {
            try? await cache.saveFamilyMembers(members)
        }
    }

    private func queueMutation(_ type: PendingMutation.MutationType, member: FamilyMember) async throws {
        let payload = try JSONEncoder().encode(member)
        let mutation = PendingMutation(
            type: type,
            entityType: .familyMember,
            entityId: member.id,
            payload: payload
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
