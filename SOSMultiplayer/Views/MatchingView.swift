//
//  MatchingView.swift
//  SOSMultiplayer
//
//  Created by f on 23.06.2022.
//

import SwiftUI

struct MatchingView: View {
    
    @StateObject private var game: SOSGame
    
    let player: LocalNetworkPlayer
    
    init() {
        let game = SOSGame()
        _game = .init(wrappedValue: game)
        let player = LocalNetworkPlayer(game: game, actorSystem: localNetworkSystem)
        localNetworkSystem.receptionist.checkIn(player, tag: "x")
        self.player = player
        
        game.opponent = nil
    }
    
    var body: some View {
        VStack {
            Text("My id: \(String(describing: player.id))")
            
            if let opponent = game.opponent {
                Text(String(describing: opponent.id))
            } else {
                ProgressView()
                    .task {
                        await startMatching()
                    }
            }
        }
    }
    
    func startMatching() async {
        guard game.opponent == nil else { return }
        
        let listing = await localNetworkSystem.receptionist.listing(of: LocalNetworkPlayer.self, tag: "x")
        
        for try await opponent in listing where opponent.id != self.player.id {
            game.foundOpponent(opponent, myself: self.player, informOpponent: true)
        }
        // QUESTION: is it possible to step over closure, because it is async?
        return
    }
}

//struct MatchingView_Previews: PreviewProvider {
//    static var previews: some View {
//        MatchingView()
//    }
//}
