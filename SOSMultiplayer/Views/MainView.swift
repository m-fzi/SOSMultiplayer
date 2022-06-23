//
//  MainView.swift
//  SOSMultiplayer
//
//  Created by f on 17.06.2022.
//

// The main view of the application from which the user can select a game mode, and team to play as.

import SwiftUI

struct MainView: View {
    @State private var showMatchSheet = false
    
    var body: some View {
        Button {
            showMatchSheet = true
        } label: {
            Text("SOS Multiplayer")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.black)
        }
        .sheet(isPresented: $showMatchSheet) {
            MatchingView()
        }
    }
        
}






struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
