//
//  ARData.swift
//  VisualizingSceneSemantics
//
//  Created by Bruno de Borba on 19/08/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import ARKit

class ARData {
    var depthImage: CVPixelBuffer
    var confidenceImage: CVPixelBuffer?
    var depthSmoothImage: CVPixelBuffer
    var confidenceSmoothImage: CVPixelBuffer?
    var colorImage: CVPixelBuffer
    var cameraIntrinsics: simd_float3x3
    var cameraResolution: CGSize
    var deviceOrientation: UIDeviceOrientation
    var screenResolution: CGSize
    var adjustImageResolution: CGSize

    init(depthImage: CVPixelBuffer,
         confidenceImage: CVPixelBuffer?,
              depthSmoothImage: CVPixelBuffer,
              confidenceSmoothImage: CVPixelBuffer?,
              colorImage: CVPixelBuffer,
              cameraIntrinsics: simd_float3x3,
              cameraResolution: CGSize,
              deviceOrientation: UIDeviceOrientation,
              screenResolution: CGSize) {
        self.depthImage = depthImage
        self.confidenceImage = confidenceImage
        self.depthSmoothImage = depthSmoothImage
        self.confidenceSmoothImage = confidenceSmoothImage
        self.colorImage = colorImage
        self.cameraIntrinsics = cameraIntrinsics
        self.cameraResolution = cameraResolution
        self.deviceOrientation = deviceOrientation
        self.screenResolution = screenResolution
        let imageWidth = CGFloat(CVPixelBufferGetWidth(colorImage))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(colorImage))
        let aspect = imageWidth/imageHeight
        let height = screenResolution.height
        let width = height * aspect
        adjustImageResolution = CGSize(width: width, height: height)
       
        /*
        debugPrint("colorImage resolution", CVPixelBufferGetWidth(colorImage), CVPixelBufferGetHeight(colorImage))
        debugPrint("depthSmoothImage resolution", CVPixelBufferGetWidth(depthSmoothImage), CVPixelBufferGetHeight(depthSmoothImage))
        debugPrint("depthImage resolution", CVPixelBufferGetWidth(depthImage), CVPixelBufferGetHeight(depthImage))
        debugPrint("screen resolution", screenResolution)
        debugPrint("adjust imaage resolution", adjustImageResolution)
        */
    }
}
