//
//  DeviceTrackerApp.swift
//  DeviceTracker
//
//  Created by Kerem Türközü on 3.04.2025.
//

import SwiftUI
import SwiftData
import StoreKit

@main
struct DeviceTrackerApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @StateObject private var storeKitHelper = StoreKitHelper.shared
    
    // MARK: - SwiftData configuration
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Device.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .preferredColorScheme(.light) // Only light mode as requested
                .modelContainer(sharedModelContainer)
                .defaultAppFont() // SF Pro Rounded olarak ayarla
                .task {
                    // StoreKit entegrasyonu
                    // Önce ürünleri yükle
                    await storeKitHelper.loadProducts()
                    
                    // Satın alınmış ürünleri kontrol et
                    await storeKitHelper.updatePurchasedProducts()
                    
                    // App Store ile senkronize et, bazı durumlarda güncel verileri almak için gerekebilir
                    try? await AppStore.sync()
                    
                    // Tekrar durumu kontrol et, sync'ten sonra güncellenmiş olabilir
                    await storeKitHelper.updatePurchasedProducts()
                    
                    print("Premium status: \(storeKitHelper.isPremiumUser ? "Active" : "Not active")")
                }
        }
    }
}
