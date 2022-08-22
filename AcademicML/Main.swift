//
//  AcademicMLApp.swift
//  AcademicML
//
//  Created by Colbyn Wadman on 8/10/22.
//

import SwiftUI
import UniformTypeIdentifiers
import Combine
import WebKit

fileprivate class OptionalBox<T>: ObservableObject {
    @Published
    var ref: Optional<T> = .none
    var exist: Bool {ref != nil}
}

class FileDataModel: ObservableObject {
    @Published
    var filePath: URL? = nil
    @Published
    var fileEncoding: String.Encoding? = nil
    @Published
    var fileContents: String? = nil
    
    static func load(filePath: URL) -> FileDataModel? {
        var encoding = String.Encoding.utf8
        guard let contents = try? String.init(contentsOf: filePath, usedEncoding: &encoding) else {
            return nil
        }
        let fileDataModel = FileDataModel()
        fileDataModel.fileEncoding = encoding
        fileDataModel.filePath = filePath
        fileDataModel.fileContents = contents
        return fileDataModel
    }
    func save(contents: String) {
//        let encoder = PropertyListEncoder()
//        let data = try! encoder.encode(self)
        try! contents.write(
            to: filePath!,
            atomically: true,
            encoding: fileEncoding ?? contents.fastestEncoding
        )
    }
}

class PackageDataModel: NSObject, ObservableObject {
    @Published
    var packagePath: URL? = nil
    @Published
    var files: [File] = []
    @Published var activeFile: File? = nil
    
    func save() {
        
    }
    
    struct File: Equatable, Hashable {
        let id: UUID
        var name: String
    }
    
    static func load(packagePath: URL) -> PackageDataModel {
        let directoryContents = try! FileManager.default.contentsOfDirectory(
            at: packagePath,
            includingPropertiesForKeys: nil
        )
        var files: [PackageDataModel.File] = []
        for file in directoryContents {
            if file.pathExtension == "aml" {
                files.append(File(id: UUID(), name: file.lastPathComponent))
            }
        }
        let packageDataModel = PackageDataModel()
        packageDataModel.packagePath = packagePath
        packageDataModel.files = files
        return packageDataModel
    }
}


@main
struct AcademicMLApp: App {
    @StateObject private var fileDataModel: OptionalBox<FileDataModel> = OptionalBox()
    @StateObject private var packageDataModel: PackageDataModel = PackageDataModel()
    
    @ViewBuilder var rootView: some View {
        if packageDataModel.packagePath != nil {
            PackageView(packageModel: packageDataModel)
        } else {
            Text("Loading...")
        }
    }
    var body: some Scene {
        DocumentGroup(newDocument: AcademicMLBundleDocument()) { file in
            rootView
                .onAppear(perform: load(with: file))
                .navigationViewStyle(StackNavigationViewStyle())
                .navigationBarHidden(true)
        }
    }
    private func load(with file: FileDocumentConfiguration<AcademicMLBundleDocument>) -> () -> () {
        return {
            let data = PackageDataModel.load(packagePath: file.fileURL!)
            self.packageDataModel.files = data.files
            self.packageDataModel.packagePath = file.fileURL!
        }
    }
}

