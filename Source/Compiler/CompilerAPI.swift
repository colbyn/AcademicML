//
//  Compiler.swift
//  AcademicML
//
//  Created by Colbyn Wadman on 8/21/22.
//

import Foundation

struct CompilerAPI {
    static func compileFile(filePath: URL, outputDir: URL) {
        if !FileManager.default.fileExists(atPath: outputDir.absoluteString) {
            try! FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        }
        let source = try! String(contentsOf: filePath)
        var tokens = CF.toTokens(source: source)
        let env = CC.Env()
        let nodes1 = CF.toAst(isTopLevel: true, tokens: &tokens)
        let nodes2 = CF.normalize(nodes: nodes1)
//        for node in nodes2 {
//            print(node.stringify())
//        }
        let coreNodes = nodes2.compactMap({$0.toCoreIR(env: env)})
        let htmlCGEnv = HtmlCodeGen.HtmlCGEnv()
        let outFileName = filePath.lastPathComponent.replacingOccurrences(of: ".aml", with: ".html")
        let outputFilePath = outputDir.appendingPathComponent(outFileName, isDirectory: false)
        let output = CC.Node.fragment(coreNodes).toHtml(htmlCGEnv: htmlCGEnv)
        let outputFile = HtmlCodeGen.packHtmlFile(body: output, htmlCGEnv: htmlCGEnv)
        try! outputFile.write(to: outputFilePath, atomically: true, encoding: output.fastestEncoding)
    }
}
