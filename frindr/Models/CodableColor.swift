//
//  CodableColor.swift
//  frindr
//
//  Created by Luke Caradine on 17/01/2026.
//

import SwiftUI

struct CodableColor: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }

    init(color: Color) {
        // Default approximations for common colors
        if color == .pink {
            (red, green, blue, opacity) = (1.0, 0.75, 0.8, 1.0)
        } else if color == .purple {
            (red, green, blue, opacity) = (0.75, 0.5, 1.0, 1.0)
        } else if color == .blue {
            (red, green, blue, opacity) = (0.0, 0.5, 1.0, 1.0)
        } else if color == .cyan {
            (red, green, blue, opacity) = (0.0, 1.0, 1.0, 1.0)
        } else if color == .red {
            (red, green, blue, opacity) = (1.0, 0.0, 0.0, 1.0)
        } else if color == .orange {
            (red, green, blue, opacity) = (1.0, 0.6, 0.0, 1.0)
        } else if color == .green {
            (red, green, blue, opacity) = (0.0, 1.0, 0.0, 1.0)
        } else if color == .teal {
            (red, green, blue, opacity) = (0.0, 0.5, 0.5, 1.0)
        } else {
            (red, green, blue, opacity) = (0.5, 0.5, 0.5, 1.0)
        }
    }

    init(red: Double, green: Double, blue: Double, opacity: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }
}
