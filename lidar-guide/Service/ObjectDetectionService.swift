//
//  ObjectDetectionService.swift
//  lidar-guide
//
//  Created by Bruno de Borba on 19/09/21.
//

import UIKit
import Vision
import SceneKit

class ObjectDetectionService {
    // Inicializa o modelo
    var mlModel = try! VNCoreMLModel(for: YOLOv3Int8LUT().model)
    
    // Requisição de analise da imagem
    lazy var coreMLRequest: VNCoreMLRequest = {
        return VNCoreMLRequest(model: mlModel,
                               completionHandler: self.coreMlRequestHandler)
    }()
    
    private var completion: ((Result<Response, Error>) -> Void)?
    
    // Executa requisições do Vision Framework
    func detect(on request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        self.completion = completion
        
        // Busca orientação do dispositivo
        let orientation = CGImagePropertyOrientation(rawValue:  UIDevice.current.exifOrientation) ?? .up
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: request.pixelBuffer,
                                                        orientation: orientation)
        
        do {
            try imageRequestHandler.perform([coreMLRequest])
        } catch {
            self.complete(.failure(error))
            return
        }
    }
}

private extension ObjectDetectionService {
    func coreMlRequestHandler(_ request: VNRequest?, error: Error?) {
        // Valida se houve erro
        if let error = error {
            complete(.failure(error))
            return
        }
        
        // Mapeia resultados da detecção
        guard let request = request, let results = request.results as? [VNRecognizedObjectObservation] else {
            complete(.failure(RecognitionError.resultIsEmpty))
            return
        }
        
        // Filtra array de resultados deixando apenas os que tiveram maior confiança
        guard let result = results.first(where: { $0.confidence > 0.8 }),
            let classification = result.labels.first else {
                complete(.failure(RecognitionError.lowConfidence))
                return
        }
        
        // Envia o resultado para completar a requisição
        let response = Response(boundingBox: result.boundingBox,
                                classification: classification.identifier)
        
        complete(.success(response))
    }
    
    
    func complete(_ result: Result<Response, Error>) {
        DispatchQueue.main.async {
            self.completion?(result)
            self.completion = nil
        }
    }
}

enum RecognitionError: Error {
    case unableToInitializeCoreMLModel
    case resultIsEmpty
    case lowConfidence
}

extension ObjectDetectionService {
    struct Request {
        let pixelBuffer: CVPixelBuffer
    }
    
    struct Response {
        let boundingBox: CGRect
        let classification: String
    }
}
