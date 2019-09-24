//
//  FranziskaneumError.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 05.02.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import Foundation

public enum FranziskaneumError {
    case networkError
    case authenticationFailed
    case fileNotFound
    case noMoreContentAvailable
    case unknownError
    
    func description() -> String {
        switch(self) {
        case .networkError:
            return "Keine Internetverbindung..."
        default:
            return "Ein unbekannter Fehler ist aufgetreten..."
        }
    }
}
