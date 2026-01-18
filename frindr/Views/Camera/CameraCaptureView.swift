//
//  CameraCaptureView.swift
//  frindr
//
//  Created by Luke Caradine on 17/01/2026.
//

import SwiftUI

struct CameraCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MealService.self) private var mealService
    let familyMembers: [FamilyMember]

    @State private var mealName = ""
    @State private var isSaving = false
    @State private var cuisineType = "Italian"
    @State private var prepTime: Meal.PrepTime = .medium
    @State private var selectedMembers: Set<UUID> = []
    @State private var capturedImage: UIImage?
    @State private var showImagePicker = false

    private let cuisineOptions = ["Italian", "Asian", "Mexican", "Mediterranean", "American", "Other"]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.15, green: 0.05, blue: 0.25),
                        Color(red: 0.2, green: 0.1, blue: 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        cameraButton
                        mealNameSection
                        cuisineSection
                        prepTimeSection
                        familyMemberSection
                        saveButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Capture Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $capturedImage)
            }
        }
    }

    // MARK: - View Components

    private var cameraButton: some View {
        Button {
            showImagePicker = true
        } label: {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("Tap to take photo")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .frame(height: 200)
            }
        }
        .frame(maxWidth: .infinity)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
    }

    private var mealNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal Name")
                .font(.headline)
                .foregroundStyle(.white)

            TextField("Enter meal name", text: $mealName)
                .textFieldStyle(.plain)
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                .foregroundStyle(.white)
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var cuisineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cuisine Type")
                .font(.headline)
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(cuisineOptions, id: \.self) { cuisine in
                        Button {
                            cuisineType = cuisine
                        } label: {
                            Text(cuisine)
                                .font(.subheadline)
                                .foregroundStyle(cuisineType == cuisine ? .white : .white.opacity(0.7))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule().fill(cuisineType == cuisine ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
                                )
                        }
                    }
                }
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var prepTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prep Time")
                .font(.headline)
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Meal.PrepTime.allCases, id: \.self) { time in
                        Button {
                            prepTime = time
                        } label: {
                            Text(time.rawValue)
                                .font(.caption)
                                .foregroundStyle(prepTime == time ? .white : .white.opacity(0.7))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule().fill(prepTime == time ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
                                )
                        }
                    }
                }
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var familyMemberSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Who ate it?")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(familyMembers) { member in
                Button {
                    if selectedMembers.contains(member.id) {
                        selectedMembers.remove(member.id)
                    } else {
                        selectedMembers.insert(member.id)
                    }
                } label: {
                    HStack {
                        Circle()
                            .fill(LinearGradient(colors: member.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 40, height: 40)
                            .overlay(Image(systemName: member.icon).foregroundStyle(.white))

                        Text(member.name)
                            .foregroundStyle(.white)

                        Spacer()

                        if selectedMembers.contains(member.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedMembers.contains(member.id) ? Color.white.opacity(0.2) : Color.white.opacity(0.05))
                    )
                }
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var saveButton: some View {
        Button {
            guard !isSaving else { return }
            isSaving = true

            let newMeal = Meal(
                name: mealName,
                cuisineType: cuisineType,
                prepTime: prepTime,
                lastEaten: Date(),
                timesEaten: 1,
                eatenBy: Array(selectedMembers)
            )
            let imageData = capturedImage?.jpegData(compressionQuality: 0.8)

            Task {
                do {
                    try await mealService.create(newMeal, imageData: imageData)
                    await MainActor.run {
                        dismiss()
                    }
                } catch {
                    print("Failed to save meal: \(error)")
                    await MainActor.run {
                        isSaving = false
                    }
                }
            }
        } label: {
            HStack {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                }
                Text(isSaving ? "Saving..." : "Save Meal")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(16)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
        }
        .disabled(mealName.isEmpty || capturedImage == nil || isSaving)
        .opacity(mealName.isEmpty || capturedImage == nil || isSaving ? 0.5 : 1.0)
    }
}
