//
//  DeviceTrackerApp.swift
//  DeviceTracker
//
//  Created by Kerem Türközü on 3.04.2025.
//

import SwiftUI
import SwiftData

@main
struct DeviceTrackerApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
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
        }
    }
}
