//
//  Item.swift
//  CareBridgeAI
//
//  Created by user13 on 6/19/26.
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
