//
//  PlayingCardsMainView.swift
//  Set
//
//  Created by Peter Wu on 5/17/18.
//  Copyright © 2018 Zero. All rights reserved.
//

import UIKit

class PlayingCardsMainView: UIView {
    
    private struct AspectRatio {
        static let cardViewRectangle: CGFloat = 5.0 / 8.0
    }
    
    lazy var grid = Grid(layout: Grid.Layout.aspectRatio(AspectRatio.cardViewRectangle), frame: self.bounds)
//    private weak var timer: Timer?
    lazy var deckFrame = CGRect(x: self.frame.minX, y: self.frame.maxY, width: self.frame.width/20, height: self.frame.width/20)
    var numberOfCardViews: Int = 0 {
        didSet {
            // recalculate grid every time number of cards are set
            grid.cellCount = numberOfCardViews
//            layoutIfNeeded()
        }
    }
    
    var cardViews: [CardView] = []
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        print(#function)
//        grid.frame = self.bounds
//        layoutIfNeeded()
//        updateCardsFrame()
        setNeedsLayout()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        grid.frame = self.bounds

        print(#function)
        updateCardsFrame()
//        for (index, cardView) in self.cardViews.enumerated() {
//            guard let rect = self.grid[index] else { return }
//            let newRect = rect.insetBy(dx: rect.width / 10, dy: rect.height / 10)
//            cardView.frame = newRect
//        }
    }
    
    /// Update each cardView's frame with the new CGRect from grid object
    func updateCardsFrame() {
        print(#function)
//        animate(startingIndex: 0)
//        for index in cardViews.indices {
//            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
//                self.animate(index: index)
//            })
//        }
//        while index < (cardViews.count - 1) {
//            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
//                self.animate(index: index)
//                index += 1
//            })
//            timer?.invalidate()
//        }

        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.7, delay: 0, options: [.allowAnimatedContent], animations: {
            for (index, cardView) in self.cardViews.enumerated() {
                guard let rect = self.grid[index] else { return }
                let newRect = rect.insetBy(dx: rect.width / 10, dy: rect.height / 10)
                cardView.frame = newRect
            }
        })
    }
//    func animate(startingIndex: Int) {
//            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 1.0, delay: 1.0, options: [.layoutSubviews], animations: {
//                guard let rect = self.grid[startingIndex] else { return }
//                let newRect = rect.insetBy(dx: rect.width / 10, dy: rect.height / 10)
//                let cardView = self.cardViews[startingIndex]
//                cardView.frame = newRect
//            }, completion: { finished in
//                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 1.0, delay: 1.0, options: [.layoutSubviews], animations: {
//                    guard let rect = self.grid[(startingIndex + 1)] else { return }
//                    let newRect = rect.insetBy(dx: rect.width / 10, dy: rect.height / 10)
//                    let cardView = self.cardViews[(startingIndex + 1)]
//                    cardView.frame = newRect
//                }, completion: { finished in
//                    UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 1.0, delay: 1.0, options: [.layoutSubviews], animations: {
//                        guard let rect = self.grid[(startingIndex + 2)] else { return }
//                        let newRect = rect.insetBy(dx: rect.width / 10, dy: rect.height / 10)
//                        let cardView = self.cardViews[(startingIndex + 2)]
//                        cardView.frame = newRect
//                    }, completion: nil)
//                })
//            })
//    }
    
    func reset() {
        self.cardViews.forEach{ $0.removeFromSuperview() }
        self.cardViews.removeAll()
        numberOfCardViews = 0
    }
    

}


