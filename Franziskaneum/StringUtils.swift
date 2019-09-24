//
//  StringUtils.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 14.05.17.
//  Copyright © 2017 Franziskaneum. All rights reserved.
//

import Foundation

extension String {
	var length: Int {
		get {
			return self.characters.count
		}
	}
	
	func trim() -> String {
		return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
	}
	
	func removeNewline() -> String {
		return self.replacingOccurrences(of: "\n", with: "")
	}
	
	func nilIfEmpty() -> String? {
		if self.isEmpty {
			return nil
		}
		
		return self
	}
	
	func contains(_ string: String) -> Bool {
		return self.range(of: string) != nil
	}
	
	func containsIgnoreCase(_ string: String) -> Bool {
		return self.lowercased().range(of: string.lowercased()) != nil
	}
	
	func indexOf(_ string: String) -> Int {
		if let range = self.range(of: string) {
			return self.characters.distance(from: self.startIndex, to: range.lowerBound)
		}
		
		return -1
	}
	
	func escape() -> String {
		return self.replacingOccurrences(of: "Ä", with: "Ae").replacingOccurrences(of: "Ö", with: "Oe").replacingOccurrences(of: "Ü", with: "Ue").replacingOccurrences(of: "ä", with: "ae").replacingOccurrences(of: "ö", with: "oe").replacingOccurrences(of: "ü", with: "ue").replacingOccurrences(of: "ß", with: "ss")
	}
	
	var boolValue: Bool {
		return NSString(string: self).boolValue
	}
}
