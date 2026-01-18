//
//  AddFamilyMemberSheet.swift
//  frindr
//
//  Created by Luke Caradine on 17/01/2026.
//

import SwiftUI

struct AddFamilyMemberSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FamilyMemberService.self) private var familyMemberService
    @State private var name = ""
    @State private var isSaving = false
    @State private var role = ""
    @State private var age = ""
    @State private var selectedIcon = "person.fill"
    @State private var allergens: [String] = []
    @State private var favoriteDrinks: [String] = []
    @State private var newAllergen = ""
    @State private var newDrink = ""

    private let iconOptions = [
        "person.fill", "figure.walk", "figure.dress.line.vertical.figure",
        "heart.circle.fill", "star.fill", "sparkles"
    ]

    private let roleOptions = ["Parent", "Partner", "Child", "Sibling", "Grandparent", "Other"]

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
                        iconSection
                        nameSection
                        roleSection
                        ageSection
                        allergensSection
                        drinksSection
                        addButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Family Member")
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
        }
    }

    // MARK: - View Components

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose an Icon")
                .font(.headline)
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(iconOptions, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                        } label: {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: icon)
                                        .foregroundStyle(.white)
                                        .font(.title2)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(
                                            selectedIcon == icon ? Color.white : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                        }
                    }
                }
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Name")
                .font(.headline)
                .foregroundStyle(.white)

            TextField("Enter name", text: $name)
                .textFieldStyle(.plain)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                .foregroundStyle(.white)
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var roleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Role")
                .font(.headline)
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(roleOptions, id: \.self) { roleOption in
                        Button {
                            role = roleOption
                        } label: {
                            Text(roleOption)
                                .font(.subheadline)
                                .foregroundStyle(role == roleOption ? .white : .white.opacity(0.7))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(role == roleOption ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
                                )
                        }
                    }
                }
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var ageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Age")
                .font(.headline)
                .foregroundStyle(.white)

            TextField("Enter age", text: $age)
                .textFieldStyle(.plain)
                .keyboardType(.numberPad)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                .foregroundStyle(.white)
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var allergensSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Allergens")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            HStack(spacing: 8) {
                TextField("Add allergen", text: $newAllergen)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial)
                    )
                    .foregroundStyle(.white)

                Button {
                    if !newAllergen.isEmpty {
                        allergens.append(newAllergen)
                        newAllergen = ""
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.title2)
                }
                .disabled(newAllergen.isEmpty)
            }

            if !allergens.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(allergens, id: \.self) { allergen in
                        HStack(spacing: 4) {
                            Text(allergen)
                                .font(.subheadline)
                                .foregroundStyle(.white)

                            Button {
                                allergens.removeAll { $0 == allergen }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white.opacity(0.7))
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.orange.opacity(0.3))
                        )
                        .glassEffect(.regular, in: .capsule)
                    }
                }
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var drinksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundStyle(.cyan)
                Text("Favorite Drinks")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            HStack(spacing: 8) {
                TextField("Add drink", text: $newDrink)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial)
                    )
                    .foregroundStyle(.white)

                Button {
                    if !newDrink.isEmpty {
                        favoriteDrinks.append(newDrink)
                        newDrink = ""
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.cyan)
                        .font(.title2)
                }
                .disabled(newDrink.isEmpty)
            }

            if !favoriteDrinks.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(favoriteDrinks, id: \.self) { drink in
                        HStack(spacing: 4) {
                            Text(drink)
                                .font(.subheadline)
                                .foregroundStyle(.white)

                            Button {
                                favoriteDrinks.removeAll { $0 == drink }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white.opacity(0.7))
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.cyan.opacity(0.3))
                        )
                        .glassEffect(.regular, in: .capsule)
                    }
                }
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var addButton: some View {
        Button {
            guard !isSaving, let ageInt = Int(age) else { return }
            isSaving = true

            let newMember = FamilyMember(
                name: name,
                role: role,
                age: ageInt,
                icon: selectedIcon,
                gradientColors: [.blue, .purple],
                activities: [],
                preferences: "",
                allergens: allergens,
                favoriteDrinks: favoriteDrinks
            )

            Task {
                do {
                    try await familyMemberService.create(newMember)
                    await MainActor.run {
                        dismiss()
                    }
                } catch {
                    print("Failed to add family member: \(error)")
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
                Text(isSaving ? "Adding..." : "Add Family Member")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(16)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
        }
        .disabled(name.isEmpty || role.isEmpty || age.isEmpty || isSaving)
        .opacity(name.isEmpty || role.isEmpty || age.isEmpty || isSaving ? 0.5 : 1.0)
    }
}
