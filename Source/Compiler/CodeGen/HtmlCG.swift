//
//  HtmlCG.swift
//  AcademicML
//
//  Created by Colbyn Wadman on 8/20/22.
//

import Foundation
import Collections


struct HtmlCodeGen {
    class HtmlCGEnv {
        var blockMathIds: Deque<String> = Deque()
        var inlineMathIds: Deque<String> = Deque()
        var headings: Deque<CC.Element> = []
    }
    static func packHtmlFile(body: String, htmlCGEnv: HtmlCGEnv) -> String {
        var tocList: [String] = []
        for heading in htmlCGEnv.headings {
            let children = heading.children
            let attrs = [
                "toc": "",
                "entry": heading.name.trimmingCharacters(in: ["\\"])
            ]
            let element = CC.Element(name: "li", attrs: attrs, children: [
                CC.Node.element(CC.Element(
                    name: "a",
                    attrs: ["href" : "#\(heading.attrs["id"] ?? "")"],
                    children: children
                ))
            ])
            tocList.append(element.toHtml(htmlCGEnv: htmlCGEnv))
        }
        let toc = """
<div toc>
<h1 toc-title>Table Of Contents</h1>
<ul toc-entries>\(tocList.joined(separator: "\n"))</ul>
</div>
"""
        return """
<!DOCTYPE html>
<html>
<head>
<!-- FONTS -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Dancing+Script:wght@400;500;600;700&family=DynaPuff:wght@400;500;600;700&family=Playfair+Display:ital,wght@0,500;0,600;0,700;1,400;1,500;1,600;1,700&family=Yomogi&display=swap" rel="stylesheet">
<!-- KATEX & KATEX DEPS -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.0/dist/katex.min.css" integrity="sha384-Xi8rHCmBmhbuyyhbI88391ZKP2dmfnOl4rT9ZfRI7mLTdk1wblIUnrIq35nqwEvC" crossorigin="anonymous">
<script src="https://cdn.jsdelivr.net/npm/katex@0.16.0/dist/katex.min.js" integrity="sha384-X/XCfMm41VSsqRNQgDerQczD69XqmjOOOwYQvr/uuC+j4OPoNhVgjdGFwhvN02Ja" crossorigin="anonymous"></script>
<script src="https://cdn.jsdelivr.net/npm/katex@0.16.0/dist/contrib/mhchem.min.js" integrity="sha384-RTN08a0AXIioPBcVosEqPUfKK+rPp+h1x/izR7xMkdMyuwkcZCWdxO+RSwIFtJXN"  crossorigin="anonymous"></script>
<!-- LOCAL CSS -->
<link rel="stylesheet" href="styling.css">
<style>
* {
    box-sizing: border-box;
}
body {
    margin: 0;
}
</style>
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta charset="utf-8"/>
</head>
<body>
\(toc)
\(body)
<script>
    function runKatecBlockMathIds(id_set) {
        for (const id of id_set) {
            const element = document.getElementById(id);
            katex.render(element.textContent, element, {displayMode: true});
        }
    }
    function runKatecInlineMathIds(id_set) {
        for (const id of id_set) {
            const element = document.getElementById(id);
            katex.render(element.textContent, element, {displayMode: false});
        }
    }
    window.onload = function(){
        runKatecBlockMathIds([\(htmlCGEnv.blockMathIds.map({$0.debugDescription}).joined(separator: ","))])
        runKatecInlineMathIds([\(htmlCGEnv.inlineMathIds.map({$0.debugDescription}).joined(separator: ","))])
    }
</script>
</body>
</html>
"""
    }
    struct Element {
        let tag: String
        var attrs: [String : String?]
        var children: [Node]
        init(tag: String) {
            self.tag = tag
            self.attrs = [:]
            self.children = []
        }
        init(tag: String, attrs: [String : String?], children: [Node]) {
            self.tag = tag
            self.attrs = attrs
            self.children = children
        }
        init(tag: String, children: [Node]) {
            self.tag = tag
            self.attrs = [:]
            self.children = children
        }
    }
    enum Node {
        case element(Element)
        case text(String)
        case fragment([Node])
    }
}

