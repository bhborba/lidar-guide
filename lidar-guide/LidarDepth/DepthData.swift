//
//  DepthData.swift
//  VisualizingSceneSemantics
//
//  Created by Bruno de Borba on 17/08/21.
//  Copyright © 2021 Apple. All rights reserved.
//
// Importação para cálculos da matriz (média)
import Accelerate

/**
    Classe para trabalhar com dados de profundidade
 */
class DepthData {
    // Dados do array
    private var data = Array(repeating: Array(repeating: Float(-1), count: 192), count: 256)
    // Flag de colisão
    private var isTooClose = false
    // Direção de colisão
    private var tooCloseDirection = ""
    // Tamanho da matriz
    private let matrixSize = Float(96*256)
    
    /**
        Define valores da matriz de profundidade
     */
    func set(x:Int,y:Int,floatData:Float) {
         data[x][y]=floatData
    }
    
    /**
        Busca valores da matriz de profundidade
     */
    func get(x:Int,y:Int) -> Float {
        return data[x][y]
    }
    
    /**
        Retorna toda a matriz de profundidade
     */
    func getAll() -> [[Float]] {
        return data
    }
    
    /**
        Define flag de colisão
     */
    func setIsTooClose(value:Bool){
        isTooClose = value
    }
    
    /**
        Busca valores da flag de colisão
     */
    func getIsTooClose() -> Bool {
        return isTooClose
    }
    
    /**
        Define direção de colisão
     */
    func setTooCloseDirection(value:String){
        tooCloseDirection = value
    }
    
    /**
        Busca direção de colisão
     */
    func getTooCloseDirection() -> String {
        return tooCloseDirection
    }
    
    /**
            Busca direção que está mais próxima
     */
    func getClearestDirection() -> Void {
        // Pega lado direito da matriz
        let matrixRight: [Float] = data.flatMap { $0.dropLast(96) }
        // Efetua cálculo da média
        let matrixRightMedia = (vDSP.sum(matrixRight)/matrixSize)
       
        // Pega lado esquerdo da matriz
        let matrixLeft: [Float] = data.flatMap { $0.dropFirst(96) }
        // Efetua cálculo da média
        let matrixLeftMedia = (vDSP.sum(matrixLeft)/matrixSize)
        
        // Se média da direita for maior do que a da esquerda (tiver distâncias maiores)
        (matrixRightMedia > matrixLeftMedia) ?
            // Define lado mais próximo como esquerda
            setTooCloseDirection(value:"left")
        :
            // Define lado mais próximo como direita
            setTooCloseDirection(value:"right")
    }
    
    /**
        Valida se há algum ponto muito próximo na matriz
     */
    func validateIsTooClose() -> Bool {
        // Dados da matriz
        let matrix: [Float] = data.flatMap { $0 }
        // Busca algum ponto menor do que 0.5 (que esteja colidindo)
        let hasPointTooClose = matrix.filter{point in point < 0.5}
        // Retorna true se valor não estiver vazio (indicando colisão)
        return !hasPointTooClose.isEmpty
    }
    
}
