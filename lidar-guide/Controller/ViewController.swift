//
//  ViewController.swift
//  lidar-guide
//
//  Created by Bruno de Borba on 02/09/21.
//

import RealityKit
import ARKit
import AVFoundation

class ViewController: UIViewController, ARSessionDelegate {
    @IBOutlet weak var arView: ARView!
    @IBOutlet weak var directionTooClose: UILabel!
    @IBOutlet weak var objectDirection: UILabel!
    @IBOutlet weak var objectDistance: UILabel!
    
    var newDepthData:Depth?
    
    var timer = Timer()
    
    var oldDirection = "";
    
    var lastProcessedFrame: ARFrame?
    
    let dispatchQueue = DispatchQueue(label:"con",attributes:.concurrent)
    
    // the mechanism that ensures a function is called at most once every defined time period
    let throttler = Throttler(minimumDelay: 1, queue: .global(qos: .userInteractive))
    
    var lastLocation: SCNVector3?
    
    var isLoopShouldContinue = true
    
    var objectDetectionService = ObjectDetectionService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arView.session.delegate = self
        
        // Turn on occlusion from the scene reconstruction's mesh.
        arView.environment.sceneUnderstanding.options.insert(.occlusion)
        
        // Turn on physics for the scene reconstruction's mesh.
        arView.environment.sceneUnderstanding.options.insert(.physics)
        
        // Display a debug visualization of the mesh.
        arView.debugOptions.insert(.showSceneUnderstanding)
        
        // For performance, disable render options that are not required for this app.
        arView.renderOptions = [.disablePersonOcclusion, .disableDepthOfField, .disableMotionBlur]
        
        // Manually configure what kind of AR session to run since
        // ARView on its own does not turn on mesh classification.
        arView.automaticallyConfigureSession = false
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.sceneReconstruction = .meshWithClassification
        
        configuration.environmentTexturing = .automatic
        
        
        // Add plane detection
        configuration.planeDetection = [.horizontal, .vertical]
        
        /** Adicionado sceneDepth **/
        configuration.frameSemantics = [.sceneDepth]
    
        
        arView.session.run(configuration)
        
        // Configura classe para trabalhar com os valores de profundidade
        newDepthData = Depth(arARSession: arView.session, arConfiguration: configuration)
        
        // Play audio even with de silent mode on
        do {
              try AVAudioSession.sharedInstance().setCategory(.playback)
           } catch(let error) {
               print(error.localizedDescription)
           }
 
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Prevent the screen from being dimmed to avoid interrupting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    private func shouldProcessFrame(_ frame: ARFrame) -> Bool {
      guard let lastProcessedFrame = lastProcessedFrame else {
        // Always process the first frame
        return true
      }
      return frame.timestamp - lastProcessedFrame.timestamp >= 0.032 // 32ms for 30fps
    }
    
    /**
     Isso aqui chama sozinho dependendo da assinatura da funcao
     */
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        dispatchQueue.async {
            self.updateDepthData(with: frame)
          }
        
        let transform = SCNMatrix4(frame.camera.transform)
        let orientation = SCNVector3(-transform.m31, -transform.m32, transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let currentPositionOfCamera = orientation + location
        
        if let lastLocation = lastLocation {
            let speed = (lastLocation - currentPositionOfCamera).length()
            isLoopShouldContinue = speed < 0.0085
        }
        lastLocation = currentPositionOfCamera
    }
    
    
    func updateDepthData(with frame: ARFrame){
        
        guard shouldProcessFrame(frame) else {
          // Less than 32ms with the previous frame
          return
        }
        
        lastProcessedFrame = frame
    
        if let newDepthData = newDepthData{
            
            let data = newDepthData.getDepthDistance()
            let isTooClose = data.getIsTooClose()
            let direction = data.getTooCloseDirection()
            
            if (direction != oldDirection){
                oldDirection = direction
            }
            

            if (isTooClose && !timer.isValid){
                scheduledTimerWithTimeInterval()
            } else if (!isTooClose && timer.isValid) {
                timer.invalidate()
            }
        }
    }
    
