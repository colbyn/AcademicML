//
//  TextEditor.swift
//  AcademicML
//
//  Created by Colbyn Wadman on 8/10/22.
//

import Foundation
import SwiftUI
import UIKit
import OrderedCollections
import Combine


//class UITextInputCodeTokenizer: UITextInputStringTokenizer {
//    override func isPosition(
//        _ position: UITextPosition,
//        atBoundary granularity: UITextGranularity,
//        inDirection direction: UITextDirection
//    ) -> Bool {
//        let result = super.isPosition(position, atBoundary: granularity, inDirection: direction)
//        print("isPosition [1]:", result)
//        return result
//    }
//
//    override func isPosition(
//        _ position: UITextPosition,
//        withinTextUnit granularity: UITextGranularity,
//        inDirection direction: UITextDirection
//    ) -> Bool {
//        let result = super.isPosition(position, withinTextUnit: granularity, inDirection: direction)
//        print("isPosition [2]:", result)
//        return result
//    }
//
//    override func position(
//        from position: UITextPosition,
//        toBoundary granularity: UITextGranularity,
//        inDirection direction: UITextDirection
//    ) -> UITextPosition? {
//        let result = super.position(from: position, toBoundary: granularity, inDirection: direction)
//        print("position:", result)
//        return result
//    }
//
//    override func rangeEnclosingPosition(
//        _ position: UITextPosition,
//        with granularity: UITextGranularity,
//        inDirection direction: UITextDirection
//    ) -> UITextRange? {
//        let result = super.rangeEnclosingPosition(position, with: granularity, inDirection: direction)
//        print("rangeEnclosingPosition:", result)
//        return result
//    }
//}

class UICodeView: UITextView {
    
}

class SSTextEditorViewController: UIViewController, UITextViewDelegate, NSLayoutManagerDelegate {
    var filePath: URL!
    var textView = UICodeView()
    
    override var keyCommands: [UIKeyCommand]? {[
        UIKeyCommand(
            title: "Save",
            action: #selector(saveDocument),
            input: "s",
            modifierFlags: .command
        )
    ]}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.layoutManager.delegate = self
        textView.isScrollEnabled = true
        textView.showsHorizontalScrollIndicator = true
        textView.showsVerticalScrollIndicator = true
        textView.font = UIFont.monospacedFont(size: 20)
        textView.delegate = self
        textView.spellCheckingType = UITextSpellCheckingType.no
        textView.autocorrectionType = UITextAutocorrectionType.no
        textView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leftAnchor.constraint(equalTo: view.leftAnchor),
            textView.rightAnchor.constraint(equalTo: view.rightAnchor),
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        runHighlighter()
    }
    
    @objc func saveDocument() -> URL {
        print("Saving document: \(filePath!)")
        try! textView.text.write(to: filePath!, atomically: true, encoding: textView.text.fastestEncoding)
        return filePath!
    }
    
    func textViewDidChange(_ _: UITextView) {
        runHighlighter()
    }
    
    func runHighlighter() {
//        print("running runHighlighter")
//        print(String(repeating: "-", count: 80))
        let cursor = textView.selectedRange
        textView.isScrollEnabled = false
        guard let source = textView.text else {
            return
        }
//        var tokens = Parser.toTokens(source: textView.text)
//        let nodes = Parser.toAst(tokens: &tokens)
        let highlights = CF.parseHighlights(source: source)
        let attrs = NSMutableAttributedString(string: source)
        let inDarkMode = self.traitCollection.userInterfaceStyle == .dark
//        let colors = Parser.Highlight.lightColors
//        let colors = RandomColorGen.lightColors
        let colors: [UIColor] = inDarkMode ? CF.Highlight.darkUIExprColors : CF.Highlight.lightUIExprColors
        let stringColor: UIColor = inDarkMode ? CF.Highlight.darkUIStringColor : CF.Highlight.lightUIStringColor
        attrs.beginEditing()
        attrs.addAttribute(
            NSAttributedString.Key.font,
            value: UIFont.monospacedFont(size: 20),
            range: NSRange(location: 0, length: source.endIndex.utf16Offset(in: source))
        )
        if inDarkMode {
            attrs.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: UIColor.white,
                range: NSRange(location: 0, length: source.endIndex.utf16Offset(in: source))
            )
        }
        func getAltColor(color: UIColor) -> UIColor {
            inDarkMode ? color.withLuminosity(0.7).withAlphaComponent(0.65) : color.withLuminosity(0.9)
        }
        func highlightBlock(block: CF.Highlight.Enclosure, color: UIColor) {
            attrs.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: color,
                range: block.open.nsRange
            )
            if let close = block.close {
                attrs.addAttribute(
                    NSAttributedString.Key.foregroundColor,
                    value: color,
                    range: close.nsRange
                )
            }
        }
        func highlightCmd(cmd: CF.Highlight.CmdHighlight, color: UIColor) {
            attrs.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: color,
                range: cmd.ident.nsRange
            )
            for arg in cmd.args {
                switch arg {
                case .block(let block):
                    highlightBlock(block: block, color: color)
                case .script(let script):
                    attrs.addAttribute(
                        NSAttributedString.Key.foregroundColor,
                        value: color,
                        range: script.op.nsRange
                    )
                    switch script.node {
                    case .token(let token):
                        attrs.addAttribute(
                            NSAttributedString.Key.foregroundColor,
                            value: color,
                            range: token.nsRange
                        )
                    case .cmd(let cmd):
                        highlightCmd(cmd: cmd, color: color)
                    case .block(let block):
                        highlightBlock(block: block, color: color)
                    }
                }
            }
            if let rewriteRules = cmd.rewriteRules {
                let colorAlt = inDarkMode ? color.withLuminosity(0.7).withAlphaComponent(0.65) : color.withLuminosity(0.9)
//                let colorAlt = inDarkMode ? color.withAlphaComponent(0.65) : color.withLuminosity(0.9)
                attrs.addAttribute(
                    NSAttributedString.Key.foregroundColor,
                    value: colorAlt,
                    range: rewriteRules.whereTk.nsRange
                )
                attrs.addAttribute(
                    NSAttributedString.Key.foregroundColor,
                    value: colorAlt,
                    range: rewriteRules.openTk.nsRange
                )
                attrs.addAttribute(
                    NSAttributedString.Key.foregroundColor,
                    value: colorAlt,
                    range: rewriteRules.closeTk.nsRange
                )
                for rule in rewriteRules.rules {
                    highlightBlock(block: rule.pattern, color: colorAlt)
                    attrs.addAttribute(
                        NSAttributedString.Key.foregroundColor,
                        value: colorAlt,
                        range: rule.forwardArrow.nsRange
                    )
                    highlightBlock(block: rule.target, color: colorAlt)
                }
            }
        }
        func highlightMacroRules(macroRules: CF.Highlight.MacroRulesHighlight, color: UIColor) {
            let colorAlt = getAltColor(color: color)
            attrs.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: colorAlt,
                range: macroRules.macroRulesKeyword.nsRange
            )
            attrs.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: colorAlt,
                range: macroRules.openSquareBracket.nsRange
            )
            attrs.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: color,
                range: macroRules.macroIdent.nsRange
            )
            attrs.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: colorAlt,
                range: macroRules.closeSquareBracket.nsRange
            )
            attrs.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: colorAlt,
                range: macroRules.openBrace.nsRange
            )
            for rule in macroRules.rules {
                attrs.addAttribute(
                    NSAttributedString.Key.foregroundColor,
                    value: colorAlt,
                    range: rule.openSquareParen.nsRange
                )
                for binder in rule.binders {
                    attrs.addAttribute(
                        NSAttributedString.Key.foregroundColor,
                        value: colorAlt,
                        range: binder.openTk.nsRange
                    )
                    attrs.addAttribute(
                        NSAttributedString.Key.foregroundColor,
                        value: color,
                        range: binder.ident.nsRange
                    )
                    attrs.addAttribute(
                        NSAttributedString.Key.foregroundColor,
                        value: colorAlt,
                        range: binder.closeTk.nsRange
                    )
                }
                attrs.addAttribute(
                    NSAttributedString.Key.foregroundColor,
                    value: colorAlt,
                    range: rule.closeSquareParen.nsRange
                )
                attrs.addAttribute(
                    NSAttributedString.Key.foregroundColor,
                    value: colorAlt,
                    range: rule.forwardArrow.nsRange
                )
                attrs.addAttribute(
                    NSAttributedString.Key.foregroundColor,
                    value: colorAlt,
                    range: rule.target.open.nsRange
                )
                attrs.addAttribute(
                    NSAttributedString.Key.foregroundColor,
                    value: colorAlt,
                    range: rule.target.close!.nsRange
                )
            }
            attrs.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: colorAlt,
                range: macroRules.closeBrace.nsRange
            )
        }
        for highlight in highlights {
            switch highlight {
            case .cmd(let cmd):
                let color = colors[cmd.scope.count % colors.count]
                highlightCmd(cmd: cmd, color: color)
            case .macroRules(let macroRules):
                let color = colors[0]
                highlightMacroRules(macroRules: macroRules, color: color)
            case .string(let string):
                let color = stringColor
                let colorAlt = getAltColor(color: color)
                attrs.addAttribute(
                    NSAttributedString.Key.foregroundColor,
                    value: colorAlt,
                    range: string.open.nsRange
                )
                if let value = string.value {
                    attrs.addAttribute(
                        NSAttributedString.Key.foregroundColor,
                        value: color,
                        range: value.nsRange
                    )
                }
                if let close = string.close {
                    attrs.addAttribute(
                        NSAttributedString.Key.foregroundColor,
                        value: colorAlt,
                        range: close.nsRange
                    )
                }
            }
        }
        attrs.endEditing()
        textView.attributedText = attrs
        textView.selectedRange = cursor
        textView.isScrollEnabled = true
    }
    
    func textView(_ _: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            let currentLine = textView.getLineString()
            var indentation = ""
            for char in currentLine {
                if char.isNewline {
                    break
                } else if char.isWhitespace {
                    indentation.append(char)
                } else {
                    break
                }
            }
            let leftward = textView.characterBeforeCursor()
            let rightward = textView.characterAfterCursor()
            textView.insertText("\n")
            textView.insertText(indentation)
            if let selectedRange = textView.selectedTextRange {
                if leftward == "{" && rightward == "}" {
                    // and only if the new position is valid
                    if let newPosition = textView.position(from: selectedRange.start, offset: 0) {
                        textView.insertText("\n")
                        textView.insertText(indentation)
                        // set the new position
                        textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
                        textView.insertText("\t")
                    }
                } else {
                    // and only if the new position is valid
                    if let newPosition = textView.position(from: selectedRange.start, offset: 0) {
                        // set the new position
                        textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
                    }
                }
            }
            return false
        } else if text == "{" {
            if let selectedRange = textView.selectedTextRange {
                let selectedText = textView.text(in: selectedRange) ?? ""
                textView.insertText("{\(selectedText)}")
                if let newPosition = textView.position(from: selectedRange.start, offset: selectedText.count + 1) {
                    textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
                }
            }
            return false
        } else if text == "[" {
            if let selectedRange = textView.selectedTextRange {
                let selectedText = textView.text(in: selectedRange) ?? ""
                textView.insertText("[\(selectedText)]")
                if let newPosition = textView.position(from: selectedRange.start, offset: selectedText.count + 1) {
                    textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
                }
            }
            return false
        } else if text == "(" {
            if let selectedRange = textView.selectedTextRange {
                let selectedText = textView.text(in: selectedRange) ?? ""
                textView.insertText("(\(selectedText))")
                if let newPosition = textView.position(from: selectedRange.start, offset: selectedText.count + 1) {
                    textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
                }
            }
            return false
        }
        return true
    }
    
    func layoutManager(_ layoutManager: NSLayoutManager, shouldBreakLineByWordBeforeCharacterAt charIndex: Int) -> Bool {
        return false
    }
}


