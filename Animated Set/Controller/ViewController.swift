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
    // MARK: - Game Properties -
    private var set = Set()
    
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
    private weak var timer: Timer?
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
    
    var selectedCardViews = [CardView]()
    
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
                    cardView.layer.borderWidth = cardView.frame.width / 15
                    cardView.layer.borderColor = #colorLiteral(red: 0, green: 0.9914394021, blue: 1, alpha: 1).cgColor
                case .deselected:
                    cardView.layer.borderWidth = cardView.frame.width / 100
                    cardView.layer.borderColor = #colorLiteral(red: 0.06274510175, green: 0, blue: 0.1921568662, alpha: 1)
                    guard let index = selectedCardViews.index(of: cardView) else { return }
                    selectedCardViews.remove(at: index)
                case .matched:
                    selectedCardViews.append(cardView)
                    selectedCardViews.forEach {
                        $0.layer.borderWidth = $0.frame.width / 15
                        $0.layer.borderColor =  UIColor.green.cgColor
                    }
                    if set.deck.isEmpty {
                        // If deck is empty, then the views are shifted.  There are now less card views than before (for ex 21 -> 18)
                        // 1. first make the matched (also selected) card views disappear but keep the rest of the cards intact
                        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 1.0, delay: 0.1, options: [UIViewAnimationOptions.curveEaseIn], animations: {
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
                            }
                        )
                    } else { // if deck is not empty, number of cardviews remains the same or more.  Simply update the cardviews for cards being replaced.
                        // matched cards animation
                        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 1.0, delay: 0.1, options: [.allowAnimatedContent], animations: {
                            self.selectedCardViews.forEach{ $0.alpha = 0 }
                        })
                        self.makeCardViews()
                        self.selectedCardViews.removeAll()
                    }
                case .noMatch:
                    selectedCardViews.append(cardView)
                    selectedCardViews.forEach({ (cardView) in
                        cardView.layer.borderWidth = cardView.frame.width / 15
                        cardView.layer.borderColor =  UIColor.red.cgColor
                    })
                    
                    UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 1.0, delay: 0.2, options: [.allowAnimatedContent], animations: {
                        self.selectedCardViews.forEach({ (selectedCardView) in
                            selectedCardView.transform = CGAffineTransform.identity.scaledBy(x: 0.8, y: 0.8)
                        })
                    }, completion: { (position) in
                        // No need to transform cardView back because it's being done in updateFrames() in PlayingCardsMainView
                        // restore selected cards back to its original property then remove from selectedCardViews array
                        self.selectedCardViews.forEach {
                            $0.layer.borderWidth = $0.frame.width / 100
                            $0.layer.borderColor = #colorLiteral(red: 0.06274510175, green: 0, blue: 0.1921568662, alpha: 1)
//                            $0.transform = .identity
                        }
                        self.selectedCardViews.removeAll()
                    })
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
//        tells game to deal three cards, then display the new cards
        set.dealCards()
        makeCardViews() // (B)
        if set.deck.count == 0 {
            dealCard(disable: true)
        }
    }
    
    // MARK: - Helper Functions -
    
    
    private func makeCardViews() {
        print(#function)
        // prepare playingCardsMainView for new cardView frames
        self.playingCardsMainView.numberOfCardViews = self.set.playedCards.count
        self.playingCardsMainView.grid.frame = self.playingCardsMainView.bounds
        // Animate cardviews as they adjust to new frame
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.7, delay: 0, options: [], animations: {
                for (index, cardView) in self.playingCardsMainView.cardViews.enumerated() {
                    guard let rect = self.playingCardsMainView.grid[index] else { return }
                    let newRect = rect.insetBy(dx: rect.width / 10, dy: rect.height / 10)
                    cardView.frame = newRect
                }
        }) { (position) in
            var delay: TimeInterval = 0
            // Only update view for new additions
            for dealtCard in self.set.dealtCards {
                // get index of dealt card amongst played cards
                guard let cardIndex = self.set.playedCards.index(of: dealtCard) else { return }
                // make cardView from index
                do {
                    let cardView = try self.makeCardView(index: cardIndex, card: dealtCard)
                    let assignedCardViewFrame = cardView.frame
                    // move cardview to deck
                    cardView.alpha = 1
                    cardView.frame = self.playingCardsMainView.deckFrame
                    // animate cardView as it goes back to the frame
                    UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.7, delay: delay, options: [], animations: {
                        self.playingCardsMainView.addSubview(cardView)
                        self.playingCardsMainView.cardViews.append(cardView)
                        cardView.frame = assignedCardViewFrame
                    }, completion: nil)
                    // increment delay
                    delay += 0.5
                } catch {
                    print(error)
                }
            }
        }
    }
    
    private func makeCardView(index: Int, card: Card) throws -> CardView {
        guard let rect = playingCardsMainView.grid[index] else { throw CardViewGeneratorError.invalidFrame }
        let cardView = makeCell(rect: rect)
        guard let color = colorDictionary[card.color] else { throw CardViewGeneratorError.invalidColor }
        guard let shape = shapeDictionary[card.shape] else { throw CardViewGeneratorError.invalidShape }
        let numberOfShapes = card.numberOfShapes.rawValue
        guard let shading = shadingDictionary[card.shading] else { throw CardViewGeneratorError.invalidShading }
        
        cardView.color = color
        cardView.shade = shading
        cardView.shape = shape
        cardView.numberOfShapes = numberOfShapes
        cardView.alpha = 0
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectCard(_:)))
        tap.numberOfTapsRequired = 1
        cardView.addGestureRecognizer(tap)
        
        return cardView
    }
    
    private func makeCell(rect: CGRect) -> CardView {
        let newRect = rect.insetBy(dx: rect.width / 10, dy: rect.height / 10)
        let cardView = CardView(frame: newRect)
        cardView.backgroundColor = #colorLiteral(red: 0, green: 0.5628422499, blue: 0.3188166618, alpha: 0.7835308305)
        cardView.layer.borderWidth = rect.width / 100
        cardView.layer.borderColor = #colorLiteral(red: 0.06274510175, green: 0, blue: 0.1921568662, alpha: 1)
        return cardView
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



