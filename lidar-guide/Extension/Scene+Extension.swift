//
//  Scene+Extension.swift
//  lidar-guide
//
//  Created by Bruno de Borba on 27/09/21.
//

import ARKit
import RealityKit

extension Scene {
    // Add an anchor and remove it from the scene after the specified number of seconds.
/// - Tag: AddAnchorExtension
    func addAnchor(_ anchor: HasAnchoring, text: String, removeAfter seconds: TimeInterval) {
        
        guard let model = anchor.children.first as? HasPhysics else {
            return
        }
        
        // Set up model to participate in physics simulation
        if model.collision == nil {
            model.generateCollisionShapes(recursive: true)
            model.physicsBody = .init()
        }
        // ... but prevent it from being affected by simulation forces for now.
        model.physicsBody? = PhysicsBodyComponent(shapes: [.generateBox(size: .one)],
                                                 mass: 1.0,
                                             material: .default,
                                             mode: .kinematic)
     
        model.name = "Object"
        
        do {  let audioResource = try AudioFileResource.load(named: text + ".mp3",
                                                          in: nil,
                                                   inputMode: .spatial,
                                             loadingStrategy: .preload,
                                                        shouldLoop: true)
            model.playAudio(audioResource)
            
        } catch(let error) {
            print(error)
        }
        
        addAnchor(anchor)
        // Making the physics body dynamic at this time will let the model be affected by forces.
        Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { (timer) in
            model.physicsBody?.mode = .dynamic
        }
        Timer.scheduledTimer(withTimeInterval: seconds + 3, repeats: false) { (timer) in
            self.removeAnchor(anchor)
        }
    }
}
