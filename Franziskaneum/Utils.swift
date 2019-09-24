//
//  Utils.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 19.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import Foundation
import UIKit
import TTTAttributedLabel

extension NSAttributedString {
    func trim() -> NSAttributedString {
        var attributedString = self
        // the first is another space char
        while attributedString.string.characters.first == "\n" || attributedString.string.characters.first == " " || attributedString.string.characters.first == " " {
            attributedString = attributedString.attributedSubstring(from: NSMakeRange(1, attributedString.string.characters.count - 1))
        }
        while attributedString.string.characters.last == "\n" || attributedString.string.characters.last == " " || attributedString.string.characters.last == " " {
            attributedString = attributedString.attributedSubstring(from: NSMakeRange(0, attributedString.string.characters.count - 1))
        }
        return attributedString
    }
}

extension UIViewController {
    var isVisible: Bool {
        get {
            return self.isViewLoaded && self.view.window != nil
        }
    }
}

extension UIView {
    public func maskCircle() {
        self.contentMode = UIViewContentMode.scaleAspectFill
        self.layer.cornerRadius = self.frame.size.width / 2.0
        self.layer.masksToBounds = false
        self.clipsToBounds = true
    }
    
    public var frameBottom: CGFloat {
        get {
            return frame.origin.y + frame.height
        }
    }
    
    public var frameHalfHeight: CGFloat {
        get {
            return frame.origin.y + frame.height / 2.0
        }
    }
}

extension UIFont {
    var isBold: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitBold)
    }
    
    var isItalic: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitItalic)
    }
}

extension UILabel {
    public var attributedTextLabelFont: NSAttributedString? {
        get {
            return self.attributedText
        }
        set(attributedText) {
            if let attributedText = attributedText {
                let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)
                mutableAttributedText.enumerateAttribute(NSFontAttributeName, in: NSMakeRange(0, attributedText.length), options: NSAttributedString.EnumerationOptions(rawValue: 0)) { (value, range, stop) -> Void in
                    if let font = value as? UIFont {
                        let symbolicTraits = font.fontDescriptor.symbolicTraits
                        let newFont = UIFont(descriptor: self.font.fontDescriptor.withSymbolicTraits(symbolicTraits)!, size: 0.0)
                        mutableAttributedText.beginEditing()
                        mutableAttributedText.removeAttribute(NSFontAttributeName, range: range)
                        mutableAttributedText.addAttribute(NSFontAttributeName, value: newFont, range: range)
                        mutableAttributedText.endEditing()
                    }
                }
                
                self.attributedText = mutableAttributedText
            } else {
                self.attributedText = attributedText
            }
        }
    }
}

extension TTTAttributedLabel {
    public func addLinksFromAttributedText() -> Void {
        attributedText.enumerateAttribute(NSLinkAttributeName, in: NSMakeRange(0, attributedText.length), options: NSAttributedString.EnumerationOptions(rawValue: 0)) { (value, range, stop) -> Void in
            if let url = value as? URL {
                self.addLink(to: url, with: range)
            } else if let urlString = value as? String, let url = URL(string: urlString) {
                self.addLink(to: url, with: range)
            }
        }
    }
}

extension UIColor {
    public class var franziskaneum: UIColor {
        get {
            return UIColor(red: 162.0/255.0, green: 14.0/255.0, blue: 12.0/255.0, alpha: 1.0)
        }
    }
}
