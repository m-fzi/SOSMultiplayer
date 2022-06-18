//
//  Globals.swift
//  SOSMultiplayer
//
//  Created by f on 18.06.2022.
//


// Global values, specifically the actor systems, which are singletons shared by the entire application.


import Distributed

// Shared instance of the local networking sample actor system.

// Note also that in `Info.plist` we must define the appropriate NSBonjourServices
// in order for the peer-to-peer nodes to be able to discover each other.

let localNetworkSystem = LocalNetworkActorSystem()
