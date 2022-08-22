//
//  Core.swift
//  AcademicML
//
//  Created by Colbyn Wadman on 8/21/22.
//

import Foundation
import Collections

/// Compiler Core (simplified & normalized) AST
struct CC {
    enum Node {
        case text(String)
        case element(Element)
        case fragment([Node])
        func stringify(identLevel: Int = 0) -> String {
            switch self {
            case .text(let string): return string
            case .element(let element): return element.stringify(identLevel: identLevel)
            case .fragment(let array):
                return array
                    .map({$0.stringify(identLevel: identLevel)})
                    .joined(separator: "\n")
            }
        }
        func toHtml(htmlCGEnv: HtmlCodeGen.HtmlCGEnv, identLevel: Int = 0) -> String {
            switch self {
            case .text(let string):
                return string
            case .element(let element):
                return element.toHtml(htmlCGEnv: htmlCGEnv, identLevel: identLevel)
            case .fragment(let array):
                return array
                    .map({$0.toHtml(htmlCGEnv: htmlCGEnv, identLevel: identLevel)})
                    .joined(separator: "\n")
            }
        }
        func allInlineNodes() -> Bool {
            switch self {
            case .text(_): return true
            case .element(let element): return element.allInlineNodes()
            case .fragment(let array):
                for node in array {
                    if !node.allInlineNodes() {
                        return false
                    }
                }
                return true
            }
        }
    }
    struct Element {
        let name: String
        let attrs: [String : String]
        let children: [Node]
        func rename(newName: String) -> Element {
            Element(name: newName, attrs: self.attrs, children: self.children)
        }
        func withAttr(key: String, value: String) -> Element {
            var newAttrs = attrs
            newAttrs[key] = value
            return Element(name: name, attrs: newAttrs, children: self.children)
        }
        func withAttr(key: String) -> Element {
            var newAttrs = attrs
            newAttrs[key] = ""
            return Element(name: name, attrs: newAttrs, children: self.children)
        }
        func allInlineNodes() -> Bool {
            if !INLINE_HTML_TAGS.contains(self.name) {
                return false
            }
            for child in self.children {
                if !child.allInlineNodes() {
                    return false
                }
            }
            return true
        }
        func stringify(identLevel: Int = 0) -> String {
            let attrs = attrs
                .map({(k, v) in
                    if !v.isEmpty {
                        return "\(k)=\(v)"
                    }
                    return k
                })
                .joined(separator: ",")
            let children = children
                .map({ child in
                    "\(child.stringify(identLevel: identLevel + 4))"
                })
                .joined()
            return "\\\(name)[\(attrs)]{\(children)}"
        }
        func toHtml(htmlCGEnv: HtmlCodeGen.HtmlCGEnv, identLevel: Int = 0) -> String {
            func pack(name: String, attrs: String, children: String) -> String {
                let name = name.trimmingCharacters(in: ["\\"])
                if attrs.isEmpty {
                    return "<\(name)>\(children)</\(name)>"
                } else {
                    return "<\(name) \(attrs)>\(children)</\(name)>"
                }
            }
            var attrs = attrs
            if HEADING_TAGS.contains(name) {
                attrs["id"] = "<UID>"
            }
            if name == "\\inline-math" {
                let id = UUID().uuidString
                htmlCGEnv.inlineMathIds.append(id)
                attrs["id"] = id
                attrs["math"] = "inline"
            }
            if name == "\\math" {
                let id = UUID().uuidString
                htmlCGEnv.blockMathIds.append(id)
                attrs["id"] = id
                attrs["math"] = "block"
            }
            if name == "\\grid" {
                attrs["grid"] = ""
            }
            if name == "\\note" {
                attrs["note"] = ""
            }
            let strAttrs = attrs
                .map({(k, v) in
                    if !v.isEmpty {
                        return "\(k)=\"\(v)\""
                    }
                    return k
                })
                .joined(separator: " ")
            let children = children
                .map({ child in
                    return child.toHtml(htmlCGEnv: htmlCGEnv, identLevel: identLevel + 4)
                })
                .joined()
            if HEADING_TAGS.contains(name) {
                let id = "UID\(children.hashValue)"
                let strAttrs_ = strAttrs.replacingOccurrences(of: "<UID>", with: id)
                let html = pack(name: name, attrs: strAttrs_, children: children)
                let ref = self.withAttr(key: "id", value: id)
                htmlCGEnv.headings.append(ref)
                return html
            }
            if name == "\\note" {
                return pack(name: "div", attrs: strAttrs, children: children)
            }
            if name == "\\grid" {
                return pack(name: "div", attrs: strAttrs, children: children)
            }
            if name == "\\inline-math" {
                return pack(name: "span", attrs: strAttrs, children: children)
            }
            if name == "\\math" {
                return pack(name: "div", attrs: strAttrs, children: children)
            }
            return pack(name: name, attrs: strAttrs, children: children)
        }
    }
    /// Compiler environment
    struct Env {
        var scope: Deque<String> = []
        func newScope(ident: String) -> Env {
            var newScope = scope
            newScope.append(ident)
            return Env(scope: newScope)
        }
        func isDescendantOf(name: String) -> Bool {
            for id in scope.reversed() {
                if id == name {
                    return true
                }
            }
            return false
        }
    }
}


extension CF.Node {
    /// To the ‘core’ intermediate AST representation.
    func toCoreIR(env: CC.Env) -> CC.Node? {
        switch self {
        case .text(let token): return CC.Node.text(token.text)
        case .string(let token): return CC.Node.text(token.text)
        case .error(let token): return CC.Node.text(token.text)
        case .cmd(let cmd): return cmd.toCoreIR(env: env)
        case .block(let block):
            if let xs = block.toCoreIR(env: env) {
                return CC.Node.fragment(xs)
            } else {
                return nil
            }
        case .macroRules(_): return nil
        }
    }
}

