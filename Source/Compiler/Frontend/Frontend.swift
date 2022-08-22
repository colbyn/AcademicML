//
//  Frontend.swift
//  AcademicML
//
//  Created by Colbyn Wadman on 8/17/22.
//

import Foundation
import DequeModule
import UIKit
import OrderedCollections

/// Compiler Frontend
struct CF {
    enum EnclosureKind {
        case curlyBrace
        case parens
        case squareParen
    }
    struct ParserRange {
        let start: Int
        let end: Int

        var nsRange: NSRange {
            NSRange(location: start, length: end - start)
        }
        var debugDescription: String {
            "ParserRange(\(start),\(end))"
        }
    }
    struct Token: CustomDebugStringConvertible {
        let range: ParserRange
        let text: String
        var debugDescription: String {
            "Token(\(range), \(text.debugDescription))"
        }
        var isWhitespace: Bool {
            text.allSatisfy { char in
                char.isWhitespace || char.isNewline
            }
        }
        var isOp: Bool {
            text == "^" ||
            text == "_" ||
            text == "+" ||
            text == "-" ||
            text == "*"
        }
        var isOpenBlock: Bool {
            switch text {
            case "{": return true
            case "[": return true
            case "(": return true
            default: return false
            }
        }
        /// We dont wanna match parens in command argument.
        var isValidCmdArgBlockToken: Bool {
            switch text {
            case "}": return true
            case "]": return true
            case "{": return true
            case "[": return true
            default: return false
            }
        }
        var isCloseBlock: Bool {
            switch text {
            case "}": return true
            case "]": return true
            case ")": return true
            default: return false
            }
        }
        var isPrefixOp: Bool {
            switch text {
            case "_": return true
            case "^": return true
            default: return false
            }
        }
        var isIdent: Bool {
            text.starts(with: "\\")
        }
        var isMacroVar: Bool {
            text.starts(with: "$")
        }
        func range(source: String) -> Range<String.Index> {
            Range(self.range.nsRange, in: source)!
        }
        func isMatchingCloseToken(closeToken: Token) -> Bool {
            switch self.text {
            case "{": return closeToken.text == "}"
            case "[": return closeToken.text == "]"
            case "(": return closeToken.text == ")"
            default: return false
            }
        }
    }
    /// Either `"..."` or `“...”` (i.e. unicode open close quotes).
    struct StringToken: CustomDebugStringConvertible {
        let open: Token
        let value: Token?
        let close: Token?
        var range: ParserRange {
            let start = open.range.start
            if let close = close {
                return ParserRange(start: start, end: close.range.end)
            }
            if let string = value {
                return ParserRange(start: start, end: string.range.end)
            }
            return open.range
        }
        var debugDescription: String {
            "StringToken(\(open.text)\(value?.text ?? "")\(close?.text ?? " [error]"))"
        }
        var isError: Bool {
            close == nil
        }
        var text: String {
            if let close = close {
                return "\(open.text)\(value?.text ?? "")\(close.text)"
            }
            return "\(open.text)\(value?.text ?? "")"
        }
    }
    /// Frontend Compiler Environment
    class Env {
        let scope: Deque<String>
        var macros: LookupTable<Node.MacroRules> = LookupTable()
        init(scope: Deque<String>) {
            self.scope = scope
        }
        func newScope(ident: String) -> Env {
            var newScope = scope
            newScope.append(ident)
            let newEnv = Env(scope: newScope)
            newEnv.macros = self.macros
            return newEnv
        }
    }
    static func normalize(nodes: [Node]) -> [Node] {
        let env = Env(scope: [])
        return nodes.compactMap{node in
            return node.normalize(env: env)
        }
    }
    enum Node {
        case text(Token)
        /// Arbitrary text between an open and close quotation marks.
        case string(StringToken)
        case error(Token)
        case cmd(Cmd)
        case block(Block)
        case macroRules(MacroRules)
        var isWhitespace: Bool {
            switch self {
            case .text(let token): return token.isWhitespace
            default: return false
            }
        }
        var range: ParserRange {
            switch self {
            case .text(let token): return token.range
            case .string(let token): return token.range
            case .error(let token): return token.range
            case .block(let block): return block.range
            case .cmd(let cmd): return cmd.range
            case .macroRules(let macroRules): return macroRules.range
            }
        }
        func matches(text: String) -> Bool {
            switch self {
            case .text(let token): return token.text == text
            default: return false
            }
        }
        func unpackMatchingText(text: String) -> Token? {
            switch self {
            case .text(let token) where token.text == text: return token
            default: return nil
            }
        }
        func unpackBlock(forEnclosureKind: EnclosureKind? = nil) -> Block? {
            switch self {
            case .block(let block):
                if let enclosureKind = forEnclosureKind {
                    switch enclosureKind {
                    case .curlyBrace:
                        if block.open.text == "{" && block.close?.text == "}" {
                            return block
                        } else {
                            return nil
                        }
                    case .parens:
                        if block.open.text == "[" && block.close?.text == "]" {
                            return block
                        } else {
                            return nil
                        }
                    case .squareParen:
                        if block.open.text == "[" && block.close?.text == "]" {
                            return block
                        } else {
                            return nil
                        }
                    }
                } else {
                    return block
                }
            default: return nil
            }
        }
        func unpackCmd() -> Cmd? {
            switch self {
            case .cmd(let cmd): return cmd
            default: return nil
            }
        }
        func unpackCmdIdent() -> Token? {
            switch self {
            case .cmd(let cmd): return cmd.ident
            default: return nil
            }
        }
        func unpackToken() -> Token? {
            switch self {
            case .text(let text): return text
            default: return nil
            }
        }
        func unpackString() -> StringToken? {
            switch self {
            case .string(let string): return string
            default: return nil
            }
        }
        func stringify(identLevel: Int = 0) -> String {
            switch self {
            case .text(let token): return "text(\(token))"
            case .string(let token): return "string(\(token))"
            case .error(let token): return "error(\(token))"
            case .block(let block): return block.stringify(identLevel: identLevel + 4)
            case .cmd(let cmd): return cmd.stringify(identLevel: identLevel)
            case .macroRules(let macroRules): return macroRules.stringify(identLevel: identLevel)
            }
        }
        func normalize(env: Env) -> Node? {
            switch self {
            case .text(_): return self
            case .string(_): return self
            case .error(_): return self
            case .block(let block): return block.normalize(env: env).map({.block($0)})
            case .cmd(let cmd): return cmd.normalize(env: env).map({.cmd($0)})
            case .macroRules(let macroRules):
                env.macros.insert(macroRules)
                return .macroRules(macroRules)
            }
        }
        struct Cmd {
            let ident: Token
            let args: [Argument]
            let rewriteRules: RewriteRules?
            var range: ParserRange {
                let start = ident.range.start
                if let macro = rewriteRules {
                    let end = macro.closeTk.range.end
                    return ParserRange(start: start, end: end)
                }
                if let last = args.last {
                    let end = last.range.end
                    return ParserRange(start: start, end: end)
                }
                let end = ident.range.end
                return ParserRange(start: start, end: end)
            }
            func stringify(identLevel: Int) -> String {
                if args.isEmpty {
                    return ident.text
                }
                let argWs = String(repeating: " ", count: identLevel + 4)
//                let ops_ = scripts
//                    .map {"\(argWs)\($0.stringify(identLevel: identLevel + 4))"}
                let args_ = args
                    .map {"\(argWs)\($0.stringify(identLevel: identLevel + 4))"}
                let macro_ = rewriteRules?.stringify(identLevel: identLevel + 4) ?? ""
                let values = args_.joined(separator: ",\n")
                let whitespace = String(repeating: " ", count: identLevel)
                if rewriteRules == nil {
                    return "cmd(\n\(argWs)\(ident.text),\n\(values)\n\(whitespace))"
                } else {
                    return "cmd(\n\(argWs)\(ident.text),\n\(values),\n\(argWs)\(macro_),\n\(whitespace))"
                }
            }
            func normalize(env: Env) -> Cmd? {
                let ident = self.ident
                let newEnv = env.newScope(ident: ident.text)
                let args: [Cmd.Argument] = self.args.compactMap({arg in
                    switch arg {
                    case .block(let block):
                        let block = block.normalize(env: newEnv)
                        return block.map({.block($0)})
                    case .script(let script):
                        let node = script.node.normalize(env: newEnv)
                        if let node = node {
                            let script = CmdScriptOp(op: script.op, node: node)
                            return .script(script)
                        } else {
                            return nil
                        }
                    }
                })
                return Cmd(ident: ident, args: args, rewriteRules: nil)
            }
            enum Argument {
                case block(Block)
                case script(CmdScriptOp)
                var range: ParserRange {
                    switch self {
                    case .block(let block): return block.range
                    case .script(let cmdScriptOp): return cmdScriptOp.range
                    }
                }
                var isBlock: Bool {
                    switch self {
                    case .block(_): return true
                    default: return false
                    }
                }
                func isBlock(ofType: EnclosureKind) -> Bool {
                    switch self {
                    case .block(let block): return block.isOfType(type: ofType)
                    default: return false
                    }
                }
                /// Square-paren based enclosure with string/text values.
                func intoAttrs() -> String? {
                    switch self {
                    case .block(let block) where block.isOfType(type: .squareParen):
                        let xs: [String] = block.children.compactMap({ child in
                            if let token = child.unpackToken() {
                                return token.text
                            }
                            if let string = child.unpackString() {
                                return string.text
                            }
                            return nil
                        })
                        return xs.joined()
                    default: return nil
                    }
                }
                func stringify(identLevel: Int) -> String {
                    switch self {
                    case .block(let block): return block.stringify(identLevel: identLevel)
                    case .script(let cmdScriptOp): return cmdScriptOp.stringify(identLevel: identLevel)
                    }
                }
                func unpackBlock() -> Block? {
                    switch self {
                    case .block(let block): return block
                    default: return nil
                    }
                }
            }
            struct RewriteRules {
                let whereTk: Token
                let openTk: Token
                let rules: [Rule]
                let closeTk: Token
                func stringify(identLevel: Int) -> String {
                    let argWs = String(repeating: " ", count: identLevel + 4)
                    let whitespace = String(repeating: " ", count: identLevel)
                    let patterns_ = rules
                        .map {"\(argWs)\($0.stringify(identLevel: identLevel + 4))"}
                        .joined(separator: "\n,")
                    return "RewriteRules(\n\(patterns_),\n\(whitespace))"
                }
                struct Rule {
                    let pattern: Node
                    let forwardArrow: Token
                    let target: Node
                    func stringify(identLevel: Int) -> String {
                        let argWs = String(repeating: " ", count: identLevel + 4)
                        let whitespace = String(repeating: " ", count: identLevel)
                        let pattern_ = pattern.stringify(identLevel: identLevel + 4)
                        let target_ = target.stringify(identLevel: identLevel + 4)
                        return "RewriteRule(\n\(argWs)\(pattern_),\n\(argWs)\(target_)\n\(whitespace))"
                    }
                }
            }
            struct CmdScriptOp {
                let op: Token
                let node: Node
                var range: ParserRange {
                    ParserRange(start: op.range.start, end: node.range.end)
                }
                func stringify(identLevel: Int) -> String {
                    return "CmdScriptOp(\(op.text.debugDescription), \(node.stringify(identLevel: identLevel)))"
                }
            }
        }

