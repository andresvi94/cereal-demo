//
//  ContentView.swift
//  CerealDemo
//
//  Created by Andrés Vinueza on 12/14/22.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var model = ContentViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                FrameView(image: model.frame, cerealResult: model.cerealResult)
                    .edgesIgnoringSafeArea(.all)
                
                ErrorView(error: model.error)
            }
            .navigationTitle("CerealDemo")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
