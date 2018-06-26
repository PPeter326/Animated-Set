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
    
    @IBOutlet weak var playingCardsMainView: PlayingCardsMainView!
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
    var tempCardViews = [CardView]()
    
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
    override func viewDidLoad() {
        set.startGamme()
        // show card views
        showDealtCards()
        // add swipe and rotate gestures to deal and shuffle, respectively
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(swipeDownToDeal(_:)))
        swipeDown.direction = .down
        playingCardsMainView.addGestureRecognizer(swipeDown)
        let rotate = UIRotationGestureRecognizer(target: self, action: #selector(rotateToShuffle(_:)))
        playingCardsMainView.addGestureRecognizer(rotate)
    }
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
                    cardView.layer.borderWidth = cardView.frame.width * SizeRatio.highlightBorderWidthRatio
                    cardView.layer.borderColor = BorderColor.selectedBorderColor
                case .deselected:
                    cardView.layer.borderWidth = cardView.frame.width * SizeRatio.defaultBorderWidthRatio
                    cardView.layer.borderColor = BorderColor.defaultBorderColor
                    guard let index = selectedCardViews.index(of: cardView) else { return }
                    selectedCardViews.remove(at: index)
                    // update score
                    score = set.score
                case .matched:
                    selectedCardViews.append(cardView)
                    selectedCardViews.forEach {
                        $0.layer.borderWidth = $0.frame.width * SizeRatio.highlightBorderWidthRatio
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
                        // 1. create temp card views for the matched cards
                        let lastMatchedCards = set.matchedCards.suffix(3)
                        for (index, card) in lastMatchedCards.enumerated() {
                            let tempRect = selectedCardViews[index].frame
                            let tempCardView = makeEmptyCardView(rect: tempRect)
                            do {
                                try configureCardView(cardView: tempCardView, card: card)
                                tempCardView.alpha = 1
                                playingCardsMainView.addSubview(tempCardView)
                                playingCardsMainView.tempCardViews.append(tempCardView)
                                tempCardViews.append(tempCardView)
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                        // 2. animate temp card views frame to pile frame
                        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 1.0, delay: 0, options: [], animations: {
                            self.playingCardsMainView.tempCardViews.forEach {
                                $0.frame = self.playingCardsMainView.pileFrame
                            }
                        }, completion: { (position) in
                            // 3. remove temp card views
                            self.tempCardViews.removeAll()
                            self.playingCardsMainView.tempCardViews.forEach({ (cardView) in
                                cardView.removeFromSuperview()
                            })
                            self.playingCardsMainView.tempCardViews.removeAll()
                        })
                        
                        // deal card animations
                        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 1.0, delay: 0.1, options: [.allowAnimatedContent], animations: {
                            self.selectedCardViews.forEach{ $0.alpha = 0 }
                        }, completion: nil)
                        // animate dealing cards to replace matched cards.  Not making new cardviews.
                        var delay: TimeInterval = 0
                        for (index, cardView) in self.selectedCardViews.enumerated() {
                            // move the cardviews to deck
                            let assignedFrame = cardView.frame
                            cardView.frame = playingCardsMainView.deckFrame
                            // double check played card and cardviews index
                            let cardIndex = set.playedCards.index(of: set.dealtCards[index])
                            let cardViewIndex = playingCardsMainView.cardViews.index(of: cardView)
                            assert(cardIndex == cardViewIndex, "mismatched cardview and dealt card")
                            do {
                                // update cardview for the new dealt cards
                              try configureCardView(cardView: cardView, card: set.dealtCards[index])
                                cardView.layer.borderWidth = cardView.frame.width * SizeRatio.defaultBorderWidthRatio
                                cardView.layer.borderColor = BorderColor.defaultBorderColor
                                // animate move updated cardview back to its assigned position
                                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.7, delay: delay, options: [], animations: {
                                    cardView.frame = assignedFrame
                                    cardView.alpha = 1.0
                                }, completion: nil)
                            } catch {
                                print(error.localizedDescription)
                            }
                            delay += 0.5
                        }
                        // remove selectedCardViews after animation
                        selectedCardViews.removeAll()
                    }
                case .noMatch:
                    selectedCardViews.append(cardView)
                    selectedCardViews.forEach({ (cardView) in
                        cardView.layer.borderWidth = cardView.frame.width * SizeRatio.highlightBorderWidthRatio
                        cardView.layer.borderColor =  BorderColor.mismatchBorderColor
                    })
                    
                    UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.7, delay: 0.1, options: [.allowAnimatedContent], animations: {
                        self.selectedCardViews.forEach({ (selectedCardView) in
                            selectedCardView.transform = CGAffineTransform.identity.scaledBy(x: 1.2, y: 1.2)
                        })
                    }, completion: { (position) in
                            self.selectedCardViews.forEach { cardView in
                                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.7, delay: 0, options: [], animations: {
                                        cardView.transform = .identity
                                }, completion: { position in
                                    cardView.layer.borderWidth = cardView.frame.width * SizeRatio.defaultBorderWidthRatio
                                    cardView.layer.borderColor = BorderColor.defaultBorderColor
                                })
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
        // reset and restart game
        set.reset()
        set.startGamme()
        // clear selectedCardViews and card views
        self.selectedCardViews.removeAll()
        playingCardsMainView.reset()
        // update card views
        showDealtCards()
        // update score and enable dealCardButton
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
                showDealtCards()
            }
        default: break
        }
        

    }
    private func updateAttributedString(_ string: String) -> NSAttributedString {
        var font = UIFont.preferredFont(forTextStyle: .headline).withSize(scoreLabel.frame.height * 0.85)
        font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: font)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let stringAttributes: [NSAttributedStringKey: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]
        return NSAttributedString(string: string, attributes: stringAttributes)
    }
    
    private func dealCards() {
//        tells game to deal three cards, then display the new cards
        set.dealCards()
        showDealtCards()
        if set.deck.count == 0 {
            dealCard(disable: true)
        }
    }
    
    // MARK: - Helper Functions -
    
    
    fileprivate func adjustCardViewsToNewFrame() {
        // prepare playingCardsMainView for new cardView frames
        self.playingCardsMainView.numberOfCardViews = self.set.playedCards.count
        // reset frame for each cardview
        for (index, cardView) in self.playingCardsMainView.cardViews.enumerated() {
            guard let rect = self.playingCardsMainView.grid[index] else { return }
            let newRect = rect.insetBy(dx: rect.width * SizeRatio.insetWidthRatio, dy: rect.height * SizeRatio.insetHeightRatio)
            cardView.frame = newRect
        }
    }
    
    private func showDealtCards() {
        // Animate cardviews as they adjust to new frame
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.7, delay: 0, options: [], animations: {
            self.adjustCardViewsToNewFrame()
        }) { (position) in
            var delay: TimeInterval = 0
            // Only update view for new additions
            for dealtCard in self.set.dealtCards {
                do {
                    // create cardView with given card position
                    let cardView = try self.makeCardView(card: dealtCard)
                    // keep track of old cardframe for animating back to its original size/position
                    let oldCardFrame = cardView.frame
                    // Make cardview opaquge and move to deck
                    cardView.alpha = 1
                    cardView.frame = self.playingCardsMainView.deckFrame
                    // animate cardView as it goes back to the frame
                    UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.7, delay: delay, options: [], animations: {
                        self.playingCardsMainView.addSubview(cardView)
                        self.playingCardsMainView.cardViews.append(cardView)
                        cardView.frame = oldCardFrame
                    }, completion: nil)
                    // increment animation delay for the next card
                    delay += 0.5
                } catch {
                    print("error from making cardView: \(error)")
                }
            }
        }
    }
    
    fileprivate func addTapGesture(_ cardView: CardView) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectCard(_:)))
        tap.numberOfTapsRequired = 1
        cardView.addGestureRecognizer(tap)
    }
    
    /// Makes a cardview for a card in play
    ///
    /// - Parameters:
    ///   - card: the card being played in the game
    /// - Returns: A CardView displaying attributes of the card that also recognizes tap gesture.  The cardview's frame is positioned in PlayingCardsMainView's grid in the same index as the card.
    /// - Throws: Error if index position cannot be found on the grid object of playingCardsMainView
    private func makeCardView(card: Card) throws -> CardView {
        guard let positionIndex = self.set.playedCards.index(of: card) else { throw CardViewGeneratorError.invalidIndex }
        guard let rect = playingCardsMainView.grid[positionIndex] else { throw CardViewGeneratorError.invalidFrame }
        let cardView = makeEmptyCardView(rect: rect)
        try configureCardView(cardView: cardView, card: card)
        addTapGesture(cardView)
        return cardView
    }
    
    /// Configures a CardView to display attributes of a given card
    ///
    /// - Parameters:
    ///   - cardView: A CardView object
    ///   - card: A given card
    /// - Throws: Error if the function is unable to retrieve card attributes such as color and shapes from dictionary
    private func configureCardView(cardView: CardView, card: Card ) throws {
        guard let color = colorDictionary[card.color] else { throw CardViewGeneratorError.invalidColor }
        guard let shape = shapeDictionary[card.shape] else { throw CardViewGeneratorError.invalidShape }
        let numberOfShapes = card.numberOfShapes.rawValue
        guard let shading = shadingDictionary[card.shading] else { throw CardViewGeneratorError.invalidShading }
        cardView.color = color
        cardView.shade = shading
        cardView.shape = shape
        cardView.numberOfShapes = numberOfShapes
        cardView.alpha = 0
    }
    
    private func makeEmptyCardView(rect: CGRect) -> CardView {
        let newRect = rect.insetBy(dx: rect.width * SizeRatio.insetWidthRatio, dy: rect.height * SizeRatio.insetHeightRatio)
        let cardView = CardView(frame: newRect)
        cardView.backgroundColor = #colorLiteral(red: 0, green: 0.5628422499, blue: 0.3188166618, alpha: 0.7835308305)
        cardView.layer.borderWidth = rect.width * SizeRatio.defaultBorderWidthRatio
        cardView.layer.borderColor = BorderColor.defaultBorderColor
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
    private struct SizeRatio {
        static var insetWidthRatio: CGFloat = 0.10
        static var insetHeightRatio: CGFloat = 0.10
        static var defaultBorderWidthRatio: CGFloat = 0.01
        static var highlightBorderWidthRatio: CGFloat = 0.0667
    }
    private struct BorderColor {
        static var defaultBorderColor: CGColor = UIColor.black.cgColor
        static var mismatchBorderColor: CGColor = UIColor.red.cgColor
        static var selectedBorderColor: CGColor = #colorLiteral(red: 0, green: 0.9914394021, blue: 1, alpha: 1).cgColor
    }
}


