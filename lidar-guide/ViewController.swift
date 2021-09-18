//
//  ViewController.swift
//  lidar-guide
//
//  Created by Bruno de Borba on 02/09/21.
//

import RealityKit
import ARKit

class ViewController: UIViewController, ARSessionDelegate {
    @IBOutlet weak var arView: ARView!
    
    var newDepthData:Depth?
    
    var timer = Timer()
    
    var oldDirection = "";
    
    var lastProcessedFrame: ARFrame?
    
    let dispatchQueue = DispatchQueue(label:"con",attributes:.concurrent)
    
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
        
        //configuration.sceneReconstruction = .meshWithClassification
        
        //configuration.environmentTexturing = .automatic
        
        // Add plane detection
        configuration.planeDetection = [.horizontal, .vertical]
        
        /** Adicionado sceneDepth **/
        configuration.frameSemantics = [.sceneDepth]
    
        
        arView.session.run(configuration)
        
        // Configura classe para trabalhar com os valores de profundidade
        newDepthData = Depth(arARSession: arView.session, arConfiguration: configuration)
 
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
        
        /** Acesso ao depth data*/
        //guard let depthData = frame.sceneDepth else { return }
        //guard let smoothedSceneDepth = frame.smoothedSceneDepth else { return }
      
        /*let arData = ARData(depthImage: depthData.depthMap,
                                    confidenceImage: depthData.confidenceMap,
                          depthSmoothImage: smoothedSceneDepth.depthMap,
                          confidenceSmoothImage: smoothedSceneDepth.confidenceMap,
                          colorImage: frame.capturedImage,
                          cameraIntrinsics: frame.camera.intrinsics,
                          cameraResolution: frame.camera.imageResolution,
                          deviceOrientation: UIDevice.current.orientation,
                          screenResolution: UIScreen.main.bounds.size)*/
        //myFeedView.updateFeed(pixelBuffer: arData.depthImage)
        // execute change map setting*/
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
        print(oldDirection)
        if (oldDirection == "left"){
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        } else if (oldDirection == "right"){
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }

}

