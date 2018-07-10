//
//  Card.swift
//  Concentration
//
//  Created by Peter Wu on 3/22/18.
//  Copyright © 2018 Zero. All rights reserved.
//

import Foundation

struct Card: Hashable {
    var hashValue: Int { return identifier}
    
    
    private(set) static var flipCount = 0
    
//    var isFaceUp = false
//    var isMatched = false
    private var identifier: Int
    private(set) var flippedCount = 0
    var date: Date?
    
    private static var identifierFactory = 0
    
    private static func getUniqueIdentifier() -> Int {
        identifierFactory += 1
        return identifierFactory
    }
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    static func increaseFlipCount() {
        self.flipCount += 1
    }
    
    static func resetFlipCount() {
        self.flipCount = 0
    }
    
    mutating func increaseFlipCount() {
        flippedCount += 1
    }
    
    mutating func resetFlipCount() {
        flippedCount = 0
    }
    
    
    init() {
        self.identifier = Card.getUniqueIdentifier()
    }
}
