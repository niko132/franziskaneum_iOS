//
//  UnarchiverDelegate.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 18.05.17.
//  Copyright © 2017 Franziskaneum. All rights reserved.
//

import UIKit

public class UnarchiverDelegate: NSObject, NSKeyedUnarchiverDelegate {
	
	public func unarchiver(_ unarchiver: NSKeyedUnarchiver, cannotDecodeObjectOfClassName name: String, originalClasses classNames: [String]) -> AnyClass? {
		print("cannot decode")
		return nil
	}

}
