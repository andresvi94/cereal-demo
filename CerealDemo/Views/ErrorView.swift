//
//  ErrorView.swift
//  CerealDemo
//
//  Created by Andrés Vinueza on 12/14/22.
//

import SwiftUI

struct ErrorView: View {
    var error: Error?
    var edge: Edge.Set = .top
    
    
    var body: some View {
        VStack {
            Text(error?.localizedDescription ?? "")
                .bold()
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(8)
                .foregroundColor(.white)
                .background(Color.red.edgesIgnoringSafeArea(edge))
                .opacity(error == nil ? 0.0 : 1.0)
                .animation(.easeInOut, value: 0.25)
            
            Spacer()
        }
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView(error: CameraError.cannotAddInput)
    }
}

