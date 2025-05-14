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
    @AppStorage("isPremiumUser") private var isPremiumUser: Bool = false
    @State private var showPremium = false
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
                .preferredColorScheme(.light)
                .modelContainer(sharedModelContainer)
                .defaultAppFont()
                .task {
                    // StoreKit entegrasyonu
                    await storeKitHelper.loadProducts()
                    await storeKitHelper.updatePurchasedProducts()
                    try? await AppStore.sync()
                    await storeKitHelper.updatePurchasedProducts()
                    print("Premium status: \(storeKitHelper.isPremiumUser ? "Active" : "Not active")")
                }
        }
    }
}
