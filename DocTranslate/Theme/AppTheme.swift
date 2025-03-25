//
//  AppTheme.swift
//  document-translator-v3
//
//  Created by Sebastian Mendo on 1/11/25.
//

import UIKit
import SwiftUI

// MARK: - AppTheme

struct AppTheme {

    // MARK: - Colors
    struct Colors {
        // Primary colors
        static let primary = UIColor(hex: "#8A56E8") // Purple
        static let primaryDark = UIColor(hex: "#7040D6")
        static let primaryLight = UIColor(hex: "#A980F5")
        static let primaryBackground = UIColor(hex: "#F4EDFF")

        // Neutral colors
        static let neutralDark = UIColor(hex: "#1C1C1E") // Dark gray (almost black)
        static let neutralMedium = UIColor(hex: "#8E8E93") // Medium gray
        static let neutralLight = UIColor(hex: "#E5E5EA") // Light gray
        
        // Semantic colors
        static let success = UIColor(hex: "#34C759") // Green
        static let warning = UIColor(hex: "#FF9500") // Orange
        static let error = UIColor(hex: "#FF3B30") // Red
        static let info = UIColor(hex: "#007AFF") // Blue (same as primary)

        // Background colors
        static let backgroundPrimary = UIColor.systemBackground
        static let backgroundSecondary = UIColor.secondarySystemBackground
        static let backgroundTertiary = UIColor.tertiarySystemBackground
        static let groupedBackground = UIColor.systemGroupedBackground
        
        // Content colors
        static let textPrimary = UIColor.label
        static let textSecondary = UIColor.secondaryLabel
        static let textTertiary = UIColor.tertiaryLabel
        static let textPlaceholder = UIColor.placeholderText
        
        // Interactive elements
        static let buttonPrimary = UIColor(hex: "#007AFF") // Blue
        static let buttonSecondary = UIColor.secondarySystemBackground
        static let buttonDisabled = UIColor.systemGray4
        static let buttonText = UIColor.white
        static let buttonTextSecondary = UIColor(hex: "#007AFF")
        
        // Dividers and separators
        static let separator = UIColor.separator
        static let opaqueSeparator = UIColor.opaqueSeparator
        
        // Document scanner specific
        static let documentScannerBackground = UIColor.systemGray6
        static let enhancementToggleOn = UIColor(hex: "#34C759") // Green
    }

    // MARK: - Typography
    struct Typography {
        // MARK: - Scaling factors for accessibility
        static var scalingFactor: CGFloat {
            return UIFontMetrics.default.scaledValue(for: 1.0)
        }
        
        // MARK: - Headings (SF Pro for better Apple HIG compliance)
        static let largeTitle = Font.system(size: 34 * scalingFactor, weight: .bold, design: .default)
        static let title1 = Font.system(size: 28 * scalingFactor, weight: .semibold, design: .default)
        static let title2 = Font.system(size: 22 * scalingFactor, weight: .semibold, design: .default)
        static let title3 = Font.system(size: 20 * scalingFactor, weight: .semibold, design: .default)
        static let headline = Font.system(size: 17 * scalingFactor, weight: .semibold, design: .default)
        static let subheadline = Font.system(size: 15 * scalingFactor, weight: .semibold, design: .default)

        // MARK: - Body Text (SF Pro for better Apple HIG compliance)
        static let body = Font.system(size: 17 * scalingFactor, weight: .regular, design: .default)
        static let callout = Font.system(size: 16 * scalingFactor, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13 * scalingFactor, weight: .regular, design: .default)
        static let caption1 = Font.system(size: 12 * scalingFactor, weight: .regular, design: .default)
        static let caption2 = Font.system(size: 11 * scalingFactor, weight: .regular, design: .default)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xsmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 32
        static let xxlarge: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 10
        static let large: CGFloat = 14
        static let xl: CGFloat = 20
        static let pill: CGFloat = 9999
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let small = ShadowStyle(color: .black, opacity: 0.1, radius: 2, x: 0, y: 1)
        static let medium = ShadowStyle(color: .black, opacity: 0.1, radius: 4, x: 0, y: 2)
        static let large = ShadowStyle(color: .black, opacity: 0.15, radius: 10, x: 0, y: 4)
        
        struct ShadowStyle {
            let color: Color
            let opacity: Double
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
    }
    
    // MARK: - Animation
    struct Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
    }
    
    // MARK: - Layout
    struct Layout {
        static let buttonHeight: CGFloat = 44
        static let minimumTouchTargetSize: CGFloat = 44
        static let standardPadding: CGFloat = 16
        static let contentWidth: CGFloat = 600 // Max width for content on large screens
    }
}

