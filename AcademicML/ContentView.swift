//
//  ContentView.swift
//  AcademicML
//
//  Created by Colbyn Wadman on 8/10/22.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: AcademicMLDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(AcademicMLDocument()))
    }
}
