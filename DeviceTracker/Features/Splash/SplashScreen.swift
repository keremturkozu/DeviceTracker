import SwiftUI

struct SplashScreen: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var isActive = false
    @State private var opacity = 0.5
    @State private var scale = 0.8
    
    var body: some View {
        if isActive {
            // Onboarding durumuna göre ana ekrana veya onboarding ekranına yönlendir
            if hasCompletedOnboarding {
                RadarView()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        } else {
            ZStack {
                Color(UIColor.systemBackground)
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
                    // Animasyon
                    withAnimation(.easeInOut(duration: 1.0)) {
                        opacity = 1.0
                        scale = 1.0
                    }
                    
                    // Gecikme sonrası ana ekrana geç
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            isActive = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreen()
} 