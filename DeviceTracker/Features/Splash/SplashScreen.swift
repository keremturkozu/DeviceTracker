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
                        // Ekranı hemen göster, gecikme olmadan
                        showPremium = true
                    }
                }
        } else {
            // Splash animation
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // App logo with soft edges and stroke
                    ZStack {
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 30))
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.white, lineWidth: 4)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
                    }
                    
                    VStack(spacing: 8) {
                        // App name with shadow for elegant appearance
                        Text("DeviceTracker")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primary)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        
                        // Tagline/subtitle
                        Text("Find your devices easily")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundColor(Color.gray)
                    }
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