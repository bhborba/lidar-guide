//
//  DepthData.swift
//  VisualizingSceneSemantics
//
//  Created by Bruno de Borba on 17/08/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import Accelerate

class DepthData {
    private var data = Array(repeating: Array(repeating: Float(-1), count: 192), count: 256)
    private var isTooClose = false
    private var tooCloseDirection = ""
    private let matrixSize = Float(96*256)
    func set(x:Int,y:Int,floatData:Float) {
         data[x][y]=floatData
    }
    func get(x:Int,y:Int) -> Float {
        return data[x][y]
    }
    func getAll() -> [[Float]] {
        return data
    }
    
    func setIsTooClose(value:Bool){
        isTooClose = value
    }
    
    func getIsTooClose() -> Bool {
        return isTooClose
    }
    
    func setTooCloseDirection(value:String){
        tooCloseDirection = value
    }
    
    func getTooCloseDirection() -> String {
        return tooCloseDirection
    }
    
    func getClearestDirection() -> Void {
        let matrixLeft: [Float] = data.flatMap { $0.dropLast(96) }
        let matrixLeftMedia = (vDSP.sum(matrixLeft)/matrixSize)
       
        let matrixRight: [Float] = data.flatMap { $0.dropFirst(96) }
        let matrixRightMedia = (vDSP.sum(matrixRight)/matrixSize)
        
        (matrixRightMedia > matrixLeftMedia) ?
            setTooCloseDirection(value:"right")
        :
            setTooCloseDirection(value:"left")
        
    }
    
    func validateIsTooClose() -> Bool {
        let matrix: [Float] = data.flatMap { $0 }
        let hasPointTooClose = matrix.filter{point in point < 0.5}
        return !hasPointTooClose.isEmpty
    }
    
}
