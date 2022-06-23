//
//  SOSGame.swift
//  SOSMultiplayer
//
//  Created by f on 18.06.2022.
//

// ViewModel used by the iOS views and UI-driven distributed actors to interact with eachother.
import SwiftUI

@MainActor
class SOSGame: ObservableObject {
    
    @Published var opponent: LocalNetworkPlayer?


    
     func foundOpponent(_ opponent: LocalNetworkPlayer, myself: LocalNetworkPlayer, informOpponent: Bool) {
        self.opponent = opponent
        
        if informOpponent {
            Task {
                try await opponent.startGameWith(opponent: myself, startTurn: false)
            }
        }
    }

    

}

