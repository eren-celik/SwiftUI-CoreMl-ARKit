//
//  ContentView.swift
//  SwiftUI-CoreMl
//
//  Created by Eren  Çelik on 13.05.2021.
//

import SwiftUI
import RealityKit
import ARKit
import Vision

struct MainView : View {
    var body: some View {
        ARViewContainer()
            .edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    let resnetModel : Resnet50 = {
        do {
            let configuration = MLModelConfiguration()
            return try Resnet50(configuration: configuration)
        } catch {
            #if DEBUG
            print(error)
            fatalError()
            #endif
        }
    }()
    
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
        arView.debugOptions = [.showPhysics , .showWorldOrigin, .showStatistics]
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureMethod))
        arView.addGestureRecognizer(tapGesture)
        
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
}
extension ARViewContainer {
    
    @objc func tapGestureMethod(recognizer : UITapGestureRecognizer){
        
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
#endif
