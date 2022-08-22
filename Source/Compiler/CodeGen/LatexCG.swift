//
//  LatexCG.swift
//  AcademicML
//
//  Created by Colbyn Wadman on 8/21/22.
//

import Foundation

extension CF {
    static func toLatexInEquationEnv(nodes: [CF.Node]) -> String {
        let source = nodes
            .compactMap({$0.toLatex()})
            .joined()
        return "\\begin{equation*}\\begin{split}\(source)\\end{split}\\end{equation*} "
    }
    static func toLatexInInlineEnv(nodes: [CF.Node]) -> String {
        let source = nodes
            .compactMap({$0.toLatex()})
            .joined()
        return source
    }
}

extension CF.Node {
    fileprivate func toLatex() -> String? {
        func blockToLatex(block: CF.Node.Block) -> String? {
            let open = block.open.text
            let children = block.children.compactMap{$0.toLatex()}.joined()
            let close = block.close?.text ?? ""
            switch block.enclosureKind {
            case .parens:
                return "\\left\(open)\(children)\\right\(close)"
            case .squareParen:
                return "\\left\(open)\(children)\\right\(close)"
            default: ()
            }
            return "\(open)\(children)\(close)"
        }
        func argToLatex(arg: CF.Node.Cmd.Argument) -> String? {
            switch arg {
            case .script(let script):
                return "\(script.op.text)\(script.node.toLatex() ?? "")"
            case .block(let block):
                return blockToLatex(block: block)
            }
        }
        switch self {
        case .text(let token): return token.text
        case .string(let token): return token.text
        case .error(let token): return token.text
        case .cmd(let cmd):
            let ident = cmd.ident.text
            let args = cmd.args.compactMap(argToLatex).joined()
            return "\(ident)\(args)"
        case .block(let block):
            return blockToLatex(block: block)
        case .macroRules(_): return nil
        }
    }
}

