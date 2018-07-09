//
//  ViewController.swift
//  Set
//
//  Created by Peter Wu on 4/17/18.
//  Copyright © 2018 Zero. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIDynamicAnimatorDelegate {
    
    // MARK: GAME
    private var set = Set()
    
    
    // MARK: VIEWS
    @IBOutlet weak var playingCardsMainView: PlayingCardsMainView!
   
    
    @IBOutlet weak var deckButton: UIButton!
    var deckFrameInPlayingCardsMV: CGRect {
      return bottomStack.convert(deckButton.frame, to: playingCardsMainView)
    }
    
 
   
    @IBOutlet weak var bottomStack: UIStackView!
    @IBOutlet weak var rightContentView: UIView!
    
    @IBOutlet weak var setPileLabel: UILabel!
    var setPileCenterInPlayingCardsMV: CGPoint {
        return rightContentView.convert(CGPoint(x: setPileLabel.frame.midX, y: setPileLabel.frame.midY), to: playingCardsMainView)
    }
//    var setOriginInPlayingCardsMV: CGPoint {
//        return rightContentView.convert(setPileLabel.frame.origin, to: playingCardsMainView)
//    }
    
    @IBOutlet weak var newGameButton: UIButton! {
        didSet {
            newGameButton.setTitle("NEW GAME", for: .normal)
//            newGameButton.setAttributedTitle(updateAttributedString("NEW GAME",
//            view: newGameButton), for: .normal)
        }
    }
    @IBOutlet weak var scoreLabel: UILabel!
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "SCORE: \(score)"
        }
    }
    var selectedCardViews = [CardView]()
//    var tempCardViews = [CardView]()
    var cellSize = CGSize()

    // MARK: ANIMATION
    lazy var animator = UIDynamicAnimator(referenceView: self.playingCardsMainView)
    private weak var timer: Timer?
    
    let collisionBehavior: UICollisionBehavior = {
       let behavior = UICollisionBehavior()
        behavior.translatesReferenceBoundsIntoBoundary = true
        return behavior
    }()

    // MARK: CARD ATTRIBUTES
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
    
    // MARK: INITIAL CONFIG
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
        
        // set delegate for animator
        animator.delegate = self
        // MARK: DYNAMIC ANIMATION - animator adds push behavior
