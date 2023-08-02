//
//  ContentView.swift
//  CVDemo
//
//  Created by Andres Vinueza on 7/31/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var model = ContentViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                FrameView(image: model.frame, overlay: model.overlay) { value in
                    model.updateConfidence(with: value)
                }
                .edgesIgnoringSafeArea(.all)
                
                ErrorView(error: model.error)
            }
            .navigationTitle("CV Demo")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
