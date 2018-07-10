//
//  Concentration.swift
//  Concentration
//
//  Created by Peter Wu on 3/22/18.
//  Copyright © 2018 Zero. All rights reserved.
//

import Foundation

struct Concentration {
    
    private(set) var cards = [Card]()
    private(set) static var score = 0
    var faceUpCardsIndex = [Int]()
    var matchedCards = [Card]()
    
    private var indexOfOneAndOnlyFaceUpCard: Int? {
        get {
            // filter cards by face up property, which returns an array of index of the card that is face up.  If there's only 1 element in the array, return the first (and only) element of the array.  Else return nil (0 or more than 1 face up card)
            return faceUpCardsIndex.oneAndOnly ?? nil
//            if let indexOfOneAndOnlyFaceUpCard = faceUpCardsIndex.oneAndOnly {
//                return cards.index(of: indexOfOneAndOnlyFaceUpCard)
//            } else{
//                return nil
//            }
//            return faceUpCardIndex.count == 1 ? faceUpCardIndex.first : nil
//            var foundIndex: Int?
//            // Go through all cards, if there's only one face up card, make set index.  Else return nil
//            // 1. First go through all cards
//            for index in cards.indices {
//                // 2. If a face-up card is found
//                if cards[index].isFaceUp == true {
//                    // 3. Check face-up index.  If there's already an index of a separate card, then this is not the only face up card.  Return nil.
//                    if foundIndex == nil{
//                        foundIndex = index
//                    } else {
//                        // there's is no other card that is up.  Set index
//                        return nil
//                    }
//                } // 4. No face-up card is found, do nothing because default value of In? is nil
//            }
//            // Return foundIndex.  It either has a value (set in step 3) or defaults to nil (step 4)
//            return foundIndex
        }
        set {
            // Once the index is set, set the card face up and every other cards face down
            if let newIndex = newValue {
                faceUpCardsIndex.removeAll()
                faceUpCardsIndex.append(newIndex)
            }
        }
        
    }
    /// sets score that is tracked by the Concentration class
    static func setScore(score: Int) {
        self.score = score
    }
    mutating func chooseCard(at index: Int) {
        // assertion to crash if index is out of bounds
        assert(cards.indices.contains(index), "Concentration.chooseCard(at: \(index)): card index chosen not in array")
        // Increase flip count
        cards[index].increaseFlipCount()
        // time stamp each card
        cards[index].date = Date()
        // ignore matched cards - they stay the same
        if !matchedCards.contains(cards[index]) {
            // A. There's already one card up, and the card chosen isn't the same one as the one that's already up
            if let matchIndex = indexOfOneAndOnlyFaceUpCard, matchIndex != index {
                if cards[matchIndex] == cards[index] {
                    // Option 1. The chosen card matches the card that's already up
                    // I. update the matched cards' attributes
                    matchedCards.append(contentsOf: [cards[matchIndex], cards[index]])
                    // II. increase score by 2
                    Concentration.score += 2
                    let timeInterval = cards[index].date!.timeIntervalSince(cards[matchIndex].date!)
                    // III. reward user for bonus points if matched quickly
                    Concentration.score += Concentration.timeReward(timeInterval: timeInterval)
                } else {
                    // Option 2. The chosen card does not match the card that's already up
                    // I. deduct points if either cards has been flipped more than once and not matched
                    if cards[index].flippedCount > 1 || cards[matchIndex].flippedCount > 1 {
                        Concentration.score -= 1
                    }
                }
                // flip up the card chosen.  There is no longer only one card up, so reset index to nil
                faceUpCardsIndex.append(index)
//                cards[index].isFaceUp = true
//                indexOfOneAndOnlyFaceUpCard = nil
            } else {
            // B. Either no cards or 2 cards are face up
                // 1. first flip every card down, then flip up the card chosen, and add it to index as the only face up card
//                for flipdownIndex in cards.indices {
//                    cards[flipdownIndex].isFaceUp = false
//                }
//                cards[index].isFaceUp = true
                indexOfOneAndOnlyFaceUpCard = index
            }
        }
    }
    static func timeReward(timeInterval: Double) -> Int {
        // User gets an additional point if cards are flipped less than 10 seconds
        let rewardInterval = 10.0
        if timeInterval < rewardInterval {
            return 1
        }
        return 0
    }
    
    init(numberOfPairsOfCards: Int) {
        assert(numberOfPairsOfCards > 0, "Concentration.init(\(numberOfPairsOfCards): you must have at least one pair of cards")
        for _ in 0..<numberOfPairsOfCards {
            let card = Card()
            cards.append(card) // struct card gets copied when it's appended to an array
            cards.append(card) // matching card
        }
        
        // TODO: Shuffle the cards - homework
        var randomCards = [Card]()
        while cards.count > 0 {
            let randomIndex = Int(arc4random_uniform(UInt32((cards.count-1))))
            // To prevent going out of bounds of cards array
            if randomIndex < cards.count {
                randomCards.append(cards.remove(at: randomIndex))
            }
        }
        cards = randomCards
    }
    
}

extension Collection {
    // if collection count is 1, return the first element of the collection to variable oneAndOnly, else return nil
    var oneAndOnly: Element? {
        return count == 1 ? first : nil
    }
}









