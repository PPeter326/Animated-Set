//
//  FlyBehavior.swift
//  Animated Set
//
//  Created by Peter Wu on 7/9/18.
//  Copyright © 2018 Zero. All rights reserved.
//

import UIKit

class FlyBehavior: UIDynamicBehavior {
    
    let collisionBehavior: UICollisionBehavior = {
        let behavior = UICollisionBehavior()
        behavior.translatesReferenceBoundsIntoBoundary = true
        return behavior
    }()
    
    func add(_ item: UIDynamicItem) {
        collisionBehavior.addItem(item)
    }
    
    func removeCollision(from item: UIDynamicItem) {
        collisionBehavior.removeItem(item)
    }
    
    
    override init() {
        super.init()
        addChildBehavior(collisionBehavior)
    }

}