//        animator.addBehavior(pushBehavior)
        
        scoreLabel.text = "SCORE: \(score)"
    }
    
    // MARK: - USER ACTIONS
    
    @IBAction func dealCard(_ sender: UIButton) {
        dealCards()
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
                        playingCardsMainView.grid.cellCount = playingCardsMainView.numberOfCardViews
//                        self.playingCardsMainView.numberOfCardViews = self.set.playedCards.count
                        
                        // MARK: ANIMATION: adjust cards to new layout
                        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 1.0, delay: 0, options: [], animations: {
                            self.adjustCardViewsToNewFrame()
                        }, completion: nil)
                        // disable dealcard button
                        self.dealCard(disable: true)
                    } else {
                        // if deck is not empty, number of cardviews remains the same or more.  Simply update the cardviews for cards being replaced.
                        animateDealtCardViews()
                        // remove selectedCardViews after animation
                        selectedCardViews.removeAll()
                    }
                case .noMatch:
                    selectedCardViews.append(cardView)
                    selectedCardViews.forEach({ (cardView) in
                        cardView.showNoMatch()
                    })
                    // MARK: ANIMATION: make cards larger by 1.2
                    UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.7, delay: 0.1, options: [.allowAnimatedContent], animations: {
                        self.selectedCardViews.forEach({ (selectedCardView) in
                            selectedCardView.transform = CGAffineTransform.identity.scaledBy(x: 1.2, y: 1.2)
                        })
                    }, completion: { (position) in
                        self.selectedCardViews.forEach { cardView in
                            // MARK: ANIMATION: cards go back to original size
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

    
    
    
    // MARK: HELPER FUNCTIONS
    private func dealCards() {
        //        tells game to deal three cards, then display the new cards
        set.dealCards()
        showDealtCards()
        
    }
    
    // MARK: - VIEW UPDATES
	fileprivate func updateViewForMatchedCards() {
        // Update sets info on set pile
        self.setPileLabel.text = "\(self.set.matchedCards.count / 3) Sets"

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
//				tempCardViews.append(tempCardView)
			} catch {
				print(error.localizedDescription)
			}
		}
		// MARK: DYNAMIC ANIMATION: add cardview to push and collision behavior
		let itemBehavior = UIDynamicItemBehavior(items: playingCardsMainView.tempCardViews)
		itemBehavior.elasticity = 0.8
		animator.addBehavior(itemBehavior)
		animator.addBehavior(collisionBehavior)
		self.playingCardsMainView.tempCardViews.forEach {
			let pushBehavior = UIPushBehavior(items: [$0], mode: .instantaneous)
			// push behavior configuration
			pushBehavior.magnitude = CGFloat(3.0) + CGFloat(2.0).arc4Random
			pushBehavior.angle = CGFloat.pi + CGFloat.pi.arc4Random
			pushBehavior.active = true
			animator.addBehavior(pushBehavior)
			// remove instantaneous push behavior once it's acted
			pushBehavior.action = { [unowned pushBehavior] in
				pushBehavior.dynamicAnimator?.removeBehavior(pushBehavior)
			}
			// add cardviews to collision behavior
			self.collisionBehavior.addItem($0)
		}
		timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { timer in
            
            // MARK: DYNAMIC ANIMATION: set timer for 2 seconds before "snapping" the cards to the pile
            self.playingCardsMainView.tempCardViews.forEach { cardView in
                let snap = UISnapBehavior(item: cardView, snapTo: self.setPileCenterInPlayingCardsMV)
                // more damping than default
                snap.damping = 0.4
                self.animator.addBehavior(snap)
                
                // bring each temp cardviews to front so they cover the set pile label
                self.view.insertSubview(cardView, aboveSubview: self.setPileLabel)
                
                // MARK: DYNAMIC ANIMATION: remove items from behaviors
                self.collisionBehavior.removeItem(cardView)
                cardView.showNoSelection()
                
                // MARK: ANIMATION: change height and width of set cards to match the set pile
                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3, delay: 0, options: [], animations: {
                    
                    cardView.bounds = self.setPileLabel.bounds
//                    cardView.frame.height = setPileLabel.frame.height
                }, completion: nil)
            }
            
		}
	}
    
    func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {
        // MARK: ANIMATION: Flip cardviews when cardviews are snapped to the pile
        // animate flip cardviews to face down
        playingCardsMainView.tempCardViews.forEach { tempCardView in
            UIView.transition(with: tempCardView, duration: 0.7, options: [.transitionFlipFromLeft], animations: {
                tempCardView.isFaceUp = false
            }, completion: { (finished) in
                // clean up and remove temp card views from superview
                tempCardView.removeFromSuperview()
                self.playingCardsMainView.tempCardViews.remove(at: self.playingCardsMainView.tempCardViews.index(of: tempCardView)!)
                // remove all behaviors from animator
                animator.removeAllBehaviors()
            })
        }
    }
    
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
            do {
                try self.configureCardView(cardView: cardView, card: dealtCard)
            } catch {
                print("error from making cardView: \(error.localizedDescription)")
            }
            // keep track of old cardframe for animating back to its original size/position
            oldCardFrame.append(cardView.frame)
            // Make cardview opaquge and move to deck
            cardView.alpha = ViewTransparency.opaque
            // get deckButton's frame in playingcardsmainview's coordinate system
            
            cardView.frame = deckFrameInPlayingCardsMV
            cardViewsToAnimate.append(cardView)
        }
        
        var delay: TimeInterval = 0
        for (index, cardView) in cardViewsToAnimate.enumerated() {
            // Brings cards to animate to front
            playingCardsMainView.bringSubview(toFront: cardView)
            // MARK: ANIMATION: Cards from deck to position
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.75, delay: delay, options: [.curveEaseOut], animations: {
                cardView.frame = oldCardFrame[index]
            }, completion: { finished in
                // MARK: ANIMATION: Card flip from back to front
                UIView.transition(with: cardView, duration: 0.75, options: [.transitionFlipFromLeft], animations: {
                    cardView.isFaceUp = true
                }, completion: nil)
            })
            // increment animation delay for the next card
            delay += 0.5
        }
    }
    
    private func showDealtCards() {
        // prepare playingCardsMainView for new cardView frames
        self.playingCardsMainView.numberOfCardViews = self.set.playedCards.count
        // If the subview layout changes, animate dealing cardviews after existing cards adjust to new frame
        var animationDuration: TimeInterval = 0
        if cellSize != playingCardsMainView.grid.cellSize {
            animationDuration = 0.7
            cellSize = playingCardsMainView.grid.cellSize
        }
        dealCard(disable: true)
        // // MARK: ANIMATION: cards adjust to new layout
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
    
    // MARK: SUBVIEWS CONFIGURATION
    fileprivate func addTapGesture(_ cardView: CardView) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectCard(_:)))
        tap.numberOfTapsRequired = 1
        cardView.addGestureRecognizer(tap)
    }
    
    
    /// Configures a CardView to display attributes of a given card and adds tap gesture
    /// Default cardview is face down
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
            self.deckButton.isEnabled = false
            self.deckButton.backgroundColor =  UIColor.gray
            self.deckButton.setTitleColor(UIColor.black, for: .normal)
        } else {
            self.deckButton.isEnabled = true
            self.deckButton.backgroundColor =  #colorLiteral(red: 0.08967430145, green: 0.3771221638, blue: 0.6760857701, alpha: 1)
            self.deckButton.setTitleColor(UIColor.white, for: .normal)
        }
    }
    
    // MARK: - DEFINED CONSTANTS
    private struct ViewTransparency {
        static let opaque: CGFloat = 1.0
        static let transparent: CGFloat = 0
    }
    
}

extension CGFloat {
    var arc4Random: CGFloat {
        var randomFloat: CGFloat = 0
        if self > 0 {
            let intNum = Int(self*100)
            let randomInt = intNum.arc4random
            let randomDouble = Double(randomInt)
            randomFloat = CGFloat(randomDouble/100)
        } else if self < 0 {
            let positiveInt = Int(abs(self*100))
            let randomPositiveInt = positiveInt.arc4random
            let randomDouble = Double(randomPositiveInt)
            randomFloat = CGFloat(randomDouble/100)
        } else {
            randomFloat = 0
        }
        return randomFloat
    }
}




