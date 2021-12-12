//
//  Depth.swift
//  VisualizingSceneSemantics
//
//  Created by Bruno de Borba on 17/08/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import ARKit

/**
    Classe para buscar dados de profundidade
 */
class Depth {
    // AR Session
    private let arARSession:ARSession
    
    // AR Depth Data
    private var depthData:ARDepthData?
    
    // Inicializa configuracoes de AR Session
    init(arARSession:ARSession) {
        self.arARSession=arARSession
    }

    // Busca dados de distancia
    func getDepthDistance() -> DepthData {
        // Cria variável do tipo DepthData (classe)
        let depthFloatData = DepthData()
        
        // Percorre depth map gerado pelo ARKit
        if let depth = arARSession.currentFrame?.sceneDepth?.depthMap{
            // Busca Largura da matriz
            let depthWidth = CVPixelBufferGetWidth(depth)
            // Busca Altura da matriz
            let depthHeight = CVPixelBufferGetHeight(depth)
            
            // Bloqueia o endereço do pixel buffer
            CVPixelBufferLockBaseAddress(depth, CVPixelBufferLockFlags(rawValue: 0))
            
            // Converte o buffer para float
            let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(depth), to: UnsafeMutablePointer<Float32>.self)
            
            // Inicializa flag de colisão
            var isTooClose = false
            
            // Percorre array de profundidade
            for y in 0...depthHeight-1 {
                for x in 0...depthWidth-1 {
                    // Busca distancia do buffer de acordo com tamanho do array
                    let distanceAtXYPoint = floatBuffer[y*depthWidth+x]
                    // Valida se há colisão
                    if (!isTooClose && distanceAtXYPoint < 0.5) {
                        // Define valor de colisao como true
                        depthFloatData.setIsTooClose(value: true)
                        isTooClose = true
                    }
                    // Define distancia na respectiva posição do array
                    depthFloatData.set(x: x, y: y, floatData: distanceAtXYPoint)
                }
            }
        
            // Se há colisão, busca direção para orientar usuário
            if (isTooClose){
                depthFloatData.getClearestDirection()
            }

        }
        // Retorna dados de profundidade
        return depthFloatData
    }

}
