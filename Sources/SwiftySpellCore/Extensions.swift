//
//  Extensions.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 10/8/2024.
//

import Foundation
import SwiftSyntax

extension String {
    func matches(_ pattern: String) -> Bool {
        range(of: pattern, options: .regularExpression) != nil
    }

    func replace(_ target: String, _ replacement: String) -> String {
        replacingOccurrences(of: target, with: replacement)
    }

    func remove(_ substring: String) -> String {
        replacingOccurrences(of: substring, with: String())
    }

    func trim() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func trimLastNumbers() -> String {
        replacingOccurrences(of: "\\d+$", with: String(), options: .regularExpression)
    }

    func endsWith(_ suffix: String) -> Bool {
        hasSuffix(suffix)
    }

    /// Removes C-style format specifiers from a string for spell checking
    /// Examples: %d, %s, %f, %@, %.1f, %02d, etc.
    /// - Returns: The cleaned string with format specifiers removed
    func removeFormatSpecifiers() -> String {
        // Remove C-style format specifiers: %d, %s, %f, %@, %.1f, %02d, etc.
        // Pattern: % followed by optional flags/width/precision, then a type character
        let formatSpecifierPattern = "%[-+0# ]*[0-9]*\\.?[0-9]*[hlLzjt]*[@diouxXeEfFgGaAcspn%]"
        return replacingOccurrences(
            of: formatSpecifierPattern,
            with: "",
            options: .regularExpression
        )
    }

    /// Removes Swift string interpolation from a string for spell checking
    /// Examples: \(variable), \(expression), \(object.property)
    /// - Returns: The cleaned string with interpolation removed
    func removeStringInterpolation() -> String {
        // Remove string interpolation: \(...)
        // Pattern matches \( followed by anything until the matching )
        let interpolationPattern = "\\\\\\([^)]*\\)"
        return replacingOccurrences(
            of: interpolationPattern,
            with: "",
            options: .regularExpression
        )
    }

    /// Removes format specifiers and string interpolation from a string for spell checking
    /// - Returns: The cleaned string with format specifiers and interpolation removed
    func removeFormatSpecifiersAndInterpolation() -> String {
        self
            .removeStringInterpolation()
            .removeFormatSpecifiers()
    }
}

extension SyntaxProtocol {
    var isContainedInFunctionBody: Bool {
        var current: SyntaxProtocol? = self
        while let currentNode = current {
            if Syntax(currentNode).asProtocol(SyntaxProtocol.self) is FunctionDeclSyntax {
                return true
            }
            current = currentNode.parent
        }
        return false
    }
}
