//
//  FrameView.swift
//  CerealDemo
//
//  Created by Andrés Vinueza on 12/14/22.
//

import SwiftUI

struct FrameView: View {
    
    var image: CGImage?
    var cerealResult: CerealResult?
    
    private let label = Text("No match").foregroundColor(.white)
    
    var body: some View {
        if let image = image {
            GeometryReader { geometry in
                Image(image, scale: 1.0, orientation: .up, label: label)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height,
                        alignment: .center)
                    .clipped()
                    .overlay(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Class Label: \(cerealResult?.classificationLabel ?? "N/A")")
                                .bold()
                                .shadow(radius: 4)
                                .multilineTextAlignment(.leading)
                            Text("Confidence Score: \(cerealResult?.classificationScore ?? "N/A")")
                                .bold()
                                .shadow(radius: 4)
                                .multilineTextAlignment(.leading)
                            Text("Processing Time: \(cerealResult?.inferenceTime ?? "N/A")")
                                .bold()
                                .shadow(radius: 4)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(24)
                        .frame(width: geometry.size.width, alignment: .leading)
                        .background(Color.red.edgesIgnoringSafeArea(.bottom))
                        .animation(.easeInOut, value: 0.25)
                    }
            }
        } else {
            EmptyView()
        }
    }
}

struct FrameView_Previews: PreviewProvider {
    static var previews: some View {
        FrameView(image: nil)
    }
}
