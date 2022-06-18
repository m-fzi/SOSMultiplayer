//
//  SOSGame.swift
//  SOSMultiplayer
//
//  Created by f on 18.06.2022.
//

// ViewModel used by the iOS views and UI-driven distributed actors to interact with eachother.


import SwiftUI

@MainActor
class GameViewModel: ObservableObject {
    
    let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let fields = 0..<9
    
    @Published var opponent: OpponentPlayer?
    
    @Published var selectedPositions: Set<Int> = []
    @Published var lastMovePosition: Int? = nil
    @Published var waitingForOpponentMove: Bool = false
    
    @Published var gameState: GameState = .init()
    @Published var gameResult: GameResult?
    
    let team: CharacterTeam
    
    init(team: CharacterTeam) {
        self.team = team
    }
    
    func userMadeMove(move: GameMove) -> GameResult? {
        guard !selectedPositions.contains(move.position) else {
            log("game-model", "illegal player move, already selected position \(move.position)")
            return gameResult
        }
        
        do {
            selectedPositions.insert(move.position)
            try gameState.mark(move)
            
            gameResult = gameState.checkWin()
            
            if let opponent = opponent {
                waitForOpponentMove(true)
                Task {
                    // inform the opponent about this player's move
                    try await opponent.opponentMoved(move)
                    
                    guard gameResult == nil else {
                        // we're done here, the game has some result already
                        return
                    }
                    
                    // the game is not over yet,
                    // ask the opponent to make their move:
                    let opponentMove = try await opponent.makeMove()
                    log("model", "Opponent moved: \(opponentMove)")
                    try markOpponentMove(opponentMove)
                }
            }
        } catch {
            log("game-model", "Move failed, error: \(error)")
        }
        return gameResult
        
    }
    
    /// Poll the UI, and therefore human player, to make a decision which field to make a move on.
    func humanSelectedField() async -> Int {
        for await position in $lastMovePosition.values {
            guard let selectedPosition = position else {
                continue
            }
            
            lastMovePosition = nil // reset the last move
            return selectedPosition
        }
        
        fatalError("Expected a position actually be selected")
    }
    
    func foundOpponent(_ opponent: OpponentPlayer, myself: MyPlayer, informOpponent: Bool) {
        self.opponent = opponent

        // STEP 2: local multiplayer, enable telling the other player
        if informOpponent {
            Task {
                try await opponent.startGameWith(opponent: myself, startTurn: false)
            }
        }
    }
    
    func waitForOpponentMove(_ shouldWait: Bool) {
        log("model", "wait...")
        self.waitingForOpponentMove = shouldWait
    }
    
    func markOpponentMove(_ move: GameMove) throws {
        log("model", "mark opponent move: \(move)")
        assert(move.playerID == opponent?.id)
        
        try gameState.mark(move)
        gameResult = gameState.checkWin()
        
        // now we're free to make our own move, unless the game finished (see isGameDisabled)
        self.waitingForOpponentMove = false
    }
    
    var isGameDisabled: Bool {
        // the game field is disabled when:
        
        // we don't have an opponent yet,
        opponent == nil ||
        // we are waiting for the opponent's move
        waitingForOpponentMove ||
        // or when the game has concluded
        gameResult != nil
    }
}

