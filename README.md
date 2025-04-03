# Device Tracker

A Bluetooth device finder application built with SwiftUI that helps you locate and interact with nearby Bluetooth devices.

## Features

- **Device Discovery**: Scan for nearby Bluetooth devices and see them on a radar-like display
- **Distance Tracking**: View the approximate distance to each detected device
- **Device Details**: Access detailed information about each device
- **Sound Alert**: Trigger a sound on the device to help locate it
- **Location Tracking**: View the device's last known location
- **Chat Functionality**: Communicate with the device owner

## Technologies Used

- Swift & SwiftUI for the UI
- MVVM (Model-View-ViewModel) Architecture
- CoreBluetooth for Bluetooth functionality
- CoreLocation for location services
- SwiftData for data persistence
- Combine for reactive programming

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Project Structure

The project follows Clean Architecture principles and is organized into Core and Features:

### Core
- **Models**: Data models for the application
- **Services**: Bluetooth and Location services
- **Extensions**: Utility extensions
- **Utils**: Theme and utility classes

### Features
- **Radar**: Main view showing nearby devices
- **DeviceDetail**: Detailed view of selected device
- **Chat**: Chat functionality with device owners

## Getting Started

1. Clone the repository
2. Open `DeviceTracker.xcodeproj` in Xcode
3. Build and run the application on your device (not simulator for Bluetooth functionality)

## Screenshots

(Screenshots will be added as the app progresses)

## License

This project is licensed under the MIT License - see the LICENSE file for details. 