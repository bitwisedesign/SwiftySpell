//
//  LocalizedStringDetector.swift
//  SwiftySpell
//
//  Created for check_only_localized_strings rule
//

import Foundation
import SwiftSyntax

internal class LocalizedStringDetector {
    /// Determines if a StringLiteralExprSyntax node represents a user-facing localized string
    static func isLocalizedString(_ node: StringLiteralExprSyntax) -> Bool {
        var currentNode: Syntax? = Syntax(node)

        // EARLY CHECK: If this string is directly in an accessibilityIdentifier, exclude it immediately
        // We check this first before any other logic
        while let parent = currentNode?.parent {
            if let functionCall = parent.as(FunctionCallExprSyntax.self) {
                if isAccessibilityIdentifier(functionCall) {
                    return false
                }
            }
            // Also check if we've reached a user-facing context - if so, stop looking for accessibilityIdentifier
            // This prevents us from walking too far up the tree
            if let functionCall = parent.as(FunctionCallExprSyntax.self) {
                if isSwiftUIText(functionCall) || isSwiftUILabel(functionCall) || isLocalizationFunction(functionCall) {
                    break
                }
            }
            currentNode = parent
        }

        // Reset for the main passes
        currentNode = Syntax(node)
        var hasNonUserFacingLabel = false

        // FIRST PASS: Walk all the way up to check if we're in a non-user-facing labeled parameter
        // This works for ANY function/initializer, not just SwiftUI built-ins
        while let parent = currentNode?.parent {
            if let labeledExpr = parent.as(LabeledExprSyntax.self) {
                if isNonUserFacingLabelParameter(labeledExpr) {
                    hasNonUserFacingLabel = true
                }
            }

            currentNode = parent
        }

        // If we found a non-user-facing parameter (systemImage, systemName, etc.), exclude it
        // This works for both built-in SwiftUI and custom functions/modifiers
        if hasNonUserFacingLabel {
            return false
        }

        // SECOND PASS: Check for positive matches
        currentNode = Syntax(node)

        // Walk up the syntax tree to find context
        while let parent = currentNode?.parent {
            // Check for NSLocalizedString and related Foundation functions
            if let functionCall = parent.as(FunctionCallExprSyntax.self) {
                if isLocalizationFunction(functionCall) {
                    return true
                }

                // Check for String(localized:) initializer
                if isStringLocalizedInitializer(functionCall) {
                    return true
                }

                // Check for SwiftUI Text initializer
                if isSwiftUIText(functionCall) {
                    return true
                }

                // Check for SwiftUI Label initializer
                if isSwiftUILabel(functionCall) {
                    return true
                }

                // Check for UIKit method calls
                if isUIKitTextMethod(functionCall) {
                    return true
                }

                // Check for AppKit method calls (macOS)
                if isAppKitTextMethod(functionCall) {
                    return true
                }

                // Check for SwiftUI view modifiers
                if isSwiftUIViewModifier(functionCall) {
                    return true
                }
            }

            // Check for UIKit property assignments
            if let assignment = parent.as(AssignmentExprSyntax.self) {
                if isUIKitTextProperty(assignment) {
                    return true
                }
            }

            // Check for labeled expressions (common in SwiftUI)
            if let labeledExpr = parent.as(LabeledExprSyntax.self) {
                if isUserFacingLabel(labeledExpr) {
                    return true
                }
            }

            currentNode = parent
        }

        return false
    }

    // MARK: - Foundation Localization

    private static func isLocalizationFunction(_ functionCall: FunctionCallExprSyntax) -> Bool {
        let functionName = functionCall.calledExpression.description.trimmingCharacters(in: .whitespaces)

        let localizationFunctions = [
            "NSLocalizedString",
            "NSLocalizedStringWithDefaultValue",
            "NSLocalizedStringFromTable",
            "NSLocalizedStringFromTableInBundle"
        ]

        return localizationFunctions.contains { functionName.contains($0) }
    }

    // MARK: - String(localized:)

    private static func isStringLocalizedInitializer(_ functionCall: FunctionCallExprSyntax) -> Bool {
        let functionName = functionCall.calledExpression.description.trimmingCharacters(in: .whitespaces)

        // Check if it's String initializer
        if functionName.contains("String") {
            // Check if it has "localized" label in arguments
            for argument in functionCall.arguments {
                if let label = argument.label?.text, label == "localized" {
                    return true
                }
            }
        }

        return false
    }

    // MARK: - SwiftUI Text

    private static func isSwiftUIText(_ functionCall: FunctionCallExprSyntax) -> Bool {
        let functionName = functionCall.calledExpression.description.trimmingCharacters(in: .whitespaces)

        // Check for Text("...") or Text(verbatim:)
        if functionName == "Text" || functionName.hasSuffix(".Text") {
            return true
        }

        // Also check if the calledExpression is an identifier
        if let identifierExpr = functionCall.calledExpression.as(DeclReferenceExprSyntax.self) {
            let identifier = identifierExpr.baseName.text
            if identifier == "Text" {
                return true
            }
        }

        return false
    }

