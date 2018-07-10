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
    
    func push(_ item: UIDynamicItem) {
        let pushBehavior = UIPushBehavior(items: [item], mode: .instantaneous)
        // push behavior configuration
        pushBehavior.magnitude = CGFloat(3.0) + CGFloat(2.0).arc4Random
        pushBehavior.angle = CGFloat.pi + CGFloat.pi.arc4Random
        pushBehavior.active = true
        // remove instantaneous push behavior once it's acted
        pushBehavior.action = { [weak self, unowned pushBehavior] in
            self?.removeChildBehavior(pushBehavior)
        }
        addChildBehavior(pushBehavior)
    }
    
    
    func snap(_ item: UIDynamicItem, snapPoint: CGPoint) {
        let snap = UISnapBehavior(item: item, snapTo: snapPoint)
        // more damping than default
        snap.damping = 0.4
        addChildBehavior(snap)
        // remove collision so items can layover on each other when snapping
        collisionBehavior.removeItem(item)
        
    }
    
    func add(_ item: UIDynamicItem) {
        collisionBehavior.addItem(item)
        itemBehavior.addItem(item)
        push(item)
    }
    
    func removeSnap(from item: UIDynamicItem) {
        childBehaviors.forEach { behavior in
            if let snap = behavior as? UISnapBehavior {
                removeChildBehavior(snap)
            }
        }
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
