//
//  Theme.swift
//  ACT prep
//
//  Centralized semantic colors and layout metrics so every surface adapts to
//  light/dark mode and to iPhone, iPad, and Mac idioms consistently.
//

import SwiftUI

extension Color {
    /// Page background behind grouped content.
    static var appGroupedBackground: Color { Color(uiColor: .systemGroupedBackground) }
    /// Card background sitting on `appGroupedBackground`.
    static var appSecondaryBackground: Color { Color(uiColor: .secondarySystemGroupedBackground) }
    /// Subtle fill for chips, badges, and inactive controls.
    static var appFill: Color { Color(uiColor: .tertiarySystemFill) }
    /// Separator hairlines.
    static var appSeparator: Color { Color(uiColor: .separator) }
}

enum Layout {
    /// Maximum readable width for long-form text on iPad and Mac.
    static let readableWidth: CGFloat = 720
    static let cardCorner: CGFloat = 16
    static let tileCorner: CGFloat = 14
}

extension View {
    /// Constrains content to a comfortable reading width and centers it, so
    /// wide iPad and Mac windows do not stretch text to the full window width.
    func readableWidth(_ width: CGFloat = Layout.readableWidth) -> some View {
        frame(maxWidth: width).frame(maxWidth: .infinity)
    }

    /// Standard card treatment used across the app.
    func cardBackground(cornerRadius: CGFloat = Layout.cardCorner) -> some View {
        background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

/// Adaptive grid columns: more columns on wider windows (iPad, Mac).
struct AdaptiveGrid {
    static func columns(minWidth: CGFloat = 160, spacing: CGFloat = 12) -> [GridItem] {
        [GridItem(.adaptive(minimum: minWidth), spacing: spacing)]
    }
}

/// Label style with the icon trailing the title, used for "Next ›" buttons.
struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.title
            configuration.icon
        }
    }
}

extension LabelStyle where Self == TrailingIconLabelStyle {
    static var trailingIcon: TrailingIconLabelStyle { TrailingIconLabelStyle() }
}

/// Small pill used for topic tags and lock badges.
struct TagPill: View {
    let text: String
    var symbol: String?
    var tint: Color = .accentColor

    var body: some View {
        HStack(spacing: 4) {
            if let symbol {
                Image(systemName: symbol)
            }
            Text(text)
        }
        .font(.caption2.bold())
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.15), in: Capsule())
        .foregroundStyle(tint)
    }
}
