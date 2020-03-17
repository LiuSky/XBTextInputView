//
//  XBTextHelp.swift
//  XBTextInputView
//
//  Created by xiaobin liu on 2020/3/17.
//

import UIKit
import Foundation

/// MARK - extension
extension String {
    
    func substring(with nsrange: NSRange) -> String {
        guard let range = Range(nsrange, in: self) else { return "" }
        return String(self[range])
    }

    var length: Int {
        return count
    }

    subscript(i: Int) -> String {
        return self[i ..< i + 1]
    }

    subscript(r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}
