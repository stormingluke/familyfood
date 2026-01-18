//
//  CacheManager.swift
//  frindr
//
//  File-based JSON persistence for local caching
//

import Foundation

actor CacheManager {
    static let shared = CacheManager()

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private var cacheDirectory: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("cache", isDirectory: true)
    }

    private var imagesDirectory: URL {
        cacheDirectory.appendingPathComponent("images", isDirectory: true)
    }

    private init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        Task {
            await ensureDirectoriesExist()
        }
    }

    private func ensureDirectoriesExist() {
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Meals

    func saveMeals(_ meals: [Meal]) async throws {
        let url = cacheDirectory.appendingPathComponent("meals.json")
        let data = try encoder.encode(meals)
        try data.write(to: url)
    }

    func loadMeals() async throws -> [Meal] {
        let url = cacheDirectory.appendingPathComponent("meals.json")
        guard fileManager.fileExists(atPath: url.path) else {
            return []
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode([Meal].self, from: data)
    }

    // MARK: - Family Members

    func saveFamilyMembers(_ members: [FamilyMember]) async throws {
        let url = cacheDirectory.appendingPathComponent("familyMembers.json")
        let data = try encoder.encode(members)
        try data.write(to: url)
    }

    func loadFamilyMembers() async throws -> [FamilyMember] {
        let url = cacheDirectory.appendingPathComponent("familyMembers.json")
        guard fileManager.fileExists(atPath: url.path) else {
            return []
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode([FamilyMember].self, from: data)
    }

    // MARK: - Image Cache

    func saveImageData(_ data: Data, for mealId: UUID) async throws {
        let url = imagesDirectory.appendingPathComponent("\(mealId.uuidString).jpg")
        try data.write(to: url)
    }

    func loadImageData(for mealId: UUID) async throws -> Data? {
        let url = imagesDirectory.appendingPathComponent("\(mealId.uuidString).jpg")
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        return try Data(contentsOf: url)
    }

    func deleteImageData(for mealId: UUID) async throws {
        let url = imagesDirectory.appendingPathComponent("\(mealId.uuidString).jpg")
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    // MARK: - Pending Mutations (Offline Queue)

    func savePendingMutations(_ mutations: [PendingMutation]) async throws {
        let url = cacheDirectory.appendingPathComponent("pendingMutations.json")
        let data = try encoder.encode(mutations)
        try data.write(to: url)
    }

    func loadPendingMutations() async throws -> [PendingMutation] {
        let url = cacheDirectory.appendingPathComponent("pendingMutations.json")
        guard fileManager.fileExists(atPath: url.path) else {
            return []
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode([PendingMutation].self, from: data)
    }

    func appendPendingMutation(_ mutation: PendingMutation) async throws {
        var mutations = try await loadPendingMutations()
        mutations.append(mutation)
        try await savePendingMutations(mutations)
    }

    func removePendingMutation(id: UUID) async throws {
        var mutations = try await loadPendingMutations()
        mutations.removeAll { $0.id == id }
        try await savePendingMutations(mutations)
    }

    // MARK: - Clear Cache

    func clearAll() async throws {
        if fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.removeItem(at: cacheDirectory)
        }
        await ensureDirectoriesExist()
    }
}

// MARK: - Pending Mutation Model

struct PendingMutation: Codable, Identifiable {
    let id: UUID
    let type: MutationType
    let entityType: EntityType
    let entityId: UUID
    let payload: Data
    let imageDataPath: String?
    let createdAt: Date

    enum MutationType: String, Codable {
        case create
        case update
        case delete
    }

    enum EntityType: String, Codable {
        case meal
        case familyMember
        case favorite
        case mealEaten
    }

    init(
        id: UUID = UUID(),
        type: MutationType,
        entityType: EntityType,
        entityId: UUID,
        payload: Data,
        imageDataPath: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.entityType = entityType
        self.entityId = entityId
        self.payload = payload
        self.imageDataPath = imageDataPath
        self.createdAt = createdAt
    }
}