class SSTextEditorMasterViewController: UIViewController {
    var packageModel: PackageDataModel!
    var onEditorChange: ((SSTextEditorViewController) -> ())? = nil
    private var container = UIStackView()
    private var cancellables: Set<AnyCancellable> = []
    private var textEditors: [PackageDataModel.File : SSTextEditorViewController] = [:]
    private func addChildViewCtl(_ child: SSTextEditorViewController) {
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            child.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            child.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            child.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    private func removeChildViewCtl(ctl: UIViewController) {
        // Just to be safe, we check that this view controller
        // is actually added to a parent before removing it.
        guard ctl.parent != nil else {
            return
        }
        ctl.willMove(toParent: nil)
        ctl.view.removeFromSuperview()
        ctl.removeFromParent()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        packageModel.$activeFile
            .sink(receiveValue: { newFile in
//                print("packageModel.activeFile [UPDATE]: \(self.packageModel.activeFile) -> \(newFile)")
                let packagePath = self.packageModel.packagePath!
                for child in self.textEditors.values {
                    self.removeChildViewCtl(ctl: child)
                }
                if let newFile = newFile {
                    let filePath = packagePath.appendingPathComponent(newFile.name, isDirectory: false)
                    if let editor = self.textEditors[newFile] {
                        self.addChildViewCtl(editor)
                        if let onEditorChange = self.onEditorChange {
                            onEditorChange(editor)
                        }
                    } else {
                        let source = try! String.init(contentsOf: filePath)
                        let childViewCtl = SSTextEditorViewController()
                        childViewCtl.filePath = filePath
                        childViewCtl.textView.text = source
//                        childViewCtl.runHighlighter()
                        childViewCtl.textView.isEditable = true
//                        self.saveCurrentEditor = {
//                            childViewCtl.saveDocument()
//                        }
                        self.addChildViewCtl(childViewCtl)
                        self.textEditors[newFile] = childViewCtl
                        if let onEditorChange = self.onEditorChange {
                            onEditorChange(childViewCtl)
                        }
                    }
                }
            })
            .store(in: &self.cancellables)
        
        
    }
    func saveAll() {
        for child in self.textEditors.values {
            let _ = child.saveDocument()
        }
    }
}



