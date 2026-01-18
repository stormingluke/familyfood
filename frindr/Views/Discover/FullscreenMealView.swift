//
//  FullscreenMealView.swift
//  frindr
//
//  Created by Luke Caradine on 17/01/2026.
//

import SwiftUI

struct FullscreenMealView: View {
    @Environment(MealService.self) private var mealService
    @Binding var isPresented: Bool
    let meals: [Meal]
    let familyMembers: [FamilyMember]
    @State private var currentIndex: Int
    @State private var dragOffset: CGFloat = 0
    @State private var isCardFlipped = false

    init(isPresented: Binding<Bool>, startingIndex: Int, meals: [Meal], familyMembers: [FamilyMember]) {
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: startingIndex)
        self.meals = meals
        self.familyMembers = familyMembers
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color(red: 0.15, green: 0.1, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
                            mealCardView(meal: meal, index: index, screenHeight: geometry.size.height)
                                .frame(width: geometry.size.width)
                        }
                    }
                    .offset(x: -CGFloat(currentIndex) * geometry.size.width + dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.width
                            }
                            .onEnded { value in
                                handleSwipe(translation: value.translation.width, screenWidth: geometry.size.width)
                            }
                    )
                }

                navigationDots
                    .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - View Components

    private var topBar: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isPresented = false
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.8))
                    .glassEffect(.regular.interactive(), in: .circle)
            }

            Spacer()

            Text("\(currentIndex + 1) of \(meals.count)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .glassEffect(.regular, in: .capsule)
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 20)
    }

    private func mealCardView(meal: Meal, index: Int, screenHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            ZStack {
                if !isCardFlipped {
                    mealImageFront(meal: meal)
                        .rotation3DEffect(
                            .degrees(isCardFlipped ? 180 : 0),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .opacity(isCardFlipped ? 0 : 1)
                }

                if isCardFlipped {
                    actionButtonsBack(meal: meal)
                        .rotation3DEffect(
                            .degrees(isCardFlipped ? 0 : -180),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .opacity(isCardFlipped ? 1 : 0)
                }
            }
            .frame(height: screenHeight * 0.5)
            .onTapGesture {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isCardFlipped.toggle()
                }
            }

            detailsSection(meal: meal, screenHeight: screenHeight)
        }
        .padding(.horizontal, 24)
    }

    private func mealImageFront(meal: Meal) -> some View {
        ZStack {
            if let imageData = meal.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.system(size: 100))
                        .foregroundStyle(.white.opacity(0.3))
                )
            }

            VStack {
                Spacer()

                HStack {
                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                            .font(.caption)
                        Text("Tap to flip")
                            .font(.caption)
                    }
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .glassEffect(.regular, in: .capsule)
                    .padding(16)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }

    private func actionButtonsBack(meal: Meal) -> some View {
        VStack(spacing: 16) {
            Text("Meal Info")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 20)

            GlassEffectContainer(spacing: 12) {
                VStack(spacing: 12) {
                    infoButton(icon: "clock.fill", title: "When", subtitle: meal.relativeLastEaten, color: .blue)
                    infoButton(icon: "heart.fill", title: "Who liked it?", subtitle: "\(meal.eatenBy.count) family members", color: .pink)
                    infoButton(icon: "hourglass", title: "How long?", subtitle: meal.prepTime.displayTime, color: .purple)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .glassEffect(.regular, in: .rect(cornerRadius: 28))
        )
    }

    private func infoButton(icon: String, title: String, subtitle: String, color: Color) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isCardFlipped = false
            }
        } label: {
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
                            .font(.body)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
            )
        }
        .buttonStyle(.plain)
    }

    private func detailsSection(meal: Meal, screenHeight: CGFloat) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(meal.name)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                            .font(.subheadline)
                        Text(meal.cuisineType)
                            .font(.subheadline)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: meal.prepTime.icon)
                            .font(.subheadline)
                        Text(meal.prepTime.displayTime)
                            .font(.subheadline)
                    }
                }
                .foregroundStyle(.white.opacity(0.7))

                if meal.timesEaten > 0 {
                    Text("Eaten \(meal.timesEaten) times")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                }

                if !meal.eatenBy.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Liked by")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))

                        FlowLayout(spacing: 8) {
                            ForEach(familyMembers.filter { meal.eatenBy.contains($0.id) }, id: \.id) { member in
                                Text(member.name)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .glassEffect(.regular, in: .capsule)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .frame(maxHeight: screenHeight * 0.5)
    }

    private var navigationDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<meals.count, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Helper Methods

    private func handleSwipe(translation: CGFloat, screenWidth: CGFloat) {
        let threshold: CGFloat = screenWidth * 0.3

        if translation < -threshold && currentIndex < meals.count - 1 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentIndex += 1
                isCardFlipped = false
            }
        } else if translation > threshold && currentIndex > 0 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentIndex -= 1
                isCardFlipped = false
            }
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            dragOffset = 0
        }
    }
}
