//
//  DepthData.swift
//  VisualizingSceneSemantics
//
//  Created by Bruno de Borba on 17/08/21.
//  Copyright © 2021 Apple. All rights reserved.
//

class DepthData {
    private var data = Array(repeating: Array(repeating: Float(-1), count: 192), count: 256)
    private var isTooClose = false
    private var tooCloseDirection = ""
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
    
}
