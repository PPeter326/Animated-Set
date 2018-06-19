//
//  ViewController.swift
//  Set
//
//  Created by Peter Wu on 4/17/18.
//  Copyright © 2018 Zero. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    // MARK: - UI Elements -
    
    
    @IBOutlet weak var playingCardsMainView: PlayingCardsMainView! {
        didSet {
            // make new cardviews
            makeCardViews()
            // add swipe and rotate gestures to deal and shuffle, respectively
            let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(swipeDownToDeal(_:)))
            swipeDown.direction = .down
            playingCardsMainView.addGestureRecognizer(swipeDown)
            let rotate = UIRotationGestureRecognizer(target: self, action: #selector(rotateToShuffle(_:)))
            playingCardsMainView.addGestureRecognizer(rotate)
        }
    }
    
    @IBOutlet weak var scoreLabel: UILabel! {
        didSet {
            scoreLabel.attributedText = updateAttributedString("SCORE: 0")
        }
    }

    var score: Int = 0 {
        didSet {
            let scoreString = "SCORE: \(score)"
            scoreLabel.attributedText = updateAttributedString(scoreString)
            
        }
    }
    @IBOutlet weak var dealCardButton: UIButton! {
        didSet {
            dealCardButton.layer.cornerRadius = 8.0
        }
    }
    
    var selectedCardViews = [CardView]() {
        didSet {
            assert(selectedCardViews.count < 4, "invalid number of selected card views")
            // reset cardviews style on prior selected cards
            for cardView in oldValue {
                cardView.layer.borderWidth = cardView.frame.width / 100
                cardView.layer.borderColor = #colorLiteral(red: 0.06274510175, green: 0, blue: 0.1921568662, alpha: 1)
            }
            // show border on new selected cards
            for cardView in selectedCardViews {
                cardView.layer.borderWidth = cardView.frame.width / 15
                cardView.layer.borderColor = #colorLiteral(red: 0, green: 0.9914394021, blue: 1, alpha: 1).cgColor
            }
            if let matched = set.matched {
                if matched {
                    selectedCardViews = selectedCardViews.map { (cardView) -> CardView in
                        cardView.layer.borderWidth = cardView.frame.width / 15
                        cardView.layer.borderColor =  UIColor.green.cgColor
                        return cardView
                    }
                } else {
                    selectedCardViews = selectedCardViews.map { (cardView) -> CardView in
                        cardView.layer.borderWidth = cardView.frame.width / 15
                        cardView.layer.borderColor =  UIColor.red.cgColor
                        return cardView
                    }
                }
            }
        }
    }
    
    // MARK: - Game Properties -
    private var set = Set()
    
    // MARK: Card Attributes
    private let colorDictionary: [Card.Color: UIColor] = [
        .color1: #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1),
        .color2: #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1),
        .color3: #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
    ]
    
    private let shapeDictionary: [Card.Shape: CardView.Shape] = [
        .shape1: CardView.Shape.diamond,
        .shape2: CardView.Shape.oval,
        .shape3: CardView.Shape.squiggle
    ]
    
    private let shadingDictionary: [Card.Shading: CardView.Shade] = [
        .shading1: CardView.Shade.solid,
        .shading2: CardView.Shade.striped,
        .shading3: CardView.Shade.unfilled
    ]
    
    // MARK: - View Config -
    
    
    // MARK: - User Actions -
    
    @objc func selectCard( _ gestureRecognizer: UITapGestureRecognizer) {
        
        if gestureRecognizer.state == .ended {
            // tells set to select card
            let cardView = gestureRecognizer.view as! CardView
            let cardViewIndex = playingCardsMainView.cardViews.index(of: cardView)!
            let selectedCard = set.playedCards[cardViewIndex]
            set.selectCard(card: selectedCard) { result in
                switch result {
                case .selected:
                    selectedCardViews.append(cardView)
                    // animate card views if it's matched
                    if let matched = set.matched, matched {
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: 1.0,
                            delay: 0,
                            options: [UIViewAnimationOptions.transitionCrossDissolve],
                            animations: {
                                self.selectedCardViews.forEach { cardView in
                                    cardView.alpha = 0
                                }
                            }
                        )
                    }
                case .deselected:
                    guard let index = selectedCardViews.index(of: cardView) else { return }
                    selectedCardViews.remove(at: index)
                case .matched:
                    if set.deck.isEmpty {
                        // If deck is empty, then the views are shifted.  There are now less card views than before (for ex 21 -> 18)
                        // 1. first make the matched (also selected) card views disappear but keep the rest of the cards intact
                        
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: 1.0,
                            delay: 0,
                            options: [UIViewAnimationOptions.curveEaseIn],
                            animations: {
                                self.selectedCardViews.forEach{ $0.alpha = 0}
                            }, completion: { position in
                                // remove the selected cardviews
                                for cardView in self.selectedCardViews {
                                    cardView.removeFromSuperview()
                                    self.playingCardsMainView.cardViews.remove(at: self.playingCardsMainView.cardViews.index(of: cardView)!)
                                }
                                self.selectedCardViews.removeAll()
                                // set the new frames and animate
                                self.playingCardsMainView.numberOfCardViews = self.set.playedCards.count
                                // disable dealcard button
                                self.dealCard(disable: true)
                                // get the index of the card from played card
                                let index = self.set.playedCards.index(of: selectedCard)!
                                // get the selectedCardview from the new index
                                let updatedSelectedCardView = self.playingCardsMainView.cardViews[index]
                                // update the selectedCardViews Array
                                self.selectedCardViews.append(updatedSelectedCardView)
                            }
                        )
                        // then the rest of cards shift to new location
                        // then the cards enlarge to new frame
                        // update cardviews for the new set of played cards
//                        for (index, card) in set.playedCards.enumerated() {
//                            makeCardView(cardView: playingCardsMainView.cardViews[index], card: card)
//                        }
                    } else { // if deck is not empty, number of cardviews remains the same or more.  Simply update the cardviews for cards being replaced.
                        makeCardViews()
                        selectedCardViews.removeAll()
                        selectedCardViews.append(cardView)
                    }
                case .noMatch:
                    selectedCardViews.removeAll()
                    selectedCardViews.append(cardView)
                default: break
                }
                // update score
                self.score = set.score
            }
        }
    }
    @IBAction func newGameButtonTouched(_ sender: UIButton) {
        // reset game
        set.reset()
        // clear selectedCardViews and card views
        self.selectedCardViews.removeAll()
        playingCardsMainView.reset()
        // update card views
        makeCardViews()
        // update score
        score = set.score
        dealCard(disable: false)
        
    }
    
    @IBAction func dealCardButtonTouched(_ sender: UIButton) {
        dealCards()
    }
    
    @objc func swipeDownToDeal(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            dealCards()
        }
    }
    
    @objc func rotateToShuffle(_ gestureRecognizer: UIGestureRecognizer) {
        
        switch gestureRecognizer.state {
        case .ended:
            // shuffle cards if deck isn't empty, and a match hasn't taken place yet
            if !set.deck.isEmpty && set.selectedCards.count < 3 {
                // clear selection cards
                selectedCardViews.removeAll()
                // shuffle remaining cards in play and deck
                set.shuffleRemainingCards()
                // update cardViews
                makeCardViews()
            }
        default: break
        }
        

    }
    private func updateAttributedString(_ string: String) -> NSAttributedString {
        var font = UIFont.preferredFont(forTextStyle: .headline).withSize(scoreLabel.frame.height * 0.85)
        font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: font)
        //        let strokeColor = UIColor.black
        //
        //        let strokeWidth = scoreLabel.frame.height / 2
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let stringAttributes: [NSAttributedStringKey: Any] = [
            .font: font,
            //            .strokeColor: strokeColor,
            //            .strokeWidth: strokeWidth,
            .paragraphStyle: paragraphStyle
        ]
        return NSAttributedString(string: string, attributes: stringAttributes)
    }
    private func dealCards() {
        // 1. tells game to deal three cards, then display the new cards
        // make new cards views only if:
        // A. A match was performed, but there was no match
        // B. No match was performed.
        set.dealCards { (clearSelection, matchedStatus) in
            if clearSelection { // selections were cleared - that means a match was performed
                if let matchedStatus = matchedStatus {
                    if matchedStatus == false { // (A)
                        makeCardViews()
                    } else { // make cardViews only for those cards replaced
                        for selectedCardView in selectedCardViews {
                            let index = playingCardsMainView.cardViews.index(of: selectedCardView)!
                            let card = set.playedCards[index]
                            makeCardView(cardView: selectedCardView, card: card)
                        }
                    }
                }
                // remove all selected card views
                selectedCardViews.removeAll()
            } else {
                makeCardViews() // (B)
            }
        }
        if set.deck.count == 0 {
            dealCard(disable: true)
        }
    }
    
    // MARK: - Helper Functions -
    
    
    private func makeCardViews() {
        self.playingCardsMainView.numberOfCardViews = self.set.playedCards.count
        // Only update view for new additions
        var dealtCardsIndex = [Int]()
        for card in self.set.dealtCards {
            let index = self.set.playedCards.index(of: card)!
            dealtCardsIndex.append(index)
        }
        for index in dealtCardsIndex {
            let cardView = self.playingCardsMainView.cardViews[index]
            let card = self.set.playedCards[index]
            self.makeCardView(cardView: cardView, card: card)
        }
    }
    
    private func makeCardView(cardView: CardView, card: Card) {
        guard let color = colorDictionary[card.color] else { return }
        guard let shape = shapeDictionary[card.shape] else { return }
        let numberOfShapes = card.numberOfShapes.rawValue
        guard let shading = shadingDictionary[card.shading] else { return }
        
        cardView.color = color
        cardView.shade = shading
        cardView.shape = shape
        cardView.numberOfShapes = numberOfShapes
        cardView.alpha = 0
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: 0.6,
            delay: 0,
            options: [.curveEaseIn],
            animations: {
                cardView.alpha = 1.0
            }
        )
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectCard(_:)))
        tap.numberOfTapsRequired = 1
        cardView.addGestureRecognizer(tap)
    }
    
    private func dealCard(disable: Bool) {
        if disable {
            self.dealCardButton.isEnabled = false
            self.dealCardButton.backgroundColor =  UIColor.gray
            self.dealCardButton.setTitleColor(UIColor.black, for: .normal)
        } else {
            self.dealCardButton.isEnabled = true
            self.dealCardButton.backgroundColor =  UIColor.red
            self.dealCardButton.setTitleColor(UIColor.white, for: .normal)
        }
    }
}