    // MARK: - SwiftUI Label

    private static func isSwiftUILabel(_ functionCall: FunctionCallExprSyntax) -> Bool {
        let functionName = functionCall.calledExpression.description.trimmingCharacters(in: .whitespaces)

        // Check for Label("...", systemImage: "...")
        // Only check the title parameter (first unlabeled parameter), NOT systemImage or other resource parameters
        if functionName == "Label" || functionName.hasSuffix(".Label") || functionName.contains("Label") {
            return true
        }

        // Also check if the calledExpression is an identifier
        if let identifierExpr = functionCall.calledExpression.as(DeclReferenceExprSyntax.self) {
            let identifier = identifierExpr.baseName.text
            if identifier == "Label" {
                return true
            }
        }

        return false
    }

    private static func isNonUserFacingLabelParameter(_ labeledExpr: LabeledExprSyntax) -> Bool {
        // Parameters in SwiftUI views that should NOT be spell-checked
        // These are resource/asset names, not user-facing text
        let nonUserFacingParameters = [
            "systemImage",  // SF Symbol name (Label, Button, etc.)
            "systemName",   // SF Symbol name (Image)
            "image",        // Image resource name
            "icon",         // Icon resource name
            "label"         // Queue/identifier labels (DispatchQueue, OperationQueue, etc.)
        ]

        if let label = labeledExpr.label?.text {
            return nonUserFacingParameters.contains(label)
        }

        return false
    }

    private static func isAccessibilityIdentifier(_ functionCall: FunctionCallExprSyntax) -> Bool {
        let functionName = functionCall.calledExpression.description.trimmingCharacters(in: .whitespaces)

        // Check for .accessibilityIdentifier() modifier
        // This is for testing/automation, NOT for users
        // Note: .accessibilityLabel() is NOT excluded because it's spoken by VoiceOver
        if functionName.contains("accessibilityIdentifier") {
            return true
        }

        return false
    }

    // MARK: - UIKit Properties

    private static func isUIKitTextProperty(_ assignment: AssignmentExprSyntax) -> Bool {
        // Look at the left side of the assignment to see if it's a UI text property
        let leftSide = assignment.description.trimmingCharacters(in: .whitespaces)

        let uikitTextProperties = [
            ".text",
            ".placeholder",
            ".title",
            ".message",
            ".attributedText",
            ".attributedPlaceholder",
            // AppKit properties for macOS
            ".stringValue",
            ".messageText",
            ".informativeText"
        ]

        return uikitTextProperties.contains { leftSide.contains($0) }
    }

    // MARK: - UIKit Methods

    private static func isUIKitTextMethod(_ functionCall: FunctionCallExprSyntax) -> Bool {
        let functionName = functionCall.calledExpression.description.trimmingCharacters(in: .whitespaces)

        let uikitTextMethods = [
            "setTitle",
            "setAttributedTitle",
            "addAction",
            "UIAlertController",
            "UIAlertAction",
            "UIBarButtonItem"
        ]

        return uikitTextMethods.contains { functionName.contains($0) }
    }

    // MARK: - AppKit Methods (macOS)

    private static func isAppKitTextMethod(_ functionCall: FunctionCallExprSyntax) -> Bool {
        let functionName = functionCall.calledExpression.description.trimmingCharacters(in: .whitespaces)

        let appkitTextMethods = [
            "NSAlert",
            "NSAlertController",
            "NSButton",
            "NSMenuItem"
        ]

        return appkitTextMethods.contains { functionName.contains($0) }
    }

    // MARK: - SwiftUI View Modifiers

    private static func isSwiftUIViewModifier(_ functionCall: FunctionCallExprSyntax) -> Bool {
        let functionName = functionCall.calledExpression.description.trimmingCharacters(in: .whitespaces)

        let viewModifiers = [
            ".navigationTitle",
            ".navigationBarTitle",
            ".alert",
            ".confirmationDialog",
            ".accessibilityLabel",
            ".accessibilityHint",
            ".accessibilityValue",
            ".help",
            ".toolbar",
            ".popover",
            ".sheet",
            ".fullScreenCover",
            ".contextMenu",
            ".swipeActions"
        ]

        return viewModifiers.contains { functionName.contains($0) }
    }

    // MARK: - Labeled Expressions

    private static func isUserFacingLabel(_ labeledExpr: LabeledExprSyntax) -> Bool {
        guard let label = labeledExpr.label?.text else {
            return false
        }

        let userFacingLabels = [
            "title",
            "message",
            "text",
            "placeholder",
            "label",
            "description",
            "localized",
            "navigationTitle",
            "systemImage" // Often paired with title in SwiftUI
        ]

        return userFacingLabels.contains(label)
    }
}
