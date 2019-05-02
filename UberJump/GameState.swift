//
//  GameState.swift
//  UberJump
//
//  Created by Adriano Ramos on 02/05/19.
//  Copyright © 2019 Adriano Ramos. All rights reserved.
//

import Foundation

class GameState {
    var score: Int
    var highScore: Int
    var stars: Int
    
    init() {
        score = 0
        highScore = 0
        stars = 0
        
        // Load game state  | UserDefaults is a simple way to persist small bits of data on the device.
        let defaults = UserDefaults.standard
        
        highScore = defaults.integer(forKey: "highScore")
        stars = defaults.integer(forKey: "stars")
    }
    
    func saveState() {
        // Update highscore if the current score is greater
        highScore = max(score, highScore)
        
        // Store in user defaults
        let defaults = UserDefaults.standard
        defaults.set(highScore, forKey: "highScore")
        defaults.set(stars, forKey: "stars")
        UserDefaults.standard.synchronize()
    }
    
    class var sharedInstance: GameState {
        struct Singleton {
            static let instance = GameState()
        }
        
        return Singleton.instance
    }
}
