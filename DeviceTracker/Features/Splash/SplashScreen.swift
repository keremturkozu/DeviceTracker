import SwiftUI

struct SplashScreen: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("isPremiumUser") private var isPremiumUser: Bool = false
    @State private var isActive = false
    @State private var opacity = 0.5
    @State private var scale = 0.8
    @State private var showPremium = false
    
    var body: some View {
        if isActive {
            // Load main content with premium modal
            contentView()
                .sheet(isPresented: $showPremium) {
                    PremiumView()
                }
                .onAppear {
                    // Her uygulama açılışında premium kullanıcı değilse ekranı göster
                    if !isPremiumUser {
                        // Show premium screen after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showPremium = true
                        }
                    }
                }
        } else {
            // Splash animation
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // App Logo
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                    
                    // App Name
                    Text("DeviceTracker")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(Theme.primary)
                    
                    // Tagline
                    Text("Find your devices, effortlessly")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    // Animation
                    withAnimation(.easeInOut(duration: 1.0)) {
                        opacity = 1.0
                        scale = 1.0
                    }
                    
                    // Transition to main screen after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            isActive = true
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func contentView() -> some View {
        // Regular app content based on onboarding status
        if hasCompletedOnboarding {
            RadarView()
        } else {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        }
    }
}

#Preview {
    SplashScreen()
} 