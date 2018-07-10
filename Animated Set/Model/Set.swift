//
//  Set.swift
//  Set
//
//  Created by Peter Wu on 4/17/18.
//  Copyright © 2018 Zero. All rights reserved.
//

import Foundation

/*
 Four features:
 1. Symbols - "▲", "◼︎", and "✦".
 2. Numbers - one, two, or three symbols. "▲", "▲▲", and "▲▲▲"
 3. Shading - solid, striped, or open
 4. Color - red, green or purple
 
 Play:
 - Allows user to select 3 cards at a time.  Also allow user to deselect cards that are already selected, but only if there 2 or less cards selected.  Once user select 3 cards, a match/mismatch must be determined.
 - match cards (true/false) when user select 3 cards
 - deal cards, 3 at a time, that does one of the following:
 1. replace the selected cards if there's a match
 2. add 3 cards to the game
 
 Score:
 - Each match is 3 points
 - Each mismatch is -5 points
 - If user already selected a card, and user deselects a card, is - 1 point.
 */
class Set {

    // MARK: Game properties and initializer
    
    var deck: [PlayCard]
    var selectedCards = [PlayCard]() {
        didSet {
            if selectedCards.count == 3 {
                // A set of cards are matched when any of the attributes are matched between ONLY two cards
                // If cards are matched, add them to the matched cards
                if onlyTwoEquals(amongst: selectedCards) {
                    score += 3
                    self.matchedCards.append(contentsOf: selectedCards)
                    matched = true
                } else {
                    score -= 5
                    matched = false
                }
            }
        }
    }
    var matchedCards = [PlayCard]()
    var playedCards = [PlayCard]()
    var dealtCards = [PlayCard]()
    private(set) var matched: Bool?
    private(set) var score: Int = 0
    
    init() {
        deck = PlayCard.all
        shuffleCards()
    }
    
    // MARK: - Game Methdods
    
    /// This function add or remove the card to selectedCards array depending on the context.
    /// Do nothing if it's one of the matched cards
    /// If there are 0 to 2 cards already selected, add card to selectedCards array if the card is not already one of the element in the array
    /// If the card is already one of the element in the array, remove the card from selectedCards array
    /// When there are three cards already selected, the selectedCards array will be cleared and the new card will be added to the array.
    /// If the selected cards have been matched, in the playedCards array the matched cards will be replaced with new cards from the deck.
    /// If there are no more cards in the deck, the matched cards will simply be removed with no replacement.
    /// - Parameter card: Card type that is accessed from playedCards array with index from the cardView
    func selectCard(card: PlayCard, result: (_ result: Result) -> Void) {
        var selectionResult = Result.selected
        
        if !matchedCards.contains(card) {
            switch self.selectedCards.count {
            case 0...2: // add/remove from selected cards, depending on if user already selected the card
                if selectedCards.contains(card) {
                    // get index of the card in selected cards
                    let index = selectedCards.index(of: card)!
                    selectedCards.remove(at: index)
                    // deduct one point for deselecting the card
                    score -= 1
                    selectionResult = .deselected
                } else {
                    selectedCards.append(card)
                    // If there was a match (selected 3 cards)
                    if let matched = matched {
                        if matched { // 3 cards matched to a set
                            if deck.isEmpty { // no more cards in deck, simply remove cards from play
                                for selectedCard in selectedCards {
                                    playedCards.remove(at: playedCards.index(of: selectedCard)!)
                                }
                            } else { // Deck isn't empty - deal cards from deck to replace matched cards
                                dealtCards.removeAll()
                                for selectedCard in selectedCards {
                                    let card =  deck.removeLast()
                                    playedCards[playedCards.index(of: selectedCard)!] = card
                                    dealtCards.append(card)
                                }
                            }
                            selectionResult = .matched
                        } else {
                            selectionResult = .noMatch
                        }
                        self.matched = nil // reset matched status after removing matched cards from play
                        selectedCards.removeAll()
                    } else {
                        assert(selectedCards.count != 3, "Invalid selected cards count")
                        selectionResult = .selected
                    }
                }
                result(selectionResult)
            default: // There should be no more than 3 cards selected at a time
                break
            }
        } else { // user touches one of the matched cards - no action
            selectionResult = .noAction
            result(selectionResult)
        }
    }
    
    enum Result {
        case selected, deselected, noAction, matched, noMatch
    }
    
    /// If there are three selected cards:
    /// A. three cards already matched: deal cards to replace matched cards
    /// B. three cards not matched:  clear selected cards, and deal 3 cards to add at the end
    /// add three cards from deck to played cards at the end
    func dealCards(){
        if !deck.isEmpty {
            dealtCards.removeAll()
            for _ in 1...3 {
                let card = deck.removeLast()
                playedCards.append(card)
                dealtCards.append(card)
            }
        }
    }
    func reset() {
        selectedCards.removeAll()
        matchedCards.removeAll()
        playedCards.removeAll()
        dealtCards.removeAll()
        matched = nil
        score = 0
        
        self.deck = PlayCard.all
        shuffleCards()
    }
    
    // MARK: - Helper Methods
    func shuffleRemainingCards() {
        // clear selection
        selectedCards.removeAll()
        // add playedcards back to the deck
        deck.append(contentsOf: playedCards)
        // shuffle cards
        shuffleCards()
        // deal the same number of new cards as previously played cards
        for index in playedCards.indices {
            playedCards[index] = deck.removeLast()
        }
    }
    
    private func shuffleCards() {
        var shuffledCards = [PlayCard]()
        for _ in 0...(self.deck.count - 1) {
            let randomIndex = self.deck.count.arc4random
            shuffledCards.append(self.deck.remove(at: Int(randomIndex)))
        }
        self.deck = shuffledCards
    }
    
    func startGamme() {
        dealtCards.removeAll()
        for _ in 0...11 {
            let card = deck.removeLast()
            playedCards.append(card)
            dealtCards.append(card)
        }
    }
    
    private func onlyTwoEquals(amongst cards:[PlayCard]) -> Bool {
        // Go through each card in the array and compare each attribute.  The cards are matched only if all attributes of all cards in a set are same or totally different.
        // Attribute 1 comparison
        let colorAttributeMatch = (cards[0].color == cards[1].color && cards[1].color == cards[2].color) || (cards[0].color != cards[1].color && cards[1].color != cards[2].color && cards[0].color != cards[2].color)
        
        let shadingAttributeMatch = (cards[0].shading == cards[1].shading && cards[1].shading == cards[2].shading) || (cards[0].shading != cards[1].shading && cards[1].shading != cards[2].shading && cards[0].shading != cards[2].shading)
        
        let numberOfShapesMatch = (cards[0].numberOfShapes == cards[1].numberOfShapes && cards[1].numberOfShapes == cards[2].numberOfShapes) || (cards[0].numberOfShapes != cards[1].numberOfShapes && cards[1].numberOfShapes != cards[2].numberOfShapes && cards[0].numberOfShapes != cards[2].numberOfShapes)
        
        let shapesMatch = (cards[0].shape == cards[1].shape && cards[1].shape == cards[2].shape) || (cards[0].shape != cards[1].shape && cards[1].shape != cards[2].shape && cards[0].shape != cards[2].shape)
        
        // Only a match if all attributes match
        return shapesMatch && numberOfShapesMatch && shadingAttributeMatch && colorAttributeMatch
//        return true
    }
}