extension CF.Node.Cmd {
    /// To the ‘core’ intermediate AST representation.
    func toCoreIR(env: CC.Env) -> CC.Node? {
        /// Standard curly brace based single argument.
        func arg1(
            parseChildrenAs: ((CC.Env, [CF.Node]) -> [CC.Node])? = nil
        ) -> CC.Element? {
            if self.args.count == 1 && self.args[0].isBlock(ofType: .curlyBrace) {
                let block = self.args[0].unpackBlock()!
                if let f = parseChildrenAs {
                    let children = f(env.newScope(ident: self.ident.text), block.children)
                    return CC.Element(
                        name: ident.text,
                        attrs: [:],
                        children: children
                    )
                }
                let children = block.toCoreIR(env: env.newScope(ident: self.ident.text)) ?? []
                return CC.Element(
                    name: ident.text,
                    attrs: [:],
                    children: children
                )
            }
            return nil
        }
        /// Standard square-paren based attributes and curly-brace based argument.
        /// Attributes are optional.
        func optAttrsWithArg1(attrParser: (String) -> [String : String]) -> CC.Element? {
            if let element = arg1() {
                return element
            }
            let arg1IsValid = self.args[0].isBlock(ofType: .squareParen)
            let arg2IsValid = self.args[1].isBlock(ofType: .curlyBrace)
            if self.args.count == 2 && arg1IsValid && arg2IsValid {
                let attrs = attrParser(self.args[0].intoAttrs() ?? "")
                let block = self.args[1].unpackBlock()!
                let children = block.toCoreIR(env: env.newScope(ident: self.ident.text)) ?? []
                return CC.Element(
                    name: ident.text,
                    attrs: attrs,
                    children: children
                )
            }
            return nil
        }
        /// Attribute only arg with no children (curly-brace block).
        /// E.g. `\img[image.jpeg]`
        func attr1(attrParser: (String) -> [String : String]) -> CC.Element? {
            if self.args.count == 1 && self.args[0].isBlock(ofType: .squareParen) {
                let attrs = attrParser(self.args[0].intoAttrs() ?? "")
                return CC.Element(
                    name: ident.text,
                    attrs: attrs,
                    children: []
                )
            }
            return nil
        }
        func mapAttrsWithArg1() -> CC.Element? {
//            let f: ([String]) -> [String : String?] = { xs in
//
//            }
            print("todo")
            return nil
        }
        if HEADING_TAGS.contains(self.ident.text) {
            return arg1().map{
                let elem = CC.Node.element($0)
                
                return elem
            }
        }
        if AML_TAGS.contains(self.ident.text) {
            if ident.text == "\\" {
                let f: (CC.Env, [CF.Node]) -> [CC.Node] = {(_, cs) in
                    let output = CF.toLatexInInlineEnv(nodes: cs)
                    return [CC.Node.text(output)]
                }
                if let element = arg1(parseChildrenAs: f) {
                    return CC.Node.element(element.rename(newName: "\\inline-math"))
                }
                return nil
            }
            if ident.text == "\\math" {
                let f: (CC.Env, [CF.Node]) -> [CC.Node] = {(_, cs) in
                    let output = CF.toLatexInEquationEnv(nodes: cs)
                    return [CC.Node.text(output)]
                }
                if let element = arg1(parseChildrenAs: f) {
                    return CC.Node.element(element)
                }
                return nil
            }
            if ident.text == "\\grid" {
                let f: (String) -> [String : String] = {value in
                    let value = value.filter({!($0.isWhitespace || $0.isNewline)})
                    var dict: [String: String] = [:]
                    switch value {
                    case "1col": dict["col"] = "1"
                    case "2col": dict["col"] = "2"
                    case "3col": dict["col"] = "2"
                    case "4col": dict["col"] = "2"
                    default: ()
                    }
                    return dict
                }
                if let element = optAttrsWithArg1(attrParser: f) {
                    if env.isDescendantOf(name: "\\grid") {
                        return CC.Node.element(element.withAttr(key: "sub-grid"))
                    }
                    return CC.Node.element(element)
                }
                return nil
            }
            if ident.text == "\\note" {
                return arg1().map{CC.Node.element($0)}
            }
            fatalError("should not happen")
        }
        if ALLOWED_HTML_TAGS.contains(self.ident.text) {
            if ident.text == "\\h1" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\h2" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\h3" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\h4" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\h5" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\h6" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\blockquote" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\dd" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\dl" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\dt" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\figcaption" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\figure" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\hr" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\li" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\ol" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\p" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\pre" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\ul" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\a" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\b" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\br" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\cite" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\code" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\em" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\i" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\mark" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\q" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\s" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\small" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\strong" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\sub" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\sup" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\time" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\u" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\img" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\table" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\tbody" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\td" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\tfoot" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\th" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            if ident.text == "\\tr" {
                return mapAttrsWithArg1().map({CC.Node.element($0)})
            }
            fatalError("[html maps] should not happen")
        }
        fatalError("TODO \(ident.text) \(AML_TAGS.contains(self.ident.text))")
    }
}

extension CF.Node.Block {
    /// To the ‘core’ intermediate AST representation.
    func toCoreIR(env: CC.Env) -> [CC.Node]? {
        children.compactMap({$0.toCoreIR(env: env)})
    }
}

