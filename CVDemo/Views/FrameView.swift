//
//  FrameView.swift
//  CVDemo
//
//  Created by Andres Vinueza on 7/31/23.
//

import SwiftUI

struct FrameView: View {
    @State private var confidence: Float = 30
    var image: CGImage?
    var overlay: CGImage?
    var updated: (_ value: Float) -> Void
    
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
                    .overlay {
                        if let overlay = overlay {
                            Image(overlay, scale: 1.0, orientation: .up, label: label)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width, height: geometry.size.height, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        VStack {
                            Slider(value: $confidence, in: 30...100) { editing in
                                updated(confidence)
                            }
                            Text("Confidence threshold: \(Int(confidence))%")
                                .font(Font.monospacedDigit(Font.system(size: 18))())
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 24)
                    }
            }
        } else {
            EmptyView()
        }
    }
}

//struct FrameView_Previews: PreviewProvider {
//    static var previews: some View {
//        FrameView(image: nil)
//    }
//}
