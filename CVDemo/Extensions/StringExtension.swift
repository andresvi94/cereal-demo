//
//  StringExtension.swift
//  CerealDemo
//
//  Created by Andrés Vinueza on 12/14/22.
//

import Foundation


extension String {
    func convertSnakeToSentenceCase() -> String {
        return self
            .replacingOccurrences(of: "_",
                                  with: "  ",
                                  options: .regularExpression,
                                  range: range(of: self))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .capitalized
    }
}