    /**
            Timer de execucao para vibrar o celular
     */
    func scheduledTimerWithTimeInterval(){
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.vibrate), userInfo: nil, repeats: true)
        }
    }
    
    /**
            Vibra o celular
     */
    @objc func vibrate() {
        //print(oldDirection)
        directionTooClose.text = "too close to the " + oldDirection
        if (oldDirection == "left"){
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        } else if (oldDirection == "right"){
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }
    
    
    func loopObjectDetection() {
        throttler.throttle { [weak self] in
            guard let self = self else { return }
            if self.isLoopShouldContinue {
                
                self.performDetection()
            }
            self.loopObjectDetection()
        }
    }
    
    func performDetection() {
        guard let pixelBuffer = arView.session.currentFrame?.capturedImage else { return }
        
        objectDetectionService.detect(on: .init(pixelBuffer: pixelBuffer)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                let rectOfInterest = VNImageRectForNormalizedRect(
                    response.boundingBox,
                    Int(self.arView.bounds.width),
                    Int(self.arView.bounds.height))
                self.addAnnotation(rectOfInterest: rectOfInterest,
                                   text: response.classification)
            
            case .failure(let error):
                print(error)
                break
            }
        }
    }
    
    func addAnnotation(rectOfInterest rect: CGRect, text: String) {
        let point = CGPoint(x: rect.midX, y: rect.midY)
        
        /*
         Text to speech
         */
        var utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        let synthesizer = AVSpeechSynthesizer()
        
        // Find for an already placed objetc
        let alreadyFoundObject = arView.scene.findEntity(named: text)
    
        let pointX = CGFloat(point.x)
        // The middle of the screen
        let middleX = arView.bounds.width/2
        
        
        if let result = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .any).first {
            
            // 3. Try to get a classification near the tap location.
            //    Classifications are available per face (in the geometric sense, not human faces).
            nearbyFaceWithClassification(to: result.worldTransform.position) { (centerOfFace, classification, anchorDistance) in
                // TODO: Get the distance value
                //let anchorDistanceString = String(format: "%.2f", anchorDistance)
                var objectDirectionString = ""
                
                // Get object position (left/right)
                if(pointX > middleX){
                    utterance = AVSpeechUtterance(string: text + " to the right")
                    objectDirectionString = text + " to the right"
                    
                } else {
                    objectDirectionString = text + " to the left"
                    utterance = AVSpeechUtterance(string: text + " to the left")
                }
                
                DispatchQueue.main.async {
                    self.objectDistance.text = text + " distance: " + String(format: "%.2f", anchorDistance)
                    self.objectDirection.text = objectDirectionString
                }
                
                // If object is already identified, just skips
                if (alreadyFoundObject != nil){
                    //synthesizer.speak(utterance)
                    return
                }
                
                DispatchQueue.main.async {
                    // 4. Compute a position for the text which is near the result location, but offset 10 cm
                    // towards the camera (along the ray) to minimize unintentional occlusions of the text by the mesh.
                    let rayDirection = normalize(result.worldTransform.position - self.arView.cameraTransform.translation)
                    let textPositionInWorldCoordinates = result.worldTransform.position - (rayDirection * 0.1)
                    
                    // 5. Create a 3D text to visualize the classification result.
                    let textEntity = self.model(text: text)

                    // 6. Scale the text depending on the distance, such that it always appears with
                    //    the same size on screen.
                    let raycastDistance = distance(result.worldTransform.position, self.arView.cameraTransform.translation)
                    textEntity.scale = .one * raycastDistance

                    // 7. Place the text, facing the camera.
                    var resultWithCameraOrientation = self.arView.cameraTransform
                    resultWithCameraOrientation.translation = textPositionInWorldCoordinates
                    let textAnchor = AnchorEntity(world: resultWithCameraOrientation.matrix)
                    textAnchor.addChild(textEntity)
                    textAnchor.name = "TEXT NAME"
                    self.arView.scene.addAnchor(textAnchor, text: text, removeAfter: 10)
                    
                    //synthesizer.speak(utterance)
                   
                    // 8. Visualize the center of the face (if any was found) for three seconds.
                    //    It is possible that this is nil, e.g. if there was no face close enough to the tap location.
                    if let centerOfFace = centerOfFace {
                        let faceAnchor = AnchorEntity(world: centerOfFace)
                        faceAnchor.name = text
                        faceAnchor.addChild(self.sphere(radius: 0.01, color: .blue))
                        self.arView.scene.addAnchor(faceAnchor, text: text, removeAfter: 10)
                    }
                }
            }
        
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        guard let frame = session.currentFrame else { return }
        onSessionUpdate(for: frame, trackingState: camera.trackingState)
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        onSessionUpdate(for: frame, trackingState: frame.camera.trackingState)
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        onSessionUpdate(for: frame, trackingState: frame.camera.trackingState)
    }
    
    private func onSessionUpdate(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        isLoopShouldContinue = false
        
        // Update the UI to provide feedback on the state of the AR experience.
                let message: String

                switch trackingState {
                case .normal where frame.anchors.isEmpty:
                    // No planes detected; provide instructions for this app's AR interactions.
                    message = "Move the device around to detect horizontal and vertical surfaces."

                case .notAvailable:
                    message = "Tracking unavailable."

                case .limited(.excessiveMotion):
                    message = "Tracking limited - Move the device more slowly."

                case .limited(.insufficientFeatures):
                    message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."

                case .limited(.initializing):
                    message = "Initializing AR session."

                default:
                    // No feedback needed when tracking is normal and planes are visible.
                    // (Nor when in unreachable limited-tracking states.)
                    message = ""
                    isLoopShouldContinue = true
                    loopObjectDetection()
                }
    }
    
    func sphere(radius: Float, color: UIColor) -> ModelEntity {
        let sphere = ModelEntity(mesh: .generateSphere(radius: radius), materials: [SimpleMaterial(color: color, isMetallic: false)])
        // Move sphere up by half its diameter so that it does not intersect with the mesh
        sphere.position.y = radius
        return sphere
    }
    
    func nearbyFaceWithClassification(to location: SIMD3<Float>, completionBlock: @escaping (SIMD3<Float>?, ARMeshClassification,Float) -> Void) {
        guard let frame = arView.session.currentFrame else {
            completionBlock(nil, .none,0)
            return
        }
    
        var meshAnchors = frame.anchors.compactMap({ $0 as? ARMeshAnchor })
        
        // Sort the mesh anchors by distance to the given location and filter out
        // any anchors that are too far away (4 meters is a safe upper limit).
        let cutoffDistance: Float = 4.0
        meshAnchors.removeAll { distance($0.transform.position, location) > cutoffDistance }
        meshAnchors.sort { distance($0.transform.position, location) < distance($1.transform.position, location) }

        // Perform the search asynchronously in order not to stall rendering.
        DispatchQueue.global().async {
            for anchor in meshAnchors {
                for index in 0..<anchor.geometry.faces.count {
                    // Get the center of the face so that we can compare it to the given location.
                    let geometricCenterOfFace = anchor.geometry.centerOf(faceWithIndex: index)
                    
                    // Convert the face's center to world coordinates.
                    var centerLocalTransform = matrix_identity_float4x4
                    centerLocalTransform.columns.3 = SIMD4<Float>(geometricCenterOfFace.0, geometricCenterOfFace.1, geometricCenterOfFace.2, 1)
                    let centerWorldPosition = (anchor.transform * centerLocalTransform).position
                     
                    // We're interested in a classification that is sufficiently close to the given location––within 5 cm.
                    let distanceToFace = distance(centerWorldPosition, location)
                    if distanceToFace <= 0.05 {
                        // Get the semantic classification of the face and finish the search.
                        let classification: ARMeshClassification = anchor.geometry.classificationOf(faceWithIndex: index)
                        let anchorDistance = distance(anchor.transform.position, self.arView.session.currentFrame!.camera.transform.position)
                        completionBlock(centerWorldPosition, classification,anchorDistance)
                        return
                    }
                }
            }
            
            // Let the completion block know that no result was found.
            completionBlock(nil, .none,0)
        }
    }
    
    func model(text: String) -> ModelEntity {

        // Generate 3D text for the classification
        let lineHeight: CGFloat = 0.05
        let font = MeshResource.Font.systemFont(ofSize: lineHeight)
        let textMesh = MeshResource.generateText(text, extrusionDepth: Float(lineHeight * 0.1), font: font)
        let textMaterial = SimpleMaterial(color: .blue, isMetallic: true)
        let model = ModelEntity(mesh: textMesh, materials: [textMaterial])
        // Move text geometry to the left so that its local origin is in the center
        model.position.x -= model.visualBounds(relativeTo: nil).extents.x / 2
        // Add model to cache
        //modelsForClassification[classification] = model
        return model
    }
}