struct PackageView: View {
    @ObservedObject var packageModel: PackageDataModel
    @State private var showSidebar: Bool = true
    @ViewBuilder var documentView: some View {
        HStack(alignment: .center, spacing: 0) {
            LeftSidebar(packageModel: packageModel, showSidebar: $showSidebar)
            Divider()
            EditorView(packageModel: packageModel)
        }
    }
    var body: some View {
        NavigationView {
            documentView
                .navigationBarTitle("")
                .navigationBarHidden(true)
                .edgesIgnoringSafeArea(.all)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .ignoresSafeArea(.container, edges: .all)
        .statusBar(hidden: true)
    }
    
    
    struct LeftSidebar: View {
        @ObservedObject var packageModel: PackageDataModel
        @Binding var showSidebar: Bool
        @State private var showNewFilePopup: Bool = false
        @State private var newFileName: String = ""
        @Environment(\.colorScheme) var colorScheme
        var body: some View {
            if showSidebar {
                fillSidebar.frame(maxWidth: 300)
            } else {
                hiddenSidebar.frame(maxWidth: 50)
            }
        }
        @ViewBuilder private var hiddenSidebar: some View {
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                Divider()
                Button(action: {
                    showSidebar = true
                }, label: {
                    HStack(alignment: .center, spacing: 8) {
                        Spacer()
                        Image(systemName: "arrow.right.to.line")
                        Spacer()
                    }
                })
                    .padding(12)
            }
        }
        @ViewBuilder private var fillSidebar: some View {
            VStack(alignment: .center, spacing: 0) {
                VStack(alignment: .center, spacing: 0) {
                    Spacer()
                }
                .frame(height: 38)
                topBts
                Divider()
                sidebar
                Spacer()
                Divider()
                Button(action: {
                    showSidebar = false
                }, label: {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: "arrow.left.to.line")
                        Spacer()
                        Text("Hide")
                    }
                })
                    .padding(12)
            }
        }
        @ViewBuilder private var topBts: some View {
            Button(action: {
                showNewFilePopup = true
            }, label: {
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: "plus.square")
                    Spacer()
                    Text("New File")
                }
            })
                .padding(12)
                .popover(isPresented: $showNewFilePopup, content: newFilePopup)
        }
        @ViewBuilder private var sidebar: some View {
            List {
                ForEach(Array(packageModel.files.enumerated()), id: \.1.id) {(ix, file) in
                    Button(action: {
                        packageModel.activeFile = file
                    }, label: {
                        HStack(alignment: .center, spacing: 0) {
                            Image(systemName: "text.quote").padding(.trailing, 8)
                            Text(file.name)
                        }
                    })
                }
            }
        }
        @ViewBuilder private func newFilePopup() -> some View {
            HStack(alignment: .center, spacing: 12) {
                let textColor = colorScheme == .dark ? Color.white : Color.black
                TextField("File name", text: $newFileName)
                    .disableAutocorrection(true)
                    .foregroundColor(validFileName ? textColor : Color.red)
                Button(action: {
                    if validFileName {
                        let packagePath = packageModel.packagePath!
                        let newFilePath = packagePath.appendingPathComponent(newFileName, isDirectory: false)
                        let contents = ""
                        let data = contents.data(using: contents.fastestEncoding)!
                        try! data.write(to: newFilePath)
                        packageModel.files.append(PackageDataModel.File(id: UUID(), name: "\(newFileName).aml"))
                        newFileName = ""
                        showNewFilePopup = false
                    }
                }, label: {
                    Text("Add")
                })
            }
            .frame(minWidth: 400)
            .padding(12)
        }
        private var validFileName: Bool {
            let validLength = newFileName.count > 3
            let names = Set(packageModel.files.map{$0.name})
            let unique = !names.contains(newFileName)
            return validLength && unique
        }
    }
    
//    struct RightPane: View {
//        @ObservedObject var packageModel: PackageDataModel
//        @Binding var showSidebar: Bool
//        @State private var showNewFilePopup: Bool = false
//        @State private var newFileName: String = ""
//        @Environment(\.colorScheme) var colorScheme
//        var body: some View {
//            if showSidebar {
//                fillSidebar.frame(maxWidth: 300)
//            } else {
//                hiddenSidebar.frame(maxWidth: 50)
//            }
//        }
//    }
    
    struct EditorView: View {
        @ObservedObject var packageModel: PackageDataModel
        @StateObject private var saveDoc: OptionalBox<() -> URL> = OptionalBox()
        @StateObject private var saveAllDocs: OptionalBox<() -> ()> = OptionalBox()
        @State private var showPreview: Bool = false
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                VStack(alignment: .center, spacing: 0) {
                    Spacer()
                }
                .frame(height: 38)
                textEditorToolbar.padding(12)
                Divider()
                HStack(alignment: .center, spacing: 0) {
                    textEditor
                    if showPreview {
                        previewPane
                    }
                }
            }
        }
        @ViewBuilder var previewPane: some View {
            if let f = saveDoc.ref {
                let filePath = f()
                let outputDir = packageModel
                    .packagePath!
                    .appendingPathComponent("output", isDirectory: true)
                WrapView {
                    let view = WKWebView()
                    view.allowsBackForwardNavigationGestures = true
                    view.loadFileURL(filePath, allowingReadAccessTo: outputDir)
                    return view
                }
            }
        }
        @ViewBuilder var textEditorToolbar: some View {
            HStack(alignment: .center, spacing: 8) {
                Button(action: {
                    if let f = saveDoc.ref {
                        let _ = f()
                    }
                }, label: {
                    Text("Save")
                })
                Spacer()
                Button(action: {
                    if let f = saveDoc.ref {
                        let filePath = f()
                        let outputDir = packageModel
                            .packagePath!
                            .appendingPathComponent("output", isDirectory: true)
                        CompilerAPI.compileFile(filePath: filePath, outputDir: outputDir)
                    }
                }, label: {
                    Text("Compile")
                })
                if !showPreview {
                    Button(action: {
                        showPreview = true
                    }, label: {
                        Text("Show Preview")
                    })
                }
                if showPreview {
                    Button(action: {
                        showPreview = false
                    }, label: {
                        Text("Hide Preview")
                    })
                }
            }
//            .padding(12)
        }
        @ViewBuilder var textEditor: some View {
            WrapViewController(
                setup: {
                    let viewCtl = SSTextEditorMasterViewController()
                    viewCtl.packageModel = packageModel
                    viewCtl.onEditorChange = { editorCtl in
                        saveDoc.ref = {
                            editorCtl.saveDocument()
                        }
                    }
                    saveAllDocs.ref = {
                        viewCtl.saveAll()
                    }
                    return viewCtl
                },
                update: {viewCtl, ctx in
                    
                }
            )
        }
    }
}

