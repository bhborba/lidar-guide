//
//  Depth.swift
//  VisualizingSceneSemantics
//
//  Created by Bruno de Borba on 17/08/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import ARKit
import AudioToolbox
class Depth {
    private let arARSession:ARSession
    private var depthData:ARDepthData?
    init(arARSession:ARSession,arConfiguration:ARConfiguration) {
        self.arARSession=arARSession
        //arConfiguration.frameSemantics = .sceneDepth
        //arARSession.run(arConfiguration)
        depthData=arARSession.currentFrame?.sceneDepth
    }
    //Gain depthUIimage
    func getUIImage() -> UIImage {
        if let depthData=arARSession.currentFrame?.sceneDepth{
            let myCImage = CIImage(cvPixelBuffer: depthData.depthMap)
            return UIImage(ciImage: myCImage)
        }
        return UIImage()
    }
    //Get detailed data
    func getDepthDistance() -> DepthData {
        let depthFloatData = DepthData()
        if let depth = arARSession.currentFrame?.sceneDepth?.depthMap{
            let depthWidth = CVPixelBufferGetWidth(depth)
            let depthHeight = CVPixelBufferGetHeight(depth)
            CVPixelBufferLockBaseAddress(depth, CVPixelBufferLockFlags(rawValue: 0))
            let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(depth), to: UnsafeMutablePointer<Float32>.self)
            var isTooClose = false
            // Esquerda
            for y in 0...depthHeight-1 {
                for x in 0...depthWidth-1 {
                    let distanceAtXYPoint = floatBuffer[y*depthWidth+x]
                    if (!isTooClose && distanceAtXYPoint < 0.5) {
                        depthFloatData.setIsTooClose(value: true)
                        isTooClose = true
                    }
                    depthFloatData.set(x: x, y: y, floatData: distanceAtXYPoint)
                }
            }
            //let isTooClose = depthFloatData.getIsTooClose()
            if (isTooClose){
               // depthFloatData.setIsTooClose(value: true)
                depthFloatData.getClearestDirection()
            }

        }
        return depthFloatData
    }

}
