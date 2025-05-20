import SwiftUI
import StoreKit

struct NeumorphicBackground: View {
    var body: some View {
        ZStack {
            // Base background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "f0f2f5"),
                    Color(hex: "e4e9f2")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle pattern overlay
            GeometryReader { geometry in
                ZStack {
                    ForEach(0..<20, id: \.self) { i in
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(
                                width: CGFloat.random(in: geometry.size.width * 0.1...geometry.size.width * 0.3),
                                height: CGFloat.random(in: geometry.size.width * 0.1...geometry.size.width * 0.3)
                            )
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: 0...geometry.size.height)
                            )
                            .blur(radius: 30)
                    }
                }
            }
        }
    }
}

struct PremiumView: View {
    @StateObject private var helper = StoreKitHelper.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var selectedPlan: StoreKitHelper.SubscriptionType? = nil
    
    private let appBlue = Color(hex: "007AFF")
    
    var body: some View {
        ZStack {
            Color(hex: "f6f7fa").ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Modernized Title & subtitle
                        Text("Unlock Your Device's Full Power")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 32)
                        // Açıklama metni
                        Text("Get unlimited access to all features. Upgrade to Premium for full device tracking, instant alerts, and more.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                        
                        // Feature list
                        VStack(spacing: 0) {
                            featureRow(icon: "antenna.radiowaves.left.and.right", text: "Radar Detection")
                            Divider().padding(.horizontal, 18)
                            featureRow(icon: "mappin.and.ellipse", text: "Location Finding")
                            Divider().padding(.horizontal, 18)
                            featureRow(icon: "bell.fill", text: "Instant Alerts")
                            Divider().padding(.horizontal, 18)
                            featureRow(icon: "laptopcomputer.and.iphone", text: "Multi-Device Support")
                            Divider().padding(.horizontal, 18)
                            featureRow(icon: "map.fill", text: "Last Location Map")
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                        )
                        .padding(.horizontal, 12)
                        .padding(.top, 18)
                        
                        // Plan selection
                        VStack(spacing: 10) {
                            Text("Choose your plan")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.top, 18)
                                .padding(.bottom, 2)
                            ForEach([StoreKitHelper.SubscriptionType.weekly, .yearly, .lifetime], id: \.self) { plan in
                                planCard(plan: plan, isSelected: selectedPlan == plan) {
                                    selectedPlan = plan
                                }
                            }
                            Button(action: {
                                Task {
                                    do {
                                        let restored = try await helper.restorePurchases()
                                        // Optionally show a confirmation
                                    } catch {
                                        // Optionally show an error
                                    }
                                }
                            }) {
                                Text("Restore Purchases")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                        .padding(.top, 2)
                        Spacer(minLength: 24)
                    }
                }
                // Continue button sticky at the bottom
                VStack {
                    Button(action: {
                        if let plan = selectedPlan {
                            purchasePremium(plan: plan)
                        }
                    }) {
                        Text(selectedPlan == nil ? "Select a plan" : "Continue")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedPlan == nil ? Color.gray.opacity(0.4) : appBlue)
                            .cornerRadius(14)
                            .shadow(color: appBlue.opacity(0.12), radius: 6, x: 0, y: 2)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 10)
                    .disabled(selectedPlan == nil || isLoading)
                }
                .background(Color(hex: "f6f7fa").opacity(0.98))
            }
            .frame(maxWidth: 480)
            .background(Color.clear)
            .overlay(
                Group {
                    if let errorMessage = errorMessage {
                        VStack {
                            Spacer()
                            Text(errorMessage)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.9))
                                        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 3)
                                )
                                .padding(.horizontal, 30)
                            Spacer().frame(height: 80)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    self.errorMessage = nil
                                }
                            }
                        }
                    }
                }
            )
        }
    }
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(appBlue)
                .frame(width: 32, height: 32)
                .background(Circle().fill(appBlue.opacity(0.10)))
            Text(text)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.black)
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
    }
    
    private func planCard(plan: StoreKitHelper.SubscriptionType, isSelected: Bool, action: @escaping () -> Void) -> some View {
        let planName: String
        let planPrice: String
        let planPeriod: String
        let planSavings: String?
        let badgeText: String?
        let cardBackground: AnyView
        switch plan {
        case .weekly:
            let product = helper.products.first(where: { $0.id == plan.productId })
            planName = "Weekly Premium"
            planPrice = product?.displayPrice ?? "$1.99"
            planPeriod = "/week"
            planSavings = nil
            badgeText = "Limited Offer"
            cardBackground = AnyView(WeeklyPlanBackground(isSelected: isSelected))
        case .yearly:
            let product = helper.products.first(where: { $0.id == plan.productId })
            planName = "Yearly Premium"
            planPrice = product?.displayPrice ?? "$21.99"
            planPeriod = "/year"
            planSavings = nil
            badgeText = nil
            cardBackground = AnyView(Color.white)
        case .lifetime:
            let product = helper.products.first(where: { $0.id == plan.productId })
            planName = "Lifetime Access"
            planPrice = product?.displayPrice ?? "$44.99"
            planPeriod = "/lifetime"
            planSavings = nil
            badgeText = nil
            cardBackground = AnyView(Color.white)
        }
        return Button(action: action) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(planName)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.black)
                        if let badgeText = badgeText {
                            Text(badgeText)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 1.5)
                                .background(Capsule().fill(Color.orange))
                        }
                    }
                    HStack(spacing: 4) {
                        Text(planPrice + " " + planPeriod)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(appBlue)
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? appBlue : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private func purchasePremium(plan: StoreKitHelper.SubscriptionType) {
        isLoading = true
        Task {
            do {
                _ = try await helper.purchaseSubscription(type: plan)
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Premium activated!"
                    // Dismiss after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// Weekly plan background
struct WeeklyPlanBackground: View {
    var isSelected: Bool
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.orange.opacity(isSelected ? 0.18 : 0.10),
                Color.white
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    PremiumView()
} 