        struct Block {
            let open: Token
            let children: [Node]
            let close: Token?
            var validBlock: Bool {
                close != nil
            }
            /// `nil` indicates an invalid block (i.e. parser/syntsx error, such as missing an closing paren).
            var enclosureKind: EnclosureKind? {
                switch (self.open.text, self.close?.text) {
                case ("{", "}"): return EnclosureKind.curlyBrace
                case ("(", ")"): return EnclosureKind.parens
                case ("[", "]"): return EnclosureKind.squareParen
                default: return nil
                }
            }
            var range: ParserRange {
                let start = open.range.start
                if let close = close {
                    return ParserRange(start: start, end: close.range.end)
                }
                if let last = children.last {
                    return ParserRange(start: start, end: last.range.end)
                }
                return open.range
            }
            /// Trim leading and trailing whitespace/newlines.
            func trimWhitespace() -> Block {
                var xs: [Node] = []
                for child in children {
                    if child.isWhitespace && xs.isEmpty {
                        continue
                    }
                    xs.append(child)
                }
                var ys: [Node] = []
                for child in xs.reversed() {
                    if child.isWhitespace && ys.isEmpty {
                        continue
                    }
                    ys.append(child)
                }
                return Block(open: open, children: ys.reversed(), close: close)
            }
            func unpackSignleChild() -> Node? {
                if children.count == 1 {
                    return children[0]
                }
                return nil
            }
            func unpackSignleTokenChild() -> Token? {
                if children.count == 1 {
                    return children[0].unpackToken()
                }
                return nil
            }
            func stringify(identLevel: Int) -> String {
                let argWs = String(repeating: " ", count: identLevel + 4)
                let ys = children
                    .map {"\(argWs)\($0.stringify(identLevel: identLevel + 4))"}
                    .joined(separator: ",\n")
                let whitespace = String(repeating: " ", count: identLevel)
                if validBlock {
                    return "Block\(open.text)\n\(ys)\n\(whitespace)\(close!.text)"
                } else {
                    return "ErrorBlock\(open.text)\(ys)"
                }
            }
            func isOfType(type: EnclosureKind) -> Bool {
                switch type {
                case .curlyBrace:
                    return self.open.text == "{" && self.close?.text == "}"
                case .parens:
                    return self.open.text == "(" && self.close?.text == ")"
                case .squareParen:
                    return self.open.text == "[" && self.close?.text == "]"
                }
            }
            func normalize(env: Env) -> Node.Block? {
                if !validBlock {
                    return nil
                }
                let children = self
                    .trimWhitespace()
                    .children.compactMap({$0.normalize(env: env)})
                return Block(open: open, children: children, close: close)
            }
        }
        
