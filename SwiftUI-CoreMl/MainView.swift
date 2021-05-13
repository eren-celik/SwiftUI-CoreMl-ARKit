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
            #endif
            fatalError()
        }
    }()
    
    let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
    private var hitTestResultValue : ARRaycastResult!
    private var visionRequests = [VNRequest]()
    
    func makeUIView(context: Context) -> ARView {
        let tapGesture = UITapGestureRecognizer(target: context.coordinator,
                                                action: #selector(Coordinator.tapGestureMethod( _ :)))
        arView.addGestureRecognizer(tapGesture)
        return arView
        
    }
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator : NSObject{
        var parent : ARViewContainer
        
        init( _ parent : ARViewContainer) {
            self.parent = parent
        }
        
        @objc func tapGestureMethod(_ sender : UITapGestureRecognizer){
            let sceneView = sender.view as! ARView
            let touchLocation = parent.arView.center
            
            let result = parent.arView.raycast(from: touchLocation,
                                               allowing: .estimatedPlane,
                                               alignment: .any)
            guard let raycastHitTestResult : ARRaycastResult = result.first else {
                return
            }
            guard let currentFrame = sceneView.session.currentFrame else {
                return
            }
            
            parent.hitTestResultValue = raycastHitTestResult
            let buffer = currentFrame.capturedImage
            visionRequest(buffer)
        }
        
        func createText(_ generatedText : String){
            let mesh = MeshResource.generateText(generatedText,
                                                 extrusionDepth: 0.001,
                                                 font: UIFont(name: "Helvetica Neue", size: 0.05)!,
                                                 containerFrame: CGRect.zero,
                                                 alignment: .center,
                                                 lineBreakMode: .byCharWrapping)
            let material = SimpleMaterial(color: .randomColor, roughness: 1, isMetallic: true)
            let modelEntity = ModelEntity(mesh: mesh, materials: [material])
            let anchorEntity = AnchorEntity(world: SIMD3<Float>(parent.hitTestResultValue.worldTransform.columns.3.x,
                                                                parent.hitTestResultValue.worldTransform.columns.3.y,
                                                                parent.hitTestResultValue.worldTransform.columns.3.z
            ))
            anchorEntity.addChild(modelEntity)
            parent.arView.scene.addAnchor(anchorEntity)
        }
        
        private func visionRequest( _ buffer : CVPixelBuffer) {
            let visionModel = try! VNCoreMLModel(for: parent.resnetModel.model)
            let request = VNCoreMLRequest(model: visionModel) { request, error in
                if error != nil{
                    return
                }
                guard let observations = request.results ,
                      let observation = observations.first as? VNClassificationObservation else {
                    return
                }
                #if DEBUG
                print("Object Name: \(observation.identifier) , \(observation.confidence * 100)")
                #endif
                DispatchQueue.main.async {
                    self.createText("\(String(describing: observation.identifier))\n%\(observation.confidence * 100)")
                }
                
            }
            request.imageCropAndScaleOption = .centerCrop
            parent.visionRequests = [request]
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: buffer,
                                                            orientation: .upMirrored,
                                                            options: [:])
            
            DispatchQueue.global().async {
                try! imageRequestHandler.perform(self.parent.visionRequests)
            }
        }
    }
}


#if DEBUG
struct MainView_Previews : PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
#endif

extension UIColor {
    static var randomColor : UIColor{
        return UIColor(
            red:   .random(),
            green: .random(),
            blue:  .random(),
            alpha: 1.0
        )
    }
}
extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}
