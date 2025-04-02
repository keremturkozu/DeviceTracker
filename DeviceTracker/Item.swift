//
//  Item.swift
//  DeviceTracker
//
//  Created by Kerem Türközü on 3.04.2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
