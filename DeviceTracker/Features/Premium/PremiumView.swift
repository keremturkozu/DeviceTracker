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
    @State var showInfoSheet = false
    @State private var canDismiss = false
    @State private var dismissCounter = 5
    @State private var dismissTimerProgress: CGFloat = 0.0
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var selectedPlan: PlanType = .yearly
    @State private var animateOffer = false
    
    // App theme colors
    private let appBlue = Color(hex: "007AFF") // iOS system blue
    
    enum PlanType: String, CaseIterable {
        case weekly = "Weekly"
        case yearly = "Yearly"
        case lifetime = "Lifetime"
        
        var price: String {
            switch self {
            case .weekly: return "$1.99"
            case .yearly: return "$21.99"
            case .lifetime: return "$44.99"
            }
        }
        
        var originalPrice: String? {
            switch self {
            case .weekly: return "$3.99"
            case .yearly: return nil
            case .lifetime: return "$69.99"
            }
        }
        
        var period: String {
            switch self {
            case .weekly: return "/ week"
            case .yearly: return "/ year"
            case .lifetime: return "/ lifetime"
            }
        }
        
        var weeklyEquivalent: Double {
            switch self {
            case .weekly: return 1.99
            case .yearly: return 21.99 / 52
            case .lifetime: return 44.99 / 104 // Estimating lifetime as 2 years for calculation
            }
        }
        
        var savings: String? {
            switch self {
            case .weekly: 
                return "50% OFF"
            case .yearly:
                let yearlyTotal = 21.99
                let weeklyTotal = 1.99 * 52
                let savingsPercent = Int((1 - (yearlyTotal / weeklyTotal)) * 100)
                return "\(savingsPercent)% Savings"
            case .lifetime:
                return nil // Removed savings for lifetime
            }
        }
    }
    
    // Timer to enable dismissal after 5 seconds
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Modern neumorphic background
                NeumorphicBackground()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        // Dismiss button with timer circle
                        ZStack {
                            Circle()
                                .stroke(lineWidth: 1.5)
                                .opacity(0.3)
                                .foregroundColor(Color.black)
                                .frame(width: 36, height: 36)
                            
                            Circle()
                                .trim(from: 0.0, to: dismissTimerProgress)
                                .stroke(style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                                .foregroundColor(Color.black)
                                .rotationEffect(Angle(degrees: 270.0))
                                .frame(width: 36, height: 36)
                            
                            Button {
                                if canDismiss {
                                    dismiss()
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "xmark")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(canDismiss ? Color.black.opacity(0.7) : Color.gray.opacity(0.4))
                                }
                            }
                            .disabled(!canDismiss)
                            
                            if !canDismiss {
                                Text("\(dismissCounter)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color.black)
                                    .offset(x: 14, y: 14)
                            }
                        }
                        .padding(.leading, 16)
                        
                        Spacer()
                        
                        Button {
                            restorePurchases()
                        } label: {
                            Text("Restore")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.1))
                                .cornerRadius(14)
                        }
                        .padding(.trailing, 16)
                    }
                    .padding(.top, 16)
                    
                    // Limited Time Offer
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "FF9500"), Color(hex: "FF3B30")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(height: 36)
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                            .padding(.horizontal, 20)
                        
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                            
                            Text("LIMITED TIME OFFER - 50% OFF TODAY")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: animateOffer ? 0 : -5)
                        .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animateOffer)
                        .onAppear {
                            animateOffer = true
                        }
                    }
                    .padding(.top, 6)
                    
                    // Compact content for single screen display
                    VStack(spacing: 12) {
                        // Pro title
                        Text("DeviceTracker Pro")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.top, 8)
                        
                        // Features
                        VStack(spacing: 6) {
                            Text("Premium Features")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 2)
                            
                            VStack(spacing: 6) {
                                FeatureCard(
                                    icon: "antenna.radiowaves.left.and.right",
                                    title: "Radar Detection",
                                    description: "Track devices with enhanced radar"
                                )
                                
                                FeatureCard(
                                    icon: "mappin.and.ellipse",
                                    title: "Location Finding",
                                    description: "Precise location tracking for all your devices"
                                )
                                
                                FeatureCard(
                                    icon: "bell.fill",
                                    title: "Instant Alerts",
                                    description: "Get notified when devices go out of range"
                                )
                                
                                FeatureCard(
                                    icon: "laptopcomputer.and.iphone",
                                    title: "Multi-Device Support",
                                    description: "Track all your Bluetooth devices in one place"
                                )
                                
                                FeatureCard(
                                    icon: "map.fill",
                                    title: "Last Location Map",
                                    description: "See the last known position of lost devices"
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Plan selection integrated into main content
                        VStack(spacing: 6) {
                            Text("Choose Your Plan")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 2)
                            
                            VStack(spacing: 6) {
                                ForEach(PlanType.allCases, id: \.rawValue) { plan in
                                    PlanSelectionCard(
                                        plan: plan,
                                        isSelected: selectedPlan == plan,
                                        action: {
                                            selectedPlan = plan
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Continue button
                        Button {
                            purchasePremium()
                        } label: {
                            ZStack {
                                Text("Continue")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(
                                            colors: [appBlue, appBlue.opacity(0.7)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                                    .opacity(isLoading ? 0.6 : 1.0)
                                
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(1.2)
                                }
                            }
                        }
                        .disabled(isLoading)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // No payments now text (non-button)
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 16))
                            
                            Text("No payments now")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black.opacity(0.8))
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 8)
                    }
                }
                
                // Error message overlay
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
        }
        .sheet(isPresented: $showInfoSheet) {
            SubscriptionInfoView()
        }
        .interactiveDismissDisabled(!canDismiss)
        .onReceive(timer) { _ in
            DispatchQueue.main.async {
                if dismissCounter > 0 {
                    dismissCounter -= 1
                    dismissTimerProgress = CGFloat(5 - dismissCounter) / 5.0
                    
                    if dismissCounter == 0 {
                        canDismiss = true
                    }
                }
            }
        }
        .onChange(of: helper.isPremiumUser) { _, isPremium in
            if isPremium {
                dismiss()
            }
        }
    }
    
    // MARK: - StoreKit Functions
    
    func purchasePremium() {
        isLoading = true
        
        Task {
            do {
                _ = try await helper.purchasePremium()
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    withAnimation {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func restorePurchases() {
        isLoading = true
        
        Task {
            do {
                let restored = try await helper.restorePurchases()
                DispatchQueue.main.async {
                    isLoading = false
                    if !restored {
                        withAnimation {
                            errorMessage = "No previous purchases found"
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    withAnimation {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}

struct PlanSelectionCard: View {
    let plan: PremiumView.PlanType
    let isSelected: Bool
    let action: () -> Void
    
    private let appBlue = Color(hex: "007AFF") // iOS system blue
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // Left side with plan name and savings badge
                VStack(alignment: .leading, spacing: 4) {
                    // Plan name
                    Text(plan.rawValue)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black.opacity(0.8))
                    
                    // Savings badge if applicable
                    if let savings = plan.savings {
                        Text(savings)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(appBlue)
                            )
                    }
                }
                .padding(.leading, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Right side with price
                VStack(alignment: .trailing, spacing: 0) {
                    if let originalPrice = plan.originalPrice {
                        Text(originalPrice)
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.5))
                            .strikethrough(true, color: .red)
                    }
                    
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(plan.price)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black.opacity(0.8))
                        
                        Text(plan.period)
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.5))
                    }
                }
                .padding(.trailing, 16)
                
                // Checkmark when selected
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(appBlue)
                            .frame(width: 22, height: 22)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 16)
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                        .padding(.trailing, 16)
                }
            }
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? appBlue : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.05))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.black.opacity(0.7))
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(Color.black.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 5)
    }
}

struct SubscriptionInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Subscription Details")
                        .font(.title2.weight(.bold))
                    
                    Text("• Weekly subscription at $1.99.")
                    Text("• Yearly subscription at $21.99.")
                    Text("• Lifetime purchase at $44.99.")
                    Text("• Payment will be charged to your Apple ID account at the confirmation of purchase.")
                    Text("• Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period.")
                    Text("• Account will be charged for renewal within 24 hours prior to the end of the current period.")
                    Text("• You can manage and cancel your subscriptions by going to your account settings on the App Store after purchase.")
                    Text("• Any unused portion of a free trial period, if offered, will be forfeited when you purchase a subscription.")
                }
                .font(.system(size: 16))
                
                Spacer()
            }
            .padding()
            .navigationTitle("Subscription Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    PremiumView()
} 
