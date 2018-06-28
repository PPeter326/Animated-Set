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
    var cellSize = CGSize()

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
    
    fileprivate func updateViewForMatchedCards() {
        // matched cards animation
        // 1. create temp card views for the matched cards
        let lastMatchedCards = set.matchedCards.suffix(3)
        for (index, card) in lastMatchedCards.enumerated() {
            let tempRect = selectedCardViews[index].frame
            let tempCardView = playingCardsMainView.makeEmptyCardView(rect: tempRect)
            do {
                try configureCardView(cardView: tempCardView, card: card)
                tempCardView.showMatch()
                tempCardView.alpha = ViewTransparency.opaque
                tempCardView.isFaceUp = true
                playingCardsMainView.addSubview(tempCardView)
                playingCardsMainView.tempCardViews.append(tempCardView)
                tempCardViews.append(tempCardView)
            } catch {
                print(error.localizedDescription)
            }
        }
        // 2. animate temp card views frame to pile frame
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 1.2, delay: 0.1, options: [], animations: {
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
    }
    
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
                    // change cardview to show
                    cardView.showSelection()
                    
                case .deselected:
                    cardView.showNoSelection()
                    
                    guard let index = selectedCardViews.index(of: cardView) else { return }
                    selectedCardViews.remove(at: index)
                    // update score
                    score = set.score
                case .matched:
                    selectedCardViews.append(cardView)
                    selectedCardViews.forEach {
                        $0.showMatch()
                    }
                    // matched cards animation
                    updateViewForMatchedCards()
                    
                    if set.deck.isEmpty {
                        // If deck is empty, then the views are shifted.  There are now less card views than before (for ex 21 -> 18)
                        // Rearrangement: first make the matched (also selected) card views disappear but keep the rest of the cards intact
                        self.selectedCardViews.forEach{ $0.alpha = ViewTransparency.transparent }
                        // remove the selected cardviews
                        for cardView in self.selectedCardViews {
                            cardView.removeFromSuperview()
                            self.playingCardsMainView.cardViews.remove(at: self.playingCardsMainView.cardViews.index(of: cardView)!)
                        }
                        self.selectedCardViews.removeAll()
                        // set the new frames and animate
                        self.playingCardsMainView.numberOfCardViews = self.set.playedCards.count
                        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 1.0, delay: 0, options: [], animations: {
                            self.adjustCardViewsToNewFrame()
                        }, completion: nil)
                        // disable dealcard button
                        self.dealCard(disable: true)
                    } else {
                        // if deck is not empty, number of cardviews remains the same or more.  Simply update the cardviews for cards being replaced.
//                        self.selectedCardViews.forEach{ $0.alpha = ViewTransparency.transparent }
                        animateDealtCardViews()
//                        var oldCardFrame = [CGRect]()
//                        var cardViewsToAnimate = [CardView]()
//                        for dealtCard in self.set.dealtCards {
//                            guard let index = set.playedCards.index(of: dealtCard) else { return }
//                            let cardView = playingCardsMainView.cardViews[index]
//                            do {
//                                try configureCardView(cardView: cardView, card: dealtCard)
//                            } catch {
//                                print(error.localizedDescription)
//                            }
//                            oldCardFrame.append(cardView.frame)
//                            cardView.alpha = ViewTransparency.opaque
//                            cardView.frame = self.playingCardsMainView.deckFrame
//                            cardViewsToAnimate.append(cardView)
//                        }
//                        // animate dealing cards to replace matched cards.  Not making new cardviews.
//                        var delay: TimeInterval = 0
//                        for (index, cardView) in cardViewsToAnimate.enumerated() {
//                            // update cardview for the new dealt cards
//                            cardView.isFaceUp = false
//                            cardView.showNoSelection()
//                            // animate move updated cardview back to its assigned position
//                            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 2.0, delay: delay, options: [], animations: {
//                                cardView.frame = oldCardFrame[index]
//                            }, completion: { finished in cardView.isFaceUp = true })
//                            delay += 0.5
//                        }
                        // remove selectedCardViews after animation
                        selectedCardViews.removeAll()
                    }
                case .noMatch:
                    selectedCardViews.append(cardView)
                    selectedCardViews.forEach({ (cardView) in
                        cardView.showNoMatch()
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
                                cardView.showNoSelection()
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
        
    }
    
    // MARK: - Helper Functions -
    
    
    fileprivate func adjustCardViewsToNewFrame() {
        // reset frame for each cardview
        for (index, cardView) in self.playingCardsMainView.cardViews.enumerated() {
            guard let rect = self.playingCardsMainView.grid[index] else { return }
            cardView.frame = rect
            cardView.insetFrame()
        }
    }
    
    fileprivate func animateDealtCardViews() {
        // Add new cardViews for dealt cards, and keep track of old card frame and card views to animate
        var oldCardFrame = [CGRect]()
        var cardViewsToAnimate = [CardView]()
        for dealtCard in self.set.dealtCards {
            guard let index = self.set.playedCards.index(of: dealtCard) else { return }
            // create cardView with given card position
            let cardView = self.playingCardsMainView.cardViews[index]
            //                self.playingCardsMainView.addSubview(cardView)
            //                self.playingCardsMainView.cardViews.append(cardView)
            do {
                try self.configureCardView(cardView: cardView, card: dealtCard)
            } catch {
                print("error from making cardView: \(error.localizedDescription)")
            }
            // keep track of old cardframe for animating back to its original size/position
            oldCardFrame.append(cardView.frame)
            // Make cardview opaquge and move to deck
            cardView.alpha = ViewTransparency.opaque
            cardView.frame = self.playingCardsMainView.deckFrame
            cardViewsToAnimate.append(cardView)
        }
        
        var delay: TimeInterval = 0
        for (index, cardView) in cardViewsToAnimate.enumerated() {
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 2.0, delay: delay, options: [], animations: {
                cardView.frame = oldCardFrame[index]
            }, completion: { finished in cardView.isFaceUp = true })
            // increment animation delay for the next card
            delay += 0.5
        }
    }
    
    private func showDealtCards() {
        // prepare playingCardsMainView for new cardView frames
        self.playingCardsMainView.numberOfCardViews = self.set.playedCards.count
        // If the subview layout changes, animate cardviews as they adjust to new frame
        var animationDuration: TimeInterval = 0
        if cellSize != playingCardsMainView.grid.cellSize {
            animationDuration = 0.7
            cellSize = playingCardsMainView.grid.cellSize
        }
        dealCard(disable: true)
        // Animate new cardviews
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: animationDuration, delay: 0, options: [], animations: {
            self.adjustCardViewsToNewFrame()
        }) { (position) in
            if self.set.deck.count == 0 {
                self.dealCard(disable: true)
            } else {
                self.dealCard(disable: false)
            }
            self.animateDealtCardViews()
        }
    }
    
    fileprivate func addTapGesture(_ cardView: CardView) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectCard(_:)))
        tap.numberOfTapsRequired = 1
        cardView.addGestureRecognizer(tap)
    }
    
    
    /// Configures a CardView to display attributes of a given card and adds tap gesture
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
        cardView.showNoSelection()
        cardView.alpha = ViewTransparency.opaque
        cardView.isFaceUp = false
        addTapGesture(cardView)
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
    
    private struct ViewTransparency {
        static let opaque: CGFloat = 1.0
        static let transparent: CGFloat = 0
    }
    
}




