//
//  Highlighter.swift
//  AcademicML
//
//  Created by Colbyn Wadman on 8/17/22.
//

import Foundation
import UIKit
import OrderedCollections
import DequeModule

extension CF {
    static func parseHighlights(source: String) -> [Highlight] {
        var tokens = CF.toTokens(source: source)
        let nodes = CF.toAst(isTopLevel: true, tokens: &tokens)
        var highlights: Deque<Highlight> = Deque()
        let state = HighlighterState(scope: [])
//        print(String(repeating: "-", count: 80))
        for node in nodes {
            node.extractHighlights(highlights: &highlights, state: state)
//            print(node.stringify())
        }
        return Array(highlights)
    }
    
    struct HighlighterState {
        var scope: [String]
        func newScope(ident: String) -> HighlighterState {
            var newScope = scope
            newScope.append(ident)
            return HighlighterState(scope: newScope)
        }
    }

    enum Highlight {
        case cmd(CmdHighlight)
        case macroRules(MacroRulesHighlight)
        case string(StringHighlight)
        struct StringHighlight {
            let open: ParserRange
            let value: ParserRange?
            let close: ParserRange?
        }
        struct CmdHighlight {
            let ident: ParserRange
            let args: Array<ArgHighlight>
            let rewriteRules: RewriteRulesHighlight?
            let scope: [String]
            enum ArgHighlight {
                case block(Enclosure)
                case script(ScriptHighlight)
            }
            struct ScriptHighlight {
                let op: ParserRange
                let node: CmdScriptOpNode
                enum CmdScriptOpNode {
                    case token(ParserRange)
                    case cmd(CmdHighlight)
                    case block(Enclosure)
                }
            }
            struct RewriteRulesHighlight {
                let whereTk: ParserRange
                let openTk: ParserRange
                let rules: [RuleHighlight]
                let closeTk: ParserRange

                struct RuleHighlight {
                    let pattern: Enclosure
                    let forwardArrow: ParserRange
                    let target: Enclosure
                }
            }
        }

        struct Enclosure {
            let open: ParserRange
            let close: ParserRange?
            var range: ParserRange {
                if let close = close {
                    return ParserRange(start: open.start, end: close.end)
                } else {
                    return open
                }
            }
        }
        
        struct MacroRulesHighlight {
            let macroRulesKeyword: ParserRange
            let openSquareBracket: ParserRange
            let macroIdent: ParserRange
            let closeSquareBracket: ParserRange
            let openBrace: ParserRange
            let rules: [RuleHighlight]
            let closeBrace: ParserRange
            
            struct RuleHighlight {
                let openSquareParen: ParserRange
                let binders: [BinderHighlight]
                let closeSquareParen: ParserRange
                let forwardArrow: ParserRange
                let target: Enclosure
                
                struct BinderHighlight {
                    let openTk: ParserRange
                    let ident: ParserRange
                    let closeTk: ParserRange
                }
            }
        }
        
        static let darkUIStringColor: UIColor = #colorLiteral(red: 0.1941846311, green: 0.991915524, blue: 1, alpha: 1)
        static let darkUIExprColors: [UIColor] = [
            #colorLiteral(red: 1, green: 0.7510948333, blue: 0.381865388, alpha: 1),
            #colorLiteral(red: 0.8662407077, green: 1, blue: 0.381865388, alpha: 1),
            #colorLiteral(red: 0.381865388, green: 0.7982736937, blue: 1, alpha: 1),
            #colorLiteral(red: 0.8115002705, green: 0.381865388, blue: 1, alpha: 1),
            #colorLiteral(red: 0.5378699955, green: 1, blue: 0.381865388, alpha: 1),
            #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1),
            #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1),
            #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1),
            #colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1),
            #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1),
            #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1),
            #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1),
        ]
        static let lightUIStringColor: UIColor = #colorLiteral(red: 0, green: 0.2834656835, blue: 0.6651299596, alpha: 1)
        static let lightUIExprColors: [UIColor] = [
            #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1),
            #colorLiteral(red: 1, green: 0.7510948333, blue: 0.381865388, alpha: 1),
            #colorLiteral(red: 1, green: 0.5409764051, blue: 0.8473142982, alpha: 1),
            #colorLiteral(red: 0.668130815, green: 0.4802306294, blue: 0.4752212167, alpha: 1),
            #colorLiteral(red: 0.239733398, green: 0.6658524871, blue: 0.8382440209, alpha: 1),
            #colorLiteral(red: 1, green: 0.4932718873, blue: 0.4739984274, alpha: 1),
            #colorLiteral(red: 0.664488554, green: 0.6708237529, blue: 0.8379078507, alpha: 1),
            #colorLiteral(red: 0.4797983766, green: 0.276894629, blue: 0.475866735, alpha: 1),
            #colorLiteral(red: 0.8464167714, green: 0.3266258538, blue: 0.8379170299, alpha: 1),
            #colorLiteral(red: 0.2634258866, green: 0.3245458603, blue: 1, alpha: 1),
            #colorLiteral(red: 0.6642242074, green: 0.6642400622, blue: 0.6642315388, alpha: 1),
            #colorLiteral(red: 0.8413977027, green: 0.6747046113, blue: 0.8376429677, alpha: 1),
            #colorLiteral(red: 0.6526787877, green: 0.9948721528, blue: 1, alpha: 1),
            #colorLiteral(red: 1, green: 0.4932718873, blue: 0.4739984274, alpha: 1),
        ]
        static let lightColors: [UIColor] = {
            var colors: [UIColor] = []
            let hueScale = MathUtil.newLinearScale(domain: (0.0, 1.0), range: (0.1, 1.0))
            let saturationScale = MathUtil.newLinearScale(domain: (0.0, 1.0), range: (0.9, 0.9))
            let brightnessScale = MathUtil.newLinearScale(domain: (0.0, 1.0), range: (0.7, 0.9))
            for x in stride(from: 0.0, through: 1.0, by: 1/10) {
                let i = CGFloat(x)
                let color = UIColor(
                    hue: hueScale(i),
                    saturation: saturationScale(i),
                    brightness: brightnessScale(i),
                    alpha: 1.0
                )
                colors.append(color)
            }
            return colors
        }()
    }
}

extension CF.Node {
    func extractHighlights(highlights: inout Deque<CF.Highlight>, state: CF.HighlighterState) {
        switch self {
        case .text(_): ()
        case .string(let string):
            let highlight = CF.Highlight.string(CF.Highlight.StringHighlight(
                open: string.open.range,
                value: string.value?.range,
                close: string.close?.range
            ))
            highlights.append(highlight)
        case .error(_): ()
        case .block(let block):
            block.extractHighlights(highlights: &highlights, state: state)
        case .cmd(let cmd):
            cmd.extractHighlights(highlights: &highlights, state: state)
        case .macroRules(let macroRules):
            macroRules.extractHighlights(highlights: &highlights, state: state)
        }
    }
}

extension CF.Node.Cmd {
    func highlight(state: CF.HighlighterState) -> CF.Highlight.CmdHighlight {
        let ident_ = ident.range
        let args_ = args.map{$0.highlight(state: state)}
        let macro_ = rewriteRules?.highlight()
        return CF.Highlight.CmdHighlight(
            ident: ident_,
            args: args_,
            rewriteRules: macro_,
            scope: state.scope
        )
    }
    func extractHighlights(highlights: inout Deque<CF.Highlight>, state: CF.HighlighterState) {
        highlights.append(CF.Highlight.cmd(self.highlight(state: state)))
        for child in args {
            let newState = state.newScope(ident: ident.text)
            child.extractHighlights(highlights: &highlights, state: newState)
        }
    }
}

extension CF.Node.Cmd.Argument {
    func highlight(state: CF.HighlighterState) -> CF.Highlight.CmdHighlight.ArgHighlight {
        switch self {
        case .block(let block): return CF.Highlight.CmdHighlight.ArgHighlight.block(block.highlight())
        case .script(let script): return CF.Highlight.CmdHighlight.ArgHighlight.script(script.highlight(state: state))
        }
    }
    func extractHighlights(highlights: inout Deque<CF.Highlight>, state: CF.HighlighterState) {
        switch self {
        case .block(let block):
            block.extractHighlights(highlights: &highlights, state: state)
        case .script(_): return ()
        }
    }
}

extension CF.Node.Cmd.RewriteRules {
    func highlight() -> CF.Highlight.CmdHighlight.RewriteRulesHighlight {
        let whereTk_ = whereTk.range
        let openTk_ = openTk.range
        let patterns_ = rules.compactMap{$0.highlight()}
        let closeTk_ = closeTk.range
        return CF.Highlight.CmdHighlight.RewriteRulesHighlight(
            whereTk: whereTk_,
            openTk: openTk_,
            rules: Array(patterns_),
            closeTk: closeTk_
        )
    }
}

extension CF.Node.Cmd.RewriteRules.Rule {
    func highlight() -> CF.Highlight.CmdHighlight.RewriteRulesHighlight.RuleHighlight? {
        if let pattern = pattern.unpackBlock() {
            if let target = target.unpackBlock() {
                return CF.Highlight.CmdHighlight.RewriteRulesHighlight.RuleHighlight(
                    pattern: pattern.highlight(),
                    forwardArrow: forwardArrow.range,
                    target: target.highlight()
                )
            }
        }
        return nil
    }
}

extension CF.Node.Cmd.CmdScriptOp {
    func highlight(state: CF.HighlighterState) -> CF.Highlight.CmdHighlight.ScriptHighlight {
        switch node {
        case .text(let token):
            return CF.Highlight.CmdHighlight.ScriptHighlight(
                op: op.range,
                node: CF.Highlight.CmdHighlight.ScriptHighlight.CmdScriptOpNode.token(token.range)
            )
        case .string(let token):
            return CF.Highlight.CmdHighlight.ScriptHighlight(
                op: op.range,
                node: CF.Highlight.CmdHighlight.ScriptHighlight.CmdScriptOpNode.token(token.range)
            )
        case .error(let token):
            return CF.Highlight.CmdHighlight.ScriptHighlight(
                op: op.range,
                node: CF.Highlight.CmdHighlight.ScriptHighlight.CmdScriptOpNode.token(token.range)
            )
        case .cmd(let cmd):
            return CF.Highlight.CmdHighlight.ScriptHighlight(
                op: op.range,
                node: CF.Highlight.CmdHighlight.ScriptHighlight.CmdScriptOpNode.cmd(cmd.highlight(state: state))
            )
        case .block(let block):
            return CF.Highlight.CmdHighlight.ScriptHighlight(
                op: op.range,
                node: CF.Highlight.CmdHighlight.ScriptHighlight.CmdScriptOpNode.block(block.highlight())
            )
        case .macroRules(let macroRules):
            return CF.Highlight.CmdHighlight.ScriptHighlight(
                op: op.range,
                node: CF.Highlight.CmdHighlight.ScriptHighlight.CmdScriptOpNode.token(macroRules.range)
            )
        }
    }
}

extension CF.Node.Block {
    func highlight() -> CF.Highlight.Enclosure {
        return CF.Highlight.Enclosure(open: open.range, close: close?.range)
    }
    func extractHighlights(highlights: inout Deque<CF.Highlight>, state: CF.HighlighterState) {
        for child in children {
            child.extractHighlights(highlights: &highlights, state: state)
        }
    }
}

extension CF.Node.MacroRules.Rule.Binder {
    func highlight() -> CF.Highlight.MacroRulesHighlight.RuleHighlight.BinderHighlight {
        return CF.Highlight.MacroRulesHighlight.RuleHighlight.BinderHighlight(
            openTk: openTk.range,
            ident: ident.range,
            closeTk: closeTk.range
        )
    }
}

extension CF.Node.MacroRules.Rule {
    func highlight() -> CF.Highlight.MacroRulesHighlight.RuleHighlight? {
        return CF.Highlight.MacroRulesHighlight.RuleHighlight(
            openSquareParen: openSquareParen.range,
            binders: binders.map{$0.highlight()},
            closeSquareParen: closeSquareParen.range,
            forwardArrow: forwardArrow.range,
            target: target.highlight()
        )
    }
}

extension CF.Node.MacroRules {
    func highlight(state: CF.HighlighterState) -> CF.Highlight.MacroRulesHighlight {
        let rules_ = rules.compactMap{$0.highlight()}
        return CF.Highlight.MacroRulesHighlight(
            macroRulesKeyword: macroRulesKeyword.range,
            openSquareBracket: openSquareBracket.range,
            macroIdent: macroIdent.range,
            closeSquareBracket: closeSquareBracket.range,
            openBrace: openBrace.range,
            rules: rules_,
            closeBrace: closeBrace.range
        )
    }
    func extractHighlights(highlights: inout Deque<CF.Highlight>, state: CF.HighlighterState) {
        highlights.append(CF.Highlight.macroRules(self.highlight(state: state)))
        for rule in rules {
            rule.target.extractHighlights(highlights: &highlights, state: state)
        }
    }
}
