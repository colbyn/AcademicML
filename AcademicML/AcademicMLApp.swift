//
//  AcademicMLApp.swift
//  AcademicML
//
//  Created by Colbyn Wadman on 8/10/22.
//

import SwiftUI

@main
struct AcademicMLApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: AcademicMLDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