// MARK: - UIColor Extension for Hex Color
extension UIColor {
    convenience init(hex: String) {
        let hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

// MARK: - SwiftUI Color Extensions
extension Color {
    // Primary Colors
    static let themePrimary = Color(AppTheme.Colors.primary)
    static let themePrimaryDark = Color(AppTheme.Colors.primaryDark)
    static let themePrimaryLight = Color(AppTheme.Colors.primaryLight)
    static let themePrimaryBackground = Color(AppTheme.Colors.primaryBackground)
    
    // Neutral Colors
    static let themeNeutralDark = Color(AppTheme.Colors.neutralDark)
    static let themeNeutralMedium = Color(AppTheme.Colors.neutralMedium)
    static let themeNeutralLight = Color(AppTheme.Colors.neutralLight)
    
    // Semantic Colors
    static let themeSuccess = Color(AppTheme.Colors.success)
    static let themeWarning = Color(AppTheme.Colors.warning)
    static let themeError = Color(AppTheme.Colors.error)
    static let themeInfo = Color(AppTheme.Colors.info)
    
    // Background Colors
    static let themeBackgroundPrimary = Color(AppTheme.Colors.backgroundPrimary)
    static let themeBackgroundSecondary = Color(AppTheme.Colors.backgroundSecondary)
    static let themeBackgroundTertiary = Color(AppTheme.Colors.backgroundTertiary)
    static let themeGroupedBackground = Color(AppTheme.Colors.groupedBackground)
    
    // Text Colors
    static let themeTextPrimary = Color(AppTheme.Colors.textPrimary)
    static let themeTextSecondary = Color(AppTheme.Colors.textSecondary)
    static let themeTextTertiary = Color(AppTheme.Colors.textTertiary)
    static let themeTextPlaceholder = Color(AppTheme.Colors.textPlaceholder)
    
    // Button Colors
    static let themeButtonPrimary = Color(AppTheme.Colors.buttonPrimary)
    static let themeButtonSecondary = Color(AppTheme.Colors.buttonSecondary)
    static let themeButtonDisabled = Color(AppTheme.Colors.buttonDisabled)
    static let themeButtonText = Color(AppTheme.Colors.buttonText)
    static let themeButtonTextSecondary = Color(AppTheme.Colors.buttonTextSecondary)
    
    // Dividers and Separators
    static let themeSeparator = Color(AppTheme.Colors.separator)
    static let themeOpaqueSeparator = Color(AppTheme.Colors.opaqueSeparator)
    
    // Document Scanner Specific
    static let themeDocumentScannerBackground = Color(AppTheme.Colors.documentScannerBackground)
    static let themeEnhancementToggleOn = Color(AppTheme.Colors.enhancementToggleOn)
}

// MARK: - View Extension for Common Styles
extension View {
    // Apply primary button style
    func primaryButtonStyle() -> some View {
        self.padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .frame(height: AppTheme.Layout.buttonHeight)
            .background(Color.themeButtonPrimary)
            .foregroundColor(Color.themeButtonText)
            .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    // Apply secondary button style
    func secondaryButtonStyle() -> some View {
        self.padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .frame(height: AppTheme.Layout.buttonHeight)
            .background(Color.themeButtonSecondary)
            .foregroundColor(Color.themeButtonTextSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    // Apply card style
    func cardStyle() -> some View {
        self.padding(AppTheme.Spacing.medium)
            .background(Color.themeBackgroundPrimary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .shadow(color: AppTheme.Shadow.medium.color.opacity(AppTheme.Shadow.medium.opacity),
                   radius: AppTheme.Shadow.medium.radius,
                   x: AppTheme.Shadow.medium.x,
                   y: AppTheme.Shadow.medium.y)
    }
    
    // Apply standard content padding
    func contentPadding() -> some View {
        self.padding(AppTheme.Spacing.medium)
    }
    
    // Apply error message style
    func errorStyle() -> some View {
        self.padding()
            .background(Color.themeError.opacity(0.1))
            .foregroundColor(Color.themeError)
            .cornerRadius(AppTheme.CornerRadius.small)
    }
    
    // Apply warning message style
    func warningStyle() -> some View {
        self.padding()
            .background(Color.themeWarning.opacity(0.1))
            .foregroundColor(Color.themeWarning)
            .cornerRadius(AppTheme.CornerRadius.small)
    }
    
    // Apply success message style
    func successStyle() -> some View {
        self.padding()
            .background(Color.themeSuccess.opacity(0.1))
            .foregroundColor(Color.themeSuccess)
            .cornerRadius(AppTheme.CornerRadius.small)
    }
}
