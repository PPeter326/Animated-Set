//
//  FlyBehavior.swift
//  Animated Set
//
//  Created by Peter Wu on 7/9/18.
//  Copyright © 2018 Zero. All rights reserved.
//

import UIKit

class FlyBehavior: UIDynamicBehavior {
    
    lazy var collisionBehavior: UICollisionBehavior = {
        let behavior = UICollisionBehavior()
        behavior.translatesReferenceBoundsIntoBoundary = true
        return behavior
    }()
    
    lazy var itemBehavior: UIDynamicItemBehavior = {
        let behavior = UIDynamicItemBehavior()
        behavior.elasticity = 0.8
        behavior.resistance = 0
        return behavior
    }()
    
    func addDynamicBehavior(_ items: [UIDynamicItem]) {
        for item in items {
            itemBehavior.addItem(item)
        }
    }
    
    func add(_ item: UIDynamicItem) {
        collisionBehavior.addItem(item)
        itemBehavior.addItem(item)
    }
    
    func removeCollision(from item: UIDynamicItem) {
        collisionBehavior.removeItem(item)
    }
    
    func removeDynamicBehavior(from item: UIDynamicItem) {
        itemBehavior.removeItem(item)
    }
    
    
    override init() {
        super.init()
        addChildBehavior(collisionBehavior)
        addChildBehavior(itemBehavior)
    }

}
