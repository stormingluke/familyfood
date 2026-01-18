//
//  FamilyMemberDetailSheet.swift
//  frindr
//
//  Created by Luke Caradine on 17/01/2026.
//

import SwiftUI

struct FamilyMemberDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FamilyMemberService.self) private var familyMemberService
    @Environment(MealService.self) private var mealService
    let memberId: UUID
    let meals: [Meal]

    @State private var isEditingAllergens = false
    @State private var isEditingDrinks = false
    @State private var showAddAllergenAlert = false
    @State private var showAddDrinkAlert = false
    @State private var newAllergen = ""
    @State private var newDrink = ""
    @State private var showAllMealHistory = false

    private var member: FamilyMember? {
        familyMemberService.members.first { $0.id == memberId }
    }

    private var favoriteMeals: [Meal] {
        guard let member = member else { return [] }
        return meals.filter { member.favoriteMealIds.contains($0.id) }
    }

    private var mealHistory: [Meal] {
        guard let member = member else { return [] }
        return meals.filter { $0.eatenBy.contains(member.id) }
            .sorted { ($0.lastEaten ?? .distantPast) > ($1.lastEaten ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient

                if let member = member {
                    ScrollView {
                        VStack(spacing: 24) {
                            profileHeader(member: member)

                            if !favoriteMeals.isEmpty {
                                favoritesSection(member: member)
                            }

                            if !mealHistory.isEmpty {
                                mealHistorySection
                            }

                            allergensSection(member: member)
                            favoriteDrinksSection(member: member)

                            if !member.activities.isEmpty {
                                activitiesSection(member: member)
                            }

                            if !member.preferences.isEmpty {
                                preferencesSection(member: member)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                } else {
                    Text("Member not found")
                        .foregroundStyle(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.8))
                            .font(.title3)
                    }
                }
            }
            .alert("Add Allergen", isPresented: $showAddAllergenAlert) {
                TextField("Allergen name", text: $newAllergen)
                Button("Cancel", role: .cancel) {
                    newAllergen = ""
                }
                Button("Add") {
                    if !newAllergen.isEmpty, var member = member {
                        member.allergens.append(newAllergen)
                        updateMember(member)
                        newAllergen = ""
                    }
                }
            }
            .alert("Add Favorite Drink", isPresented: $showAddDrinkAlert) {
                TextField("Drink name", text: $newDrink)
                Button("Cancel", role: .cancel) {
                    newDrink = ""
                }
                Button("Add") {
                    if !newDrink.isEmpty, var member = member {
                        member.favoriteDrinks.append(newDrink)
                        updateMember(member)
                        newDrink = ""
                    }
                }
            }
        }
    }

    private func updateMember(_ member: FamilyMember) {
        Task {
            try? await familyMemberService.update(member)
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
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
    }

    // MARK: - Profile Header

    private func profileHeader(member: FamilyMember) -> some View {
        VStack(spacing: 16) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: member.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: member.icon)
                        .foregroundStyle(.white)
                        .font(.system(size: 48))
                )

            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(member.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("\(member.age)")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Text(member.role)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .glassEffect(.regular, in: .capsule)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    // MARK: - Favorites Section

    private func favoritesSection(member: FamilyMember) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "heart.fill", title: "Favorite Meals", color: .pink)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(favoriteMeals) { meal in
                        favoriteMealCard(meal: meal, member: member)
                    }
                }
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    private func favoriteMealCard(meal: Meal, member: FamilyMember) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                if let imageData = meal.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 80)
                        .overlay(
                            Image(systemName: "fork.knife")
                                .foregroundStyle(.white)
                                .font(.title2)
                        )
                }

                Button {
                    var updatedMember = member
                    updatedMember.favoriteMealIds.removeAll { $0 == meal.id }
                    updateMember(updatedMember)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white)
                        .font(.caption)
                        .padding(4)
                }
            }

            Text(meal.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .lineLimit(2)
                .frame(width: 100, alignment: .leading)
        }
    }

    // MARK: - Meal History Section

    private var mealHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionHeader(icon: "clock.fill", title: "Meal History", color: .blue)

                Spacer()

                if mealHistory.count > 5 {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showAllMealHistory.toggle()
                        }
                    } label: {
                        Text(showAllMealHistory ? "Show Less" : "See All")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }

            VStack(spacing: 12) {
                let displayedMeals = showAllMealHistory ? mealHistory : Array(mealHistory.prefix(5))
                ForEach(displayedMeals) { meal in
                    mealHistoryRow(meal: meal)
                }
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    private func mealHistoryRow(meal: Meal) -> some View {
        HStack(spacing: 12) {
            if let imageData = meal.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.6), .blue.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.white)
                            .font(.caption)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                Text(meal.relativeLastEaten)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Text(meal.cuisineType)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    // MARK: - Allergens Section

    private func allergensSection(member: FamilyMember) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionHeader(icon: "exclamationmark.triangle.fill", title: "Allergens", color: .orange)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isEditingAllergens.toggle()
                    }
                } label: {
                    Text(isEditingAllergens ? "Done" : "Edit")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            if member.allergens.isEmpty && !isEditingAllergens {
                Text("No allergens listed")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(member.allergens, id: \.self) { allergen in
                        allergenTag(allergen, member: member)
                    }

                    if isEditingAllergens {
                        addTagButton {
                            showAddAllergenAlert = true
                        }
                    }
                }
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    private func allergenTag(_ allergen: String, member: FamilyMember) -> some View {
        HStack(spacing: 4) {
            Text(allergen)
                .font(.subheadline)
                .foregroundStyle(.white)

            if isEditingAllergens {
                Button {
                    var updatedMember = member
                    updatedMember.allergens.removeAll { $0 == allergen }
                    updateMember(updatedMember)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.7))
                        .font(.caption)
                }
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

    // MARK: - Favorite Drinks Section

    private func favoriteDrinksSection(member: FamilyMember) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionHeader(icon: "cup.and.saucer.fill", title: "Favorite Drinks", color: .cyan)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isEditingDrinks.toggle()
                    }
                } label: {
                    Text(isEditingDrinks ? "Done" : "Edit")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            if member.favoriteDrinks.isEmpty && !isEditingDrinks {
                Text("No favorite drinks listed")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(member.favoriteDrinks, id: \.self) { drink in
                        drinkTag(drink, member: member)
                    }

                    if isEditingDrinks {
                        addTagButton {
                            showAddDrinkAlert = true
                        }
                    }
                }
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    private func drinkTag(_ drink: String, member: FamilyMember) -> some View {
        HStack(spacing: 4) {
            Text(drink)
                .font(.subheadline)
                .foregroundStyle(.white)

            if isEditingDrinks {
                Button {
                    var updatedMember = member
                    updatedMember.favoriteDrinks.removeAll { $0 == drink }
                    updateMember(updatedMember)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.7))
                        .font(.caption)
                }
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

    // MARK: - Activities Section

    private func activitiesSection(member: FamilyMember) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "figure.run", title: "Activities", color: .green)

            FlowLayout(spacing: 8) {
                ForEach(member.activities, id: \.self) { activity in
                    Text(activity)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .glassEffect(.regular, in: .capsule)
                }
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    // MARK: - Preferences Section

    private func preferencesSection(member: FamilyMember) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "heart.text.square.fill", title: "Preferences", color: .purple)

            Text(member.preferences)
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(4)
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    // MARK: - Helper Views

    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.body)

            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private func addTagButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.caption)
                Text("Add")
                    .font(.subheadline)
            }
            .foregroundStyle(.white.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .strokeBorder(.white.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
