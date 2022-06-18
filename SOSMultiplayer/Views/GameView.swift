//
//  GameView.swift
//  SOSMultiplayer
//
//  Created by f on 18.06.2022.
//

// View representing a game of tic-tac-fish. Includes information which mode we're playing in, and a game field representation.

import SwiftUI
import Distributed

// In this game mode, we discover opposing players on the local network, and initiate a game with them.

// Note that no real protections are implemented against starting games with already in-game players,

struct GameView: View {
    
    @StateObject private var model: GameViewModel
    
    let mode: GameMode
    let player: MyPlayer
    
    init(mode: GameMode, team: CharacterTeam) {
        let model = GameViewModel(team: team)
        self._model = .init(wrappedValue: model)
        self.mode = mode
        
        switch mode {
        case .localNetwork:
            let player = LocalNetworkPlayer(team: team, model: model, actorSystem: localNetworkSystem)
            localNetworkSystem.receptionist.checkIn(player, tag: team.tag)

            self.player = player
            model.opponent = nil // we'll kick off searching for an opponent immediately as View appears
            
        default:
            fatalError("Mode not implemented in this Step: \(model), check the other Step projects of the Sample App")
        }
    }
    
    var body: some View {
        TitleView(selectedTeam: model.team, mode: mode)
        
        Text("My Player ID")
        Text("\(String(describing: self.player.id))").fontWeight(.light)
        
        if let opponent = model.opponent {
            Text("Opponent ID")
            Text(String(describing: opponent.id)).fontWeight(.light)
        } else {
            matchMakingView()
        }
        
        Spacer()
        
        LazyVGrid(columns: model.columns) {
            ForEach(model.fields, id: \.self) { position in
                GameFieldView(position: position, model: model) { position in
                    _ = try await player.makeMove(at: position)
                }
            }
        }
        
        gameResultRowView()
        
        Spacer()
    }
    
}

// - MARK: Additional Views

extension GameView {
    
    func titleText() -> some View {
        let text: Text
        switch mode {
        case .offline:
            text = Text("Playing offline")
        case .localNetwork:
            text = Text("Playing over LocalNetwork")
        }
        
        return VStack {
            Text("Tic Tac Fish 🐟").bold().font(.title)
            text
        }.padding(3)
    }
    
    func matchMakingView() -> some View {
        HStack {
            ProgressView().padding(2)
            Text("Looking for opponent...")
        }.task {
            await startMatchMaking()
        }
    }
    
    func gameResultRowView() -> some View {
        switch model.gameResult {
        case .win(let winnerID):
            if player.id == winnerID {
                return Text("You win!")
            } else {
                return Text("Opponent won!")
            }
        case .draw:
            return Text("Game ended in a Draw!")
        case .none:
            return Text("")
        }
    }
}

// - MARK: Minimal logic helpers

extension GameView {

    /// Start match making by looking for a new opponent to play a game with.
    ///
    /// Note that this is a rather simple implementation, which does not take into account
    /// that the discovered player may already be playing a game, or verifying that they indeed are a
    /// player of the opposing team (we trust the receptionist to list the right opponents).
    func startMatchMaking() async {
        guard model.opponent == nil else {
            return
        }
    
        switch mode {
        case .localNetwork:
            /// As we are playing for our `model.team` team, we try to find a player of the opposing team
            let opponentTeam = model.team == .fish ? CharacterTeam.rodents : CharacterTeam.fish

            /// The local network actor system provides a receptionist implementation that provides us an async sequence
            /// of discovered actors (past and new)
            let listing = await localNetworkSystem.receptionist.listing(of: OpponentPlayer.self, tag: opponentTeam.tag)
            for try await opponent in listing where opponent.id != self.player.id {
                log("matchmaking", "Found opponent: \(opponent)")
                model.foundOpponent(opponent, myself: self.player, informOpponent: true)

                return // make sure to return here, we only need to discover a single opponent
            }
        default:
            fatalError("Mode not implemented in this Step: \(model), check the other Step projects of the Sample App")
        }
    }
    
}

struct TitleView: View {
    
    let selectedTeam: CharacterTeam
    let mode: GameMode?
    
    var body: some View {
        titleText.fontWeight(.bold)
            .font(.largeTitle)
        
        switch mode {
        case .offline: Text("Playing offline\n")
        case .localNetwork: Text("Playing on local network\n")
        case .none: Text("\n")
        }
    }
    
    var titleText: Text {
        switch selectedTeam {
        case .fish:
            return Text("Tic Tac Fish \(CharacterTeam.fish.emojiArray.first!)")
        case .rodents:
            return Text("Tic Tac Rodent \(CharacterTeam.rodents.emojiArray.first!)")
        }
    }
}


struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView(mode: .offline, team: .fish)
    }
}
