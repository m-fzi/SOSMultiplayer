//
//  Players.swift
//  SOSMultiplayer
//
//  Created by f on 18.06.2022.
//

// Player actor implementations for the game.


import Distributed

// MARK: - GamePlayer Protocol

protocol GamePlayer: DistributedActor, Codable where ID == ActorIdentity { }



// MARK: - Local Networking Player

distributed actor LocalNetworkPlayer: GamePlayer {
    typealias ActorSystem = LocalNetworkActorSystem
    
    let game: SOSGame
    
    init(game: SOSGame, actorSystem: ActorSystem) {
        self.game = game
        self.actorSystem = actorSystem
        
    }
    
    distributed func startGameWith(opponent: LocalNetworkPlayer, startTurn: Bool) async {
        await game.foundOpponent(opponent, myself: self, informOpponent: false)
    }
    
    
    
}