        struct MacroRules: Identifiable, GetKey {
            typealias Key = String
            typealias Value = Self
            internal var id: String {
                return macroIdent.text
            }
            let macroRulesKeyword: Token
            let openSquareBracket: Token
            let macroIdent: Token
            let closeSquareBracket: Token
            let openBrace: Token
            let rules: [Rule]
            let closeBrace: Token
            var range: ParserRange {
                let start = macroRulesKeyword.range
                let end = closeBrace.range
                return ParserRange(start: start.start, end: end.end)
            }
            func stringify(identLevel: Int) -> String {
                let argWs = String(repeating: " ", count: identLevel + 4)
                let rules_ = rules
                    .map {"\(argWs)\($0.stringify(identLevel: identLevel + 4))"}
                    .joined(separator: ",\n")
                let whitespace = String(repeating: " ", count: identLevel)
                return "MacroRules(\n\(argWs)\(macroIdent.text),\n\(rules_)\n\(whitespace))"
            }
            
            struct Rule {
                let openSquareParen: Token
                let binders: [Binder]
                let closeSquareParen: Token
                let forwardArrow: Token
                let target: Node.Block
                
                func stringify(identLevel: Int) -> String {
                    let argWs = String(repeating: " ", count: identLevel + 4)
                    let binders_ = binders
                        .map {"\($0.stringify(identLevel: 0))"}
                    let target_ = target.trimWhitespace().stringify(identLevel: identLevel + 4)
                    let whitespace = String(repeating: " ", count: identLevel)
                    if binders.isEmpty {
                        return "Rule(\n\(argWs)[],\n\(argWs)\(target_),\n\(whitespace))"
                    } else {
                        return "Rule(\n\(argWs)\(binders_),\n\(argWs)\(target_),\n\(whitespace))"
                    }
                }
                
                struct Binder {
                    let openTk: Token
                    let ident: Token
                    let closeTk: Token
                    func stringify(identLevel: Int) -> String {
                        return "\(openTk.text)\(ident.text)\(closeTk.text)"
                    }
                }
            }
        }
    }
}


