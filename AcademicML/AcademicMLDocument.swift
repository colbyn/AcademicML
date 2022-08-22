//
//  AcademicMLDocument.swift
//  AcademicML
//
//  Created by Colbyn Wadman on 8/10/22.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var amlBundle: UTType {
        UTType(exportedAs: "com.colbyn.aml-bundle")
    }
    static var aml: UTType {
        UTType(exportedAs: "com.colbyn.aml")
    }
}


//struct AcademicMLDocument: FileDocument {
//    var text: String = ""
//    var fileWrapper: FileWrapper? = nil
//
//    init(text: String) {
//        print("[new file]")
//        self.text = text
//    }
//
//    static var readableContentTypes: [UTType] { [.aml] }
//
//    init(configuration: ReadConfiguration) throws {
//        print("[load file]")
//        fileWrapper = configuration.file
////        guard let data = configuration.file.regularFileContents,
////              let string = String(data: data, encoding: .utf8)
////        else {
////            throw CocoaError(.fileReadCorruptFile)
////        }
////        text = string
//        guard let data = configuration.file.regularFileContents else {
//            return
//        }
//        if let string = String(data: data, encoding: .utf8) {
//            text = string
//        } else {
//            throw CocoaError(.fileReadCorruptFile)
//        }
//    }
//
//    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
//        print("[run fileWrapper]")
//        let data = text.data(using: .utf8)!
//        return .init(regularFileWithContents: data)
//    }
//
//    func save(path: URL) {
//
//    }
//}



struct AcademicMLBundleDocument: FileDocument {
    var package: FileWrapper? = nil
    
    init() {
        print("[init notebook]")
    }

    static var readableContentTypes: [UTType] { [.amlBundle] }
    static var writableContentTypes: [UTType] {[
        .aml,
        UTType.plainText,
        UTType.package,
        UTType.text,
        UTType.fileURL,
        UTType.data
    ]}

    init(configuration: ReadConfiguration) throws {
        print("load document")
//        print("configuration.contentType.referenceURL", configuration.contentType.referenceURL)
        package = configuration.file
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        print("Save")
        if let existingFile = configuration.existingFile {
            assert(existingFile.isDirectory)
            return existingFile
        }
        let rootDirectory = FileWrapper(directoryWithFileWrappers: [:])
        assert(rootDirectory.isDirectory)
        return rootDirectory
    }
    
    func load() {
//        let data =
    }
    
//    func save(rootDir: URL, fileName: String, contents: String) {
////        let contents = "Hello world!!!"
////        let child = FileWrapper.init(regularFileWithContents: contents.data(using: contents.fastestEncoding)!)
////        child.preferredFilename = "main.txt"
////        let rootWrapper = FileWrapper(directoryWithFileWrappers: ["main.txt" : child])
//        let child = package!.fileWrappers!["main.txt"]!
//        do {
//            try child.write(
//                to: rootDir.appendingPathComponent(fileName, conformingTo: UTType.plainText),
//                options: [.atomic],
//                originalContentsURL: rootDir.appendingPathComponent(fileName)
//            )
////            try child.write(
////                to: URL(string: "file:///Users/colbyn/Desktop/Untitled.aml-bundle/main.txt")!,
////                options: FileWrapper.WritingOptions.atomic,
////                originalContentsURL: nil
////            )
////            let name = package!.fileWrappers!["main.txt"]!.filename!
////            try package!.fileWrappers!["main.txt"]!.write(
////                to: URL(string: "file:///Users/colbyn/Desktop/Untitled.aml-bundle/\(name)")!,
////                options: [.atomic],
////                originalContentsURL: nil
////            )
//        } catch {
//            print("WRITE ERROR", error)
//        }
////        if let package = package {
////            if let files = package.fileWrappers {
////                if let file = files[fileName] {
////                    package.removeFileWrapper(file)
////                }
////            }
////
////            let child = FileWrapper.init(regularFileWithContents: contents.data(using: contents.fastestEncoding)!)
////            child.preferredFilename = fileName
////            let key = package.addFileWrapper(child)
////            assert(key == fileName)
////
////            do {
////                try child.write(
////                    to: rootDir.appendingPathComponent(fileName, isDirectory: false),
////                    options: [],
////                    originalContentsURL: nil
////                )
////            } catch {
////                print("WRITE ERROR", error)
////            }
////        }
//    }
//    func read(fileName: String) -> String {
//        if let package = package {
//            if let files = package.fileWrappers {
//                if let file = files[fileName] {
//                    if let result = String(data: file.regularFileContents!, encoding: .utf8) {
//                        return result
//                    } else if let result = String(data: file.regularFileContents!, encoding: .utf16) {
//                        return result
//                    } else {
//                        fatalError("TODO? What is the encoding?")
//                    }
//                }
//            }
//        }
//        return ""
//    }
}
