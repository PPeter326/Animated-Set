//
//  PlayingCardsMainView.swift
//  Set
//
//  Created by Peter Wu on 5/17/18.
//  Copyright © 2018 Zero. All rights reserved.
//

import UIKit

class PlayingCardsMainView: UIView {
    
    struct AspectRatio {
        static let cardViewRectangle: CGFloat = 5.0 / 8.0
    }
    
    lazy var grid = Grid(layout: Grid.Layout.aspectRatio(AspectRatio.cardViewRectangle), frame: self.bounds)
    
    var orientationChanged = false
    var numberOfCardViews: Int = 0 {
        didSet {
            // recalculate grid every time number of cards are set
            grid.cellCount = numberOfCardViews
            
            // make empty cardViews for the additional cardViews
            // 2. get the index range for the additional cardviews
            var startingIndex = 0
            if oldValue > 0 {
                startingIndex = oldValue - 1
            }
            let endIndex = numberOfCardViews - 1
            for index in startingIndex...endIndex {
                guard let rect = grid[index] else { return }
                let cardView = makeEmptyCardView(rect: rect)
                addSubview(cardView)
                cardViews.append(cardView)
            }
        }
    }
    
    var cardViews: [CardView] = []
    var tempCardViews: [CardView] = []
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        orientationChanged = true
        layoutIfNeeded()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if orientationChanged {
            // update frame and reset orientation flag
            updateCardsFrame()
            orientationChanged = false
        }
    }
    
    /// Update each cardView's frame with the new CGRect from grid object
    func updateCardsFrame() {
        grid.frame = self.bounds
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.7, delay: 0, options: [.allowAnimatedContent], animations: {
            for (index, cardView) in self.cardViews.enumerated() {
                guard let rect = self.grid[index] else { return }
                cardView.frame = rect
                cardView.insetFrame()
            }
        })
    }
    func makeEmptyCardView(rect: CGRect) -> CardView {
        let cardView = CardView(frame: rect)
        cardView.contentMode = .redraw
        cardView.insetFrame()
        cardView.showNoSelection()
        cardView.alpha = 0
        return cardView
    }
    func reset() {
        self.cardViews.forEach{ $0.removeFromSuperview() }
        self.cardViews.removeAll()
        numberOfCardViews = 0
    }
    

}

