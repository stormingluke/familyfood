//
//  GlassEffectContainer.swift
//  frindr
//
//  Glass effect container for grouping elements
//

import SwiftUI

struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    init(spacing: CGFloat = 12, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        VStack(spacing: spacing) {
            content()
        }
    }
}
