//
//  GameState.swift
//  SOSMultiplayer
//
//  Created by f on 18.06.2022.
//

// Types which are used to model the game state.

struct GameMove: Codable, Hashable, Sendable {
    let playerID: ActorIdentity
    let position: Int // between 0 and 8
    
    let team: CharacterTeam
    let teamCharacterID: Int // between 0 and 2
    
    init(playerID: ActorIdentity, position: Int, team: CharacterTeam, teamCharacterID: Int) {
        self.playerID = playerID
        self.position = position
        self.team = team
        self.teamCharacterID = teamCharacterID
    }
    
    var character: String {
        team.select(teamCharacterID)
    }
}

// Represents the state of a tic-tac-fish game, including all the moves currently made and the player identities.
struct GameState: Sendable {
    private var fields: [GameMove?]
    
    private var players: Set<ActorIdentity>
    
    static let winPatterns: Set<Set<Int>> = [
        // row wins
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        // column wins
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        // cross wins
        [0, 4, 8], [6, 4, 2]
    ]
    
    init() {
        self.fields = (0..<9).map { _ in nil }
        self.players = []
    }
    
    // - MARK: Making and inspecting moves
    
    mutating func mark(_ move: GameMove) throws {
        guard move.position >= 0,
              move.position < fields.count else {
            throw IllegalMoveError(move: move)
        }
        
        players.insert(move.playerID)
        self.fields[move.position] = move
    }
    
    func at(position: Int) -> GameMove? {
        guard position >= 0,
              position < fields.count else {
            return nil
        }
        
        return fields[position]
    }
    
    var availablePositions: [Int] {
        return fields.enumerated().filter { $0.element == nil }.map { $0.offset }
    }
    
    // - MARK: End game conditions
    
    func checkWin() -> GameResult? {
        // did player 1 win?
        guard let player1 = players.first else {
            return nil
        }
        if checkWin(of: player1) {
            return .win(player: player1)
        }
        
        // did player 2 win?
        guard let player2 = players.dropFirst().first else {
            return nil
        }
        if checkWin(of: player2) {
            return .win(player: player2)
        }
        
        // was it a draw?
        if (fields.filter { $0 != nil }.count == fields.count) {
            return .draw
        }
        
        // game isn't complete yet
        return nil
    }
    
    func isWinningField(_ position: Int) -> Bool {
        guard checkWin() != nil else {
            return false
        }
        
        for pattern in Self.winPatterns {
            guard pattern.contains(position) else {
                // this position cannot be part of this winning pattern
                continue
            }
            
            assert(pattern.count == 3) // guarantees that the !-unwraps below are safe
            guard let move1 = at(position: pattern.first!) else {
                continue
            }
            guard let move2 = at(position: pattern.dropFirst(1).first!) else {
                continue
            }
            guard move1.playerID == move2.playerID else {
                continue
            }
            guard let move3 = at(position: pattern.dropFirst(2).first!) else {
                continue
            }
            
            if move2.playerID == move3.playerID {
                // yes, this position was part of this pattern, and this pattern has won
                return true
            } // else, this position is
        }
        
        return false
    }
    
    func checkWin(of playerID: ActorIdentity) -> Bool {
        let moves = Set(fields.compactMap { $0 })
        let playerMoves = Set(moves.filter { $0.playerID == playerID })
        let playerPositions = playerMoves.map(\.position)
        
        for pattern in Self.winPatterns where pattern.isSubset(of: playerPositions) {
            return true
        }
        
        return false
    }
    
}

/// Result of a game round; A game can end in a draw or win of a specific player.
enum GameResult {
    case win(player: ActorIdentity)
    case draw
}

/// Thrown when an illegal move was attempted, e.g. storing a move in a field that already has a move assigned to it.
struct IllegalMoveError: Error {
    let move: GameMove
}

