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
        configuration.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
        
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
    
    
    /**
     Isso aqui chama sozinho dependendo da assinatura da funcao
     */
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
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
        
        if let newDepthData = newDepthData{
            let data = newDepthData.getDepthDistance()
            let isTooClose = data.getIsTooClose()

            if (isTooClose && !timer.isValid){
                self.scheduledTimerWithTimeInterval()
            } else if (!isTooClose && timer.isValid) {
                timer.invalidate()
            }

            
                /*print("x:128y:96distance\(data.get(x: 128, y: 96))")
                print("x :0y:0)distance\(data.get(x: 0, y: 0))")
                print("x :255y:191distance\(data.get(x: 255, y: 191))")
                print("x:255y:191distance\(data.get(x: 0, y: 191))")
                print("x:254y:191distance\(data.get(x: 254, y: 191))")*/
        }
        
 
    }
    
    /**
            Timer de execucao para vibrar o celular
     */
    func scheduledTimerWithTimeInterval(){
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.vibrate), userInfo: nil, repeats: true)
    }
    
    /**
            Vibra o celular
     */
    @objc func vibrate() {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }

}

