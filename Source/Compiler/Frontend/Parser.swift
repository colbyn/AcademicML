//
//  Parser.swift
//  AcademicML
//
//  Created by Colbyn Wadman on 8/17/22.
//

import Foundation
import DequeModule

extension CF {
    fileprivate enum PResult<V, E> {
        case err(E)
        case ok(V)
    }
    static func toTokens(source: String) -> Deque<Token> {
        var tokens: Deque<Token> = []
        func newToken(given: (Int, String.Element)) -> Token {
            let range = ParserRange(start: given.0, end: given.0 + 1)
            let text = "\(given.1)"
            let token = Token(range: range, text: text)
            return token
        }
        func insertGuard(given: (Int, String.Element), match: String.Element, wordDef: (String) -> Bool) -> Bool {
            if given.1 == match {
                if let last = tokens.popLast() {
                    if wordDef(last.text) {
                        let range = ParserRange(start: last.range.start, end: given.0 + 1)
                        let text = "\(last.text)\(given.1)"
                        let token = Token(range: range, text: text)
                        tokens.append(token)
                    } else {
                        tokens.append(contentsOf: [last, newToken(given: given)])
                    }
                } else {
                    tokens.append(newToken(given: given))
                }
                return true
            } else {
                return false
            }
        }
        func insertGuard(given: (Int, String.Element), wordDef: (String.Element) -> Bool) -> Bool {
            if wordDef(given.1) {
                if let last = tokens.popLast() {
                    if last.text.allSatisfy(wordDef) {
                        let range = ParserRange(start: last.range.start, end: given.0 + 1)
                        let text = "\(last.text)\(given.1)"
                        let token = Token(range: range, text: text)
                        tokens.append(token)
                    } else {
                        tokens.append(contentsOf: [last, newToken(given: given)])
                    }
                } else {
                    tokens.append(newToken(given: given))
                }
                return true
            } else {
                return false
            }
        }
        for char in source.enumerated() {
            if insertGuard(given: char, match: "\\", wordDef: { _ in return false}) {
                continue
            }
            if insertGuard(given: char, wordDef: {$0.isLetter || $0.isNumber || $0.oneOf(["!", "\\", ",", ";", ".", "$"])}) {
                continue
            }
            if insertGuard(given: char, wordDef: {$0.isWhitespace || $0.isNewline}) {
                continue
            }
            if insertGuard(given: char, wordDef: {$0.oneOf(["=", "<", ">"])}) {
                continue
            }
            tokens.append(newToken(given: char))
        }
        return tokens
    }
    static func toAst(isTopLevel: Bool = false, tokens: inout Deque<Token>) -> [Node] {
        enum ParserError: Error {
            case endOfFile
            case noMatch
        }
        func whitespace() -> Token? {
            tryConsume({$0.isWhitespace}).ok()
        }
        func tryConsume(_ f: (Token) -> Bool) -> Result<Token, ParserError> {
            if let token = tokens.popFirst() {
                if f(token) {
                    return Result.success(token)
                } else {
                    tokens.prepend(token)
                    return Result.failure(ParserError.noMatch)
                }
            }
            return Result.failure(ParserError.endOfFile)
        }
        func consumeUntilMatchOrNewline(
            _ f: (Token) -> Bool
        ) -> PResult<PResult<([Token], Token), [Token]>, ParserError> {
            let origional = tokens
            var xs: Deque<Token> = []
            while let token = tokens.popFirst() {
                if f(token) {
                    return PResult.ok(PResult.ok((Array(xs), token)))
                }
                if token.text.contains(where: {$0.isNewline}) {
                    xs.append(token)
                    return PResult.ok(PResult.err(Array(xs)))
                }
                xs.append(token)
            }
            tokens = origional
            return PResult.err(ParserError.noMatch)
        }
        func parseString() -> StringToken? {
            guard let open = tryConsume({$0.text == "“" || $0.text == "\""}).ok() else {
                return nil
            }
            let f: (Token) -> Bool = {token in
                if open.text == "\"" {
                    return token.text == "\""
                }
                if open.text == "“" {
                    return token.text == "”"
                }
                return false
            }
            func mergeStringTokens(_ xs: [Token]) -> Token? {
                if xs.count == 1 {
                    return xs[0]
                }
                if xs.count > 1 {
                    let range = ParserRange(
                        start: xs.first!.range.start,
                        end: xs.last!.range.end
                    )
                    var text = ""
                    for x in xs {
                        text += x.text
                    }
                    return Token(range: range, text: text)
                }
                return nil
            }
            switch consumeUntilMatchOrNewline(f) {
            case let .ok(.ok((xs, end))):
                let string = mergeStringTokens(xs)
                return StringToken(open: open, value: string, close: end)
            case let .ok(.err(xs)):
                let string = mergeStringTokens(xs)
                return StringToken(open: open, value: string, close: nil)
            case .err(.noMatch): return nil
            case .err(.endOfFile): fatalError("not possible")
            }
        }
        func forward(isTopLevel: Bool = false, ignoreBlocks: Bool = false) -> Node? {
            if isTopLevel {
                if let macroRules = parseMacroRules() {
                    return Node.macroRules(macroRules)
                }
            }
            if let string = parseString() {
                return Node.string(string)
            }
            if let cmd = parseCmd() {
                return Node.cmd(cmd)
            }
            if let block = parseBlock() {
                return Node.block(block)
            }
            if let token = tokens.popFirst() {
                if ignoreBlocks && (token.isOpenBlock || token.isCloseBlock) {
                    tokens.prepend(token)
                    return nil
                } else {
                    return Node.text(token)
                }
            }
            return nil
        }
        func parseCmdScript() -> Node.Cmd.CmdScriptOp? {
            guard let token = tryConsume({$0.isPrefixOp}).ok() else {
                return nil
            }
            guard let node = forward(ignoreBlocks: true) else {
                tokens.prepend(token)
                return nil
            }
            return Node.Cmd.CmdScriptOp(op: token, node: node)
        }
        func parseBlock(forOpenToken: String? = nil, ensureClose: Bool? = nil) -> Node.Block? {
            let origional = tokens
            guard case let .success(openToken) = tryConsume({
                if let match = forOpenToken {
                    return $0.isOpenBlock || $0.text == match
                } else {
                    return $0.isOpenBlock
                }
            }) else {
                return nil
            }
            var nodes: Deque<Node> = Deque()
            while let node = forward(ignoreBlocks: true) {
                nodes.append(node)
            }
            let closeToken = tryConsume({openToken.isMatchingCloseToken(closeToken: $0)}).ok()
            if ensureClose == true {
                if closeToken != nil {
                    return Node.Block(open: openToken, children: Array(nodes), close: closeToken)
                } else {
                    tokens = origional
                    return nil
                }
            } else {
                return Node.Block(open: openToken, children: Array(nodes), close: closeToken)
            }
        }
        func parseMacroRuleBinder() -> Node.MacroRules.Rule.Binder? {
            guard let openTk = tryConsume({$0.isOpenBlock}).ok() else {
                return nil
            }
            guard let ident = tryConsume({$0.isMacroVar}).ok() else {
                tokens.prepend(openTk)
                return nil
            }
            guard let closeTk = tryConsume({openTk.isMatchingCloseToken(closeToken: $0)}).ok() else {
                tokens.prepend(ident)
                tokens.prepend(openTk)
                return nil
            }
            return Node.MacroRules.Rule.Binder(openTk: openTk, ident: ident, closeTk: closeTk)
        }
//        func parseMacroRule() -> Node.MacroRules.Rule? {
//            let origional = tokens
//            guard let openTk = tryConsume({$0.text == "["}).ok() else {
//                return nil
//            }
//            var binders: [Node.MacroRules.Rule.Binder] = []
//            while let binder = parseMacroRuleBinder() {
//                binders.append(binder)
//            }
//            guard let closeTk = tryConsume({$0.text == "]"}).ok() else {
//                tokens = origional
//                return nil
//            }
//            guard let forwardArrow = tryConsume({$0.text == "=>"}).ok() else {
//                tokens = origional
//                return nil
//            }
//            return Node.MacroRules.Rule(
//                openSquareParen: openTk,
//                binders: binders,
//                closeSquareParen: closeTk,
//                forwardArrow: <#T##Token#>,
//                target: <#T##Node.Block#>
//            )
//        }
        func parseMacroRules() -> Node.MacroRules? {
            let origional = tokens
            guard let macroRulesKeyword = tryConsume({$0.text == "\\macroRules!"}).ok() else {
                return nil
            }
            guard let header = parseBlock(forOpenToken: "[", ensureClose: true) else {
                tokens.prepend(macroRulesKeyword)
                return nil
            }
            guard let macroIdent = header.unpackSignleChild().flatMap({$0.unpackCmdIdent()}) else {
                tokens = origional
                return nil
            }
            guard let block = parseBlock(forOpenToken: "{", ensureClose: true) else {
                tokens = origional
                return nil
            }
            var rules: [Node.MacroRules.Rule] = []
            let children = Array(block.children.filter({!$0.isWhitespace}).enumerated())
            for (ix, child) in children {
                if ix >= 1 && (children.count > ix + 1) {
                    if let arrow = child.unpackMatchingText(text: "=>") {
                        if let left = children[ix - 1].element.unpackBlock(forEnclosureKind: EnclosureKind.squareParen) {
                            var binders: [Node.MacroRules.Rule.Binder] = []
                            for pattern in left.children.filter({!$0.isWhitespace}) {
                                if let binder = pattern.unpackBlock(forEnclosureKind: .curlyBrace) {
                                    if let binderVar = binder.unpackSignleTokenChild().filter({$0.isMacroVar}) {
                                        binders.append(Node.MacroRules.Rule.Binder(
                                            openTk: binder.open,
                                            ident: binderVar,
                                            closeTk: binder.close!
                                        ))
                                    }
                                }
                                else if let binder = pattern.unpackBlock(forEnclosureKind: .parens) {
                                    if let binderVar = binder.unpackSignleTokenChild().filter({$0.isMacroVar}) {
                                        binders.append(Node.MacroRules.Rule.Binder(
                                            openTk: binder.open,
                                            ident: binderVar,
                                            closeTk: binder.close!
                                        ))
                                    }
                                }
                                else if let binder = pattern.unpackBlock(forEnclosureKind: .squareParen) {
                                    if let binderVar = binder.unpackSignleTokenChild().filter({$0.isMacroVar}) {
                                        binders.append(Node.MacroRules.Rule.Binder(
                                            openTk: binder.open,
                                            ident: binderVar,
                                            closeTk: binder.close!
                                        ))
                                    }
                                }
                            }
                            if let right = children[ix + 1].element.unpackBlock(forEnclosureKind: EnclosureKind.curlyBrace) {
                                rules.append(Node.MacroRules.Rule(
                                    openSquareParen: left.open,
                                    binders: binders,
                                    closeSquareParen: left.close!,
                                    forwardArrow: arrow,
                                    target: right
                                ))
                            }
                        }
                    }
                }
            }
            return Node.MacroRules(
                macroRulesKeyword: macroRulesKeyword,
                openSquareBracket: header.open,
                macroIdent: macroIdent,
                closeSquareBracket: header.close!,
                openBrace: block.open,
                rules: rules,
                closeBrace: block.close!
            )
        }
        func parseWhereBlock() -> Node.Cmd.RewriteRules? {
            guard let whereTk = tryConsume({$0.text == "\\where!"}).ok() else {
                return nil
            }
            guard let block = parseBlock(forOpenToken: "{", ensureClose: true) else {
                tokens.prepend(whereTk)
                return nil
            }
            var patterns: [Node.Cmd.RewriteRules.Rule] = []
            let children = Array(block.children.filter({!$0.isWhitespace}).enumerated())
            for (ix, child) in children {
                if ix >= 1 && (children.count > ix + 1) {
                    if let arrow = child.unpackMatchingText(text: "=>") {
                        let left = children[ix - 1].element
                        let right = children[ix + 1].element
                        patterns.append(Node.Cmd.RewriteRules.Rule(pattern: left, forwardArrow: arrow, target: right))
                    }
                }
            }
            return Node.Cmd.RewriteRules(whereTk: whereTk, openTk: block.open, rules: patterns, closeTk: block.close!)
        }
        func parseArgument() -> Node.Cmd.Argument? {
            if let script = parseCmdScript() {
                return Node.Cmd.Argument.script(script)
            }
            if let block = parseBlock() {
                return Node.Cmd.Argument.block(block)
            }
            return nil
        }
        func parseCmd() -> Node.Cmd? {
            guard case let .success(ident) = tryConsume({$0.isIdent && $0.text != "\\macroRules!"}) else {return nil}
            var args: Deque<Node.Cmd.Argument> = Deque()
//            while let script = parseCmdScript() {
//                scripts.append(script)
//            }
//            while let arg = parseBlock() {
//                args.append(arg)
//            }
            while let arg = parseArgument() {
                args.append(arg)
            }
            let macro = parseWhereBlock()
            return Node.Cmd(ident: ident, args: Array(args), rewriteRules: macro)
        }
        var nodes: Deque<Node> = Deque()
        while let node = forward(isTopLevel: isTopLevel) {
            nodes.append(node)
        }
        assert(tokens.isEmpty)
        return Array(nodes)
    }
}
