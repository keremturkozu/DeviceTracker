import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Find Your Devices",
            description: "DeviceTracker helps you locate all your Bluetooth devices nearby. View their signal strength and distance in real-time.",
            imageName: "onboarding-find",
            imageSize: CGSize(width: 280, height: 280)
        ),
        OnboardingPage(
            title: "Connect & Control",
            description: "Connect to your devices with a single tap. Play sound, check battery levels, and control device settings remotely.",
            imageName: "onboarding-connect",
            imageSize: CGSize(width: 280, height: 280)
        ),
        OnboardingPage(
            title: "Locate on Map",
            description: "View the exact location of your devices on a map. Get directions and never lose your valuable devices again.",
            imageName: "onboarding-map",
            imageSize: CGSize(width: 280, height: 260)
        ),
        OnboardingPage(
            title: "Stay Connected",
            description: "Chat with your connected devices, receive notifications when devices go out of range, and share device access with family.",
            imageName: "onboarding-chat",
            imageSize: CGSize(width: 300, height: 280)
        )
    ]
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.85, green: 0.94, blue: 1.0),
                    Color(red: 0.97, green: 0.97, blue: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                // Skip button
                if currentPage < pages.count - 1 {
                    HStack {
                        Spacer()
                        Button("Skip") {
                            hasCompletedOnboarding = true
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        .foregroundColor(Theme.primary)
                        .font(.system(size: 17, weight: .semibold))
                    }
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        pageView(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Page indicator dots and button
                VStack(spacing: 20) {
                    // Custom page indicator
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Theme.primary : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    .padding(.bottom, 15)
                    
                    // Next or Start button
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            hasCompletedOnboarding = true
                        }
                    }) {
                        HStack {
                            Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            if currentPage < pages.count - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.primary)
                        .cornerRadius(16)
                        .shadow(color: Theme.primary.opacity(0.3), radius: 10, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    @ViewBuilder
    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 30) {
            Spacer(minLength: 30)
            
            // Onboarding image
            Image(page.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: page.imageSize.width, height: page.imageSize.height)
                .padding(.horizontal)
                .accessibilityHidden(true)
            
            Spacer(minLength: 30)
            
            VStack(spacing: 20) {
                // Title
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Theme.primary)
                    .multilineTextAlignment(.center)
                
                // Description
                Text(page.description)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 30)
            }
            
            Spacer(minLength: 90)
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let imageSize: CGSize
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
} 