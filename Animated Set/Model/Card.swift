//
//  Card.swift
//  Set
//
//  Created by Peter Wu on 4/23/18.
//  Copyright © 2018 Zero. All rights reserved.
//

import Foundation

struct Card: Hashable, CustomStringConvertible {
    var description: String {
        return "card # \(identifier)"
    }
    
    let color: Color
    let shape: Shape
    let numberOfShapes: NumberOfShapes
    let shading: Shading
    let identifier: Int
    private static var identifier: Int = 0
    static var all: [Card] {
        var cards = [Card]()
        for color in Color.all {
            for shape in Shape.all {
                for shading in Shading.all {
                    for numberOfShapes in NumberOfShapes.all {
                        cards.append(Card(color: color, shape: shape, numberOfShapes: numberOfShapes, shading: shading, identifier: makeIdentifier()))
                    }
                }
            }
        }
        return cards
    }
    enum NumberOfShapes: Int {
        
        case oneShape = 1
        case twoShape = 2
        case threeShape = 3
        static var all: [NumberOfShapes] {
            return [NumberOfShapes.oneShape, .twoShape, .threeShape]
        }
    }
    
    enum Color {
        case color1
        case color2
        case color3
        static var all: [Color] {
                return [Color.color1, .color2, .color3]
        }
    }
    
    enum Shape {
        case shape1
        case shape2
        case shape3
        static var all: [Shape] {
                return [Shape.shape1, .shape2, .shape3]
        }
    }
    
    enum Shading {
        case shading1
        case shading2
        case shading3
        static var all: [Shading] {
                return [Shading.shading1, .shading2, .shading3]
        }
    }
    
    init(color: Color, shape: Shape, numberOfShapes: NumberOfShapes, shading: Shading, identifier: Int) {
        self.color = color
        self.shape = shape
        self.numberOfShapes = numberOfShapes
        self.shading = shading
        self.identifier = identifier
    }
    
    private static func makeIdentifier() -> Int {
        identifier += 1
        return identifier
    }
    
}


