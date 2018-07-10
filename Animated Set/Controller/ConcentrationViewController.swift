//
//  ViewController.swift
//  Concentration
//
//  Created by Peter Wu on 2/28/18.
//  Copyright © 2018 Zero. All rights reserved.
//

import UIKit
import MapKit

class ConcentrationViewController: UIViewController {
    
    private lazy var game = Concentration(numberOfPairsOfCards: numberOfPairOfCards)
    
    var numberOfPairOfCards: Int {
        get {
            return (cardButtons.count + 1) / 2
        }
    }
    
//    private var emojiThemes = [
//        0: "😀🧐🤓🤩😡😱😨🤢😈🤡👺👻☠️👹👽👾🤖",
//        1: "🤲👍👏👊✍️👈💪👌✊🤝👇🙏🖕🖐🤞🤜🤘",
//        2: "🍏🍌🍇🥥🥦🍍🍋🍅🍊🍎🍉🍓🥝🍐🍒🥔🥑",
//        3: "⚽️🏀🏈⚾️🎾🏐🏉🎱🏓🏸🥅🏒🏑🏏⛳️🏹⛷",
//        4: "🚗🚕🚙🚌🚎🏎🚓🚑🚒🚐🚚🚛🚜🛴🚲🛵🏍",
//        5: "🏳️🏴🏁🚩🏳️‍🌈🇦🇫🇦🇽🇦🇱🇩🇿🇦🇸🇦🇩🇦🇴🇦🇮🇦🇶🇦🇬🇦🇷🇦🇲"
//    ]
    private var cardThemes = [
        [ #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.902107802), #colorLiteral(red: 1, green: 0.5763723254, blue: 0, alpha: 1)],
        [ #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1), #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)],
        [ #colorLiteral(red: 0, green: 0.5628422499, blue: 0.3188166618, alpha: 1), #colorLiteral(red: 1, green: 0.1857388616, blue: 0.5733950138, alpha: 1)],
        [ #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1), #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)],
    ]
//    private var currentThemeIndex: Int = 0
    var theme: String? {
        didSet {
            emojiChoices = theme ?? ""
            emoji = [:]
            updateViewFromModel()
        }
    }
    var emojiChoices = ""
    private var emoji = [Card:String]()
    @IBOutlet private weak var flipCountLabel: UILabel! {
        didSet {
            flipCountLabel.attributedText = updateAttributedString(text: flipCountLabel.text!)
        }
    }
    @IBOutlet private weak var scoreLabel: UILabel!
    
    @IBOutlet private var cardButtons: [UIButton]!
    
    @IBAction private func cardTouched(_ sender: UIButton) {
        // increase flip count by one
        Card.increaseFlipCount()
        // if card was faceup, make it facedown, and vice versa
        if let cardNumberIndex = cardButtons.index(of: sender){
            game.chooseCard(at: cardNumberIndex)
            updateViewFromModel()
        } else {
            print("card chosen not in buttons array")
        }
        
    }
    @IBAction private func newGameButtonDidPressed(_ sender: UIButton) {
        // Ends current game in progress, and restart a new game
        resetGame()
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    private func updateViewFromModel() {
        if cardButtons != nil {
            for index in cardButtons.indices {
                // For each card button and corresponding card in cards array, if card is face up (chosen), then the card button will show emoji.  Otherwise set it to orange color if the card isn't a match.  If the cards are matched, make them transparent (disappear from view).
                let button = cardButtons[index]
                let card = game.cards[index]
                // setting the emojis for all face-up card
                if game.faceUpCardsIndex.contains(index) {
                    button.setTitle(emoji(for: card), for: UIControlState.normal)
                    button.backgroundColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
                } else {
                    button.setTitle("", for: UIControlState.normal)
                    button.backgroundColor = game.matchedCards.contains(card) ? #colorLiteral(red: 1, green: 0.5763723254, blue: 0, alpha: 0) : #colorLiteral(red: 1, green: 0.5763723254, blue: 0, alpha: 1)
                }
            }
        }
        // Update score/flipcount label
        if scoreLabel != nil {
            scoreLabel.text = "Score: \(Concentration.score)"
        }
        if flipCountLabel != nil {
            flipCountLabel.attributedText = updateAttributedString(text: "Flips: \(Card.flipCount)")
        }
    }
    
    fileprivate func updateAttributedString(text: String) -> NSAttributedString {
        let textAttribute: [NSAttributedStringKey: Any] = [
            .strokeWidth: 5.0,
            .strokeColor:#colorLiteral(red: 1, green: 0.5763723254, blue: 0, alpha: 1)
        ]
        return NSAttributedString(string: text, attributes: textAttribute)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return false
    }
    
    func resetGame() {
        // create new game
        let newGame = Concentration(numberOfPairsOfCards: (cardButtons.count + 1) / 2)
        self.game = newGame
        // reset flipcounts and game score
        Card.resetFlipCount()
        Concentration.setScore(score: 0)
        // clear out emoji choices and emoji
        emojiChoices.removeAll()
        emoji.removeAll()
        // update view
        updateViewFromModel()
    }
    
    func emoji(for card: Card) -> String {
        // If the chosen card has no corresponding emoji (to prevent resetting the card with new emoji), and there are still emojis available, then pick a random emoji and move it to the card.
//        chooseEmojiThemes()
        if emoji[card] == nil, emojiChoices.count > 0 {
//        if emojiChoices.count > 0 {
            let randomStringIndex = emojiChoices.index(emojiChoices.startIndex, offsetBy: emojiChoices.count.arc4random)
            emoji[card] = String(emojiChoices.remove(at: randomStringIndex))
        }
        return emoji[card] ?? "?"
    }
    
//    func chooseEmojiThemes() {
//        if emojiChoices.isEmpty {
//            if emojiThemes.count.arc4random < emojiThemes.count {
//                emojiChoices = emojiThemes[emojiThemes.count.arc4random]!
//            }
//        }
//    }


}

extension Int {
    var arc4random: Int {
        if self > 0 {
            return Int(arc4random_uniform(UInt32((self))))
        } else if self < 0 {
            return -Int(arc4random_uniform(UInt32(abs(self))))
        } else {
            return 0
        }
    }
}

