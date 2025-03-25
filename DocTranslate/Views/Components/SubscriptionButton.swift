import SwiftUI

struct SubscriptionButton: View {
    @State private var isPro: Bool = false
    
    var body: some View {
        Button(action: toggleSubscription) {
            HStack(spacing: 4) {
                Image(systemName: isPro ? "star.fill" : "star")
                    .font(.system(size: 12))
                Text(isPro ? "Pro" : "Free")
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isPro ? Color.themePrimary : Color.gray.opacity(0.2))
            .foregroundColor(isPro ? .white : .black)
            .cornerRadius(AppTheme.CornerRadius.pill)
        }
        .accessibilityLabel(isPro ? "Pro Subscription Active" : "Upgrade to Pro")
        .padding(.trailing, AppTheme.Spacing.medium)
    }
    
    private func toggleSubscription() {
        isPro.toggle()
    }
}

struct SubscriptionButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SubscriptionButton()
                .previewDisplayName("Free Version")
            
            SubscriptionButton()
                .previewDisplayName("Pro Version")
                .environment(
                    \._isPro, true
                )
        }
    }
}
