import SwiftUI
import StoreKit

struct PremiumView: View {
    @StateObject private var helper = StoreKitHelper.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showInfoSheet = false
    @State private var canDismiss = false
    @State private var dismissCounter = 3
    @State private var dismissTimerProgress: CGFloat = 0.0
    @State private var isLoading = false // Ödeme işlemleri sırasında yükleniyor durumu
    @State private var errorMessage: String? = nil // Hata mesajları için
    @State private var price: String = "$1.99" // Varsayılan fiyat
    
    // Timer to enable dismissal after 3 seconds
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(white: 0.92),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button with timer circle
                HStack {
                    ZStack {
                        // Progress circle
                        Circle()
                            .stroke(lineWidth: 1.5)
                            .opacity(0.3)
                            .foregroundColor(Theme.primary)
                        
                        // Progress indicator
                        Circle()
                            .trim(from: 0.0, to: dismissTimerProgress)
                            .stroke(style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                            .foregroundColor(Theme.primary)
                            .rotationEffect(Angle(degrees: 270.0))
                        
                        // Close button
                        Button {
                            if canDismiss {
                                dismiss()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.8))
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(canDismiss ? .black.opacity(0.6) : .gray.opacity(0.4))
                            }
                            .frame(width: 30, height: 30)
                        }
                        .disabled(!canDismiss)
                        
                        // Countdown text
                        if !canDismiss {
                            Text("\(dismissCounter)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.primary)
                                .offset(x: 16, y: 16)
                        }
                    }
                    .frame(width: 40, height: 40)
                    .padding()
                    
                    Spacer()
                    
                    Button {
                        restorePurchases()
                    } label: {
                        Text("Restore")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.primary)
                    }
                    .padding()
                }
                
                // Premium graphic image
                Image(systemName: "star.square.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .foregroundColor(Theme.primary)
                    .padding(.top, 10)
                
                // Premium title
                Text("DeviceTracker Pro")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primary)
                
                // Spacer to push content to the bottom
                Spacer()
                
                // Premium content
                VStack(spacing: 25) {
                    // Special offer tag
                    Text("Limited Time Offer!")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(20)
                    
                    // Price
                    Text("\(price)/Week")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                    
                    // Discount badge
                    Text("Save 30% Now")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color(hex: "FFD700").opacity(0.7))
                        )
                    
                    // Features List
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "checkmark.circle.fill", text: "Real-time tracking for all devices")
                        FeatureRow(icon: "checkmark.circle.fill", text: "Instant alerts when devices go out of range")
                        FeatureRow(icon: "checkmark.circle.fill", text: "Advanced device statistics")
                        FeatureRow(icon: "checkmark.circle.fill", text: "No advertisements")
                    }
                    .padding(.horizontal)
                    
                    // Continue button
                    Button {
                        purchasePremium()
                    } label: {
                        ZStack {
                            Text("Continue")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.primary)
                                .cornerRadius(16)
                                .shadow(color: Theme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                                .opacity(isLoading ? 0.5 : 1.0)
                            
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.5)
                            }
                        }
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 20)
                    
                    // No payment now
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(Theme.primary)
                        
                        Button {
                            showInfoSheet = true
                        } label: {
                            Text("Subscription Info")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .underline()
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding()
                .background(
                    Rectangle()
                        .fill(Color.white)
                        .cornerRadius(30, corners: [.topLeft, .topRight])
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
                )
            }
            
            // Hata mesajı
            if let errorMessage = errorMessage {
                VStack {
                    Spacer()
                    
                    Text(errorMessage)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(10)
                        .padding()
                    
                    Spacer().frame(height: 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    // 3 saniye sonra hata mesajını kaldır
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            self.errorMessage = nil
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
            if dismissCounter > 0 {
                dismissCounter -= 1
                dismissTimerProgress = CGFloat(3 - dismissCounter) / 3.0
                
                if dismissCounter == 0 {
                    canDismiss = true
                }
            }
        }
        .onChange(of: helper.isPremiumUser) { _, isPremium in
            if isPremium {
                dismiss()
            }
        }
        .task {
            // Ürün bilgisini App Store'dan al
            if let product = helper.products.first {
                self.price = product.displayPrice
            }
        }
    }
    
    // MARK: - StoreKit Functions
    
    func purchasePremium() {
        isLoading = true
        
        Task {
            do {
                _ = try await helper.purchasePremium()
                // Premium durumu başarıyla değiştirildiğinde onChange tetiklenecek ve ekranı kapatacak
            } catch {
                isLoading = false
                withAnimation {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func restorePurchases() {
        isLoading = true
        
        Task {
            do {
                let restored = try await helper.restorePurchases()
                if !restored {
                    withAnimation {
                        errorMessage = "No previous purchases found"
                    }
                }
                isLoading = false
            } catch {
                isLoading = false
                withAnimation {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.system(size: 18))
            
            Text(text)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct SubscriptionInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Subscription Details")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("• Weekly subscription at $1.99.")
                    Text("• Payment will be charged to your Apple ID account at the confirmation of purchase.")
                    Text("• Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period.")
                    Text("• Account will be charged for renewal within 24 hours prior to the end of the current period.")
                    Text("• You can manage and cancel your subscriptions by going to your account settings on the App Store after purchase.")
                    Text("• Any unused portion of a free trial period, if offered, will be forfeited when you purchase a subscription.")
                }
                .font(.system(size: 16, design: .rounded))
                
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