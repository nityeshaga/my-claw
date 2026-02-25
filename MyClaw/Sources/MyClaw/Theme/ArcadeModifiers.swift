import SwiftUI

// MARK: - Card Modifier

struct ArcadeCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 10
    var borderColor: Color = .white.opacity(0.12)

    func body(content: Content) -> some View {
        content
            .background(Theme.surfaceDark, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
    }
}

// MARK: - Status Card — colored top bar + tinted bg + glow border

struct StatusCardModifier: ViewModifier {
    let statusColor: Color
    var cornerRadius: CGFloat = 10
    var isActive: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(statusColor.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Theme.surfaceDark)
                            .padding(1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(statusColor.opacity(isActive ? 0.5 : 0.3), lineWidth: isActive ? 1.5 : 1)
            )
            .overlay(alignment: .top) {
                UnevenRoundedRectangle(
                    topLeadingRadius: cornerRadius,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: cornerRadius
                )
                .fill(statusColor)
                .frame(height: 3)
            }
            .if(isActive) { view in
                view.shadow(color: statusColor.opacity(0.5), radius: 12)
            }
    }
}

// MARK: - Glow Effect

struct GlowModifier: ViewModifier {
    let color: Color
    var radius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius)
            .shadow(color: color.opacity(0.2), radius: radius * 0.5)
    }
}

// MARK: - Subtle Glow

struct SubtleGlowModifier: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: 6)
    }
}

// MARK: - View Extensions

extension View {
    func arcadeCard(cornerRadius: CGFloat = 10, borderColor: Color = .white.opacity(0.12)) -> some View {
        modifier(ArcadeCardModifier(cornerRadius: cornerRadius, borderColor: borderColor))
    }

    func statusCard(_ statusColor: Color, cornerRadius: CGFloat = 10, isActive: Bool = false) -> some View {
        modifier(StatusCardModifier(statusColor: statusColor, cornerRadius: cornerRadius, isActive: isActive))
    }

    func glowEffect(_ color: Color, radius: CGFloat = 12) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }

    func subtleGlow(_ color: Color) -> some View {
        modifier(SubtleGlowModifier(color: color))
    }

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Pulsing Status Indicator

struct StatusDot: View {
    let color: Color
    var size: CGFloat = 8
    var isPulsing: Bool = false

    @State private var pulseOpacity: Double = 1.0

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .shadow(color: color.opacity(0.7), radius: 6)
            .shadow(color: color.opacity(0.3), radius: 10)
            .overlay(
                Circle()
                    .fill(color.opacity(0.4))
                    .frame(width: size + 10, height: size + 10)
                    .opacity(isPulsing ? pulseOpacity : 0)
            )
            .onAppear {
                guard isPulsing else { return }
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulseOpacity = 0.05
                }
            }
    }
}

// MARK: - Arcade Badge

struct ArcadeBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.uppercased())
            .font(Theme.codeMono)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.2), in: Capsule())
            .overlay(Capsule().strokeBorder(color.opacity(0.4), lineWidth: 1))
            .shadow(color: color.opacity(0.3), radius: 4)
    }
}

// MARK: - Section Header with accent underline

struct ArcadeSectionHeader: View {
    let title: String
    var color: Color = Theme.terracotta

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(Theme.headingMono)
                .foregroundStyle(Theme.textPrimary)
                .shadow(color: color.opacity(0.3), radius: 4)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.8), color.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .frame(maxWidth: 200)
        }
    }
}
