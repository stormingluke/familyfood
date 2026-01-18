//
//  ContentView.swift
//  frindr
//
//  Created by Luke Caradine on 17/01/2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(MealService.self) private var mealService
    @Environment(FamilyMemberService.self) private var familyMemberService
    @Environment(SyncManager.self) private var syncManager

    @State private var selectedTab: Tab = .discover
    @State private var showFullscreenDiscover = false
    @State private var selectedCardIndex: Int?
    @State private var showAddFamilyMember = false
    @State private var selectedFamilyMemberIndex: Int = 0
    @State private var showCamera = false
    @State private var showFamilyMemberDetail = false
    @Namespace private var glassNamespace

    private var meals: [Meal] { mealService.meals }
    private var familyMembers: [FamilyMember] { familyMemberService.members }

    enum Tab {
        case discover, picture, family
    }

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 0) {
                mainContent
                Spacer()
                bottomNavigation
            }

            // Sync status indicator at top
            VStack {
                SyncStatusView()
                    .padding(.top, 60)
                Spacer()
            }

            if showFullscreenDiscover {
                FullscreenMealView(
                    isPresented: $showFullscreenDiscover,
                    startingIndex: selectedCardIndex ?? 0,
                    meals: meals,
                    familyMembers: familyMembers
                )
                .environment(mealService)
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .onAppear {
            loadAndSync()
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .picture {
                showCamera = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedTab = .discover
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraCaptureView(familyMembers: familyMembers)
                .environment(mealService)
        }
        .sheet(isPresented: $showFamilyMemberDetail) {
            if familyMembers.indices.contains(selectedFamilyMemberIndex) {
                FamilyMemberDetailSheet(
                    memberId: familyMembers[selectedFamilyMemberIndex].id,
                    meals: meals
                )
                .environment(familyMemberService)
                .environment(mealService)
            }
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

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        switch selectedTab {
        case .discover:
            discoverView
        case .picture:
            discoverView
        case .family:
            familyPortalView
        }
    }

    // MARK: - Discover View

    private var discoverView: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                featuredCardsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 100)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Discover Meals")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Explore and favorite family meals")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var featuredCardsSection: some View {
        GlassEffectContainer(spacing: 30) {
            VStack(spacing: 20) {
                ForEach(Array(meals.enumerated()), id: \.offset) { index, meal in
                    mealCard(meal: meal, index: index)
                }
            }
        }
    }

    private func mealCard(meal: Meal, index: Int) -> some View {
        Button {
            selectedCardIndex = index
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showFullscreenDiscover = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ZStack {
                        if let imageData = meal.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [cuisineGradient(meal.cuisineType).0, cuisineGradient(meal.cuisineType).1],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Image(systemName: cuisineIcon(meal.cuisineType))
                                        .foregroundStyle(.white)
                                        .font(.title3)
                                )
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.name)
                            .font(.headline)
                            .foregroundStyle(.white)

                        HStack(spacing: 4) {
                            Image(systemName: meal.prepTime.icon)
                                .font(.caption2)
                            Text(meal.prepTime.displayTime)
                                .font(.caption)
                        }
                        .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(meal.cuisineType)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))

                        if meal.lastEaten != nil {
                            Text(meal.relativeLastEaten)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }

                if !meal.eatenBy.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(.pink)

                        Text("Liked by \(meal.eatenBy.count) family member\(meal.eatenBy.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding(20)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
            .glassEffectID("card-\(index)", in: glassNamespace)
        }
        .buttonStyle(.plain)
    }

    private func cuisineIcon(_ cuisine: String) -> String {
        switch cuisine.lowercased() {
        case "italian": return "leaf.fill"
        case "asian", "chinese", "japanese": return "flame.fill"
        case "mexican": return "sun.max.fill"
        case "mediterranean", "greek": return "globe.europe.africa.fill"
        case "american": return "flag.fill"
        default: return "fork.knife"
        }
    }

    private func cuisineGradient(_ cuisine: String) -> (Color, Color) {
        switch cuisine.lowercased() {
        case "italian": return (.green, .red)
        case "asian", "chinese", "japanese": return (.red, .orange)
        case "mexican": return (.orange, .yellow)
        case "mediterranean", "greek": return (.blue, .cyan)
        case "american": return (.red, .blue)
        default: return (.purple, .pink)
        }
    }

    // MARK: - Family Portal View

    private var familyPortalView: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Family Portal")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Manage your family members")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 60)

                familyMemberCarousel

                quickActionsSection
            }
            .padding(.bottom, 100)
        }
    }

    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            VStack(spacing: 0) {
                quickActionRow(icon: "heart.fill", title: "Favorites", subtitle: "Family favorites", color: .pink)
                quickActionRow(icon: "calendar", title: "Meal Plan", subtitle: "Weekly planner", color: .purple)
                quickActionRow(icon: "magnifyingglass", title: "Search", subtitle: "Find meals", color: .orange)
                quickActionRow(icon: "chart.bar.fill", title: "Statistics", subtitle: "Eating patterns", color: .green)
                quickActionRow(icon: "list.bullet", title: "Categories", subtitle: "Browse cuisines", color: .teal, showDivider: false)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))
            )
            .padding(.horizontal, 20)
        }
    }

    private func quickActionRow(icon: String, title: String, subtitle: String, color: Color, showDivider: Bool = true) -> some View {
        Button {
            // Placeholder action
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: icon)
                                .foregroundStyle(.white)
                                .font(.system(size: 16, weight: .semibold))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                if showDivider {
                    Divider()
                        .background(.white.opacity(0.1))
                        .padding(.leading, 72)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var familyMemberCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(familyMembers.enumerated()), id: \.offset) { index, member in
                    familyMemberCard(member: member, index: index)
                }
                addFamilyMemberCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private func familyMemberCard(member: FamilyMember, index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selectedFamilyMemberIndex = index
                showFamilyMemberDetail = true
            }
        } label: {
            VStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: member.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: member.icon)
                            .foregroundStyle(.white)
                            .font(.system(size: 32))
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                selectedFamilyMemberIndex == index ? Color.white : Color.clear,
                                lineWidth: 3
                            )
                    )

                VStack(spacing: 4) {
                    Text(member.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(member.role)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(width: 120)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .glassEffect(
                        selectedFamilyMemberIndex == index ? .regular.interactive() : .regular,
                        in: .rect(cornerRadius: 20)
                    )
            )
            .scaleEffect(selectedFamilyMemberIndex == index ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private var addFamilyMemberCard: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showAddFamilyMember = true
            }
        } label: {
            VStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
                            .font(.system(size: 32, weight: .medium))
                    )

                VStack(spacing: 4) {
                    Text("Add Member")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("New")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(width: 120)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showAddFamilyMember) {
            AddFamilyMemberSheet()
                .environment(familyMemberService)
        }
    }

    // MARK: - Bottom Navigation

    private var bottomNavigation: some View {
        GlassEffectContainer(spacing: 0) {
            HStack(spacing: 0) {
                navButton(icon: "sparkles", tab: .discover, label: "Discover")
                navButton(icon: "camera.fill", tab: .picture, label: "Picture")
                navButton(icon: "person.3.fill", tab: .family, label: "Family")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 8)
            .glassEffect(.regular, in: .rect(cornerRadius: 32))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func navButton(icon: String, tab: Tab, label: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.5))
                    .scaleEffect(selectedTab == tab ? 1.1 : 1.0)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Load and Sync

    private func loadAndSync() {
        // 1. Load from cache immediately for fast startup
        mealService.loadFromCache()
        familyMemberService.loadFromCache()

        // 2. Sync with remote in background
        Task {
            await syncManager.syncAll()
        }
    }
}

#Preview {
    ContentView()
        .environment(MealService())
        .environment(FamilyMemberService())
        .environment(SyncManager())
}
