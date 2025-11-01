//
//  Theme.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import SwiftUI

struct Theme {
    // Colors
    static let primary = Color(hex: "#7C3AED") // Violet 600
    static let accent = Color(hex: "#06B6D4") // Cyan 500
    static let success = Color(hex: "#10B981") // Green
    static let warning = Color(hex: "#F59E0B") // Orange
    static let danger = Color(hex: "#EF4444") // Red
    
    // Surfaces (Light)
    static let backgroundLight = Color(hex: "#F9FAFB")
    static let cardLight = Color.white
    static let surfaceLight = Color(hex: "#F3F4F6")
    
    // Surfaces (Dark)
    static let backgroundDark = Color(hex: "#0B122A")
    static let cardDark = Color(hex: "#0F172A")
    static let surfaceDark = Color(hex: "#1E293B")
    
    // Typography
    enum FontWeight {
        case regular, medium, semibold, bold
    }
    
    static func headingFont(size: CGFloat, weight: FontWeight = .bold) -> Font {
        let fontWeight: Font.Weight = {
            switch weight {
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            }
        }()
        // Using system font with Sora/Poppins style - would need custom font file for actual Sora/Poppins
        return .system(size: size, weight: fontWeight, design: .rounded)
    }
    
    static func bodyFont(size: CGFloat, weight: FontWeight = .regular) -> Font {
        let fontWeight: Font.Weight = {
            switch weight {
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            }
        }()
        return .system(size: size, weight: fontWeight, design: .default)
    }
    
    static func monospacedFont(size: CGFloat) -> Font {
        return .system(size: size, design: .monospaced)
    }
    
    // Spacing
    static let spacing: CGFloat = 8
    static let spacing2: CGFloat = 16
    static let spacing3: CGFloat = 24
    
    // Card styling
    static let cardCornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 16
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

