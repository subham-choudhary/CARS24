//
//  ARViewController.swift
//  CARS24
//
//  Created by Choudhary, Subham on 05/01/19.
//  Copyright © 2019 Choudhary, Subham. All rights reserved.
//

import UIKit
import ARKit

class ARViewController: UIViewController {
    
    //MARK: OUTLETS
    @IBOutlet weak var scnView: ARSCNView!
    
    //MARK: VARS AND LETS
    var pointerNode = SCNNode()
    var carNode: SCNNode?
    var cameraYAxis: Float = 0
    var shouldAddPointerNode = true
    var currentAngleY: Float = 0.0
    var baseNode: SCNNode?
    var baseScale = SCNVector3(1, 1, 1)
    //Car Colors
    let carColors = [UIColor.red,UIColor.blue,UIColor.black, UIColor.brown]
    var colorIndex = 1
    let labelColors = [UIColor.cyan,UIColor.green, UIColor.purple, UIColor.yellow, UIColor.blue]
    var labelIndex = 0
    
    var session: ARSession {
        return scnView.session
    }
    var screenCenter: CGPoint {
        let bounds = scnView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    //MARK: VIEW LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAR()
        setupPointerNode()
    }
    
    // MARK: BUTTON ACTIONS
    @IBAction func nextCar(_ sender: Any) {
        clearBaseNode()
        let truePos = carNode?.position
        carNode?.runAction(SCNAction.fadeOut(duration: 0.3), completionHandler: {
            var appearPos = self.carNode?.position
            appearPos?.y += 0.5
            self.carNode?.position = appearPos!
            
            for i in self.carNode!.childNodes {
                if let mats = i.geometry?.materials {
                    for j in mats {
                        if (j.name?.contains("body"))! {
                            j.emission.contents = self.carColors[self.colorIndex]
                        }
                    }
                }
            }
            if self.colorIndex == self.carColors.count-1 {
                self.colorIndex = 0
            } else {
                self.colorIndex += 1
            }
            
            self.carNode?.runAction(SCNAction.fadeIn(duration: 0.001))
            self.carNode!.runAction(SCNAction.move(to: truePos!, duration: 0.2))
        })
    }
    
    @IBAction func Details(_ sender: Any) {
        clearBaseNode()
        carNode?.runAction(SCNAction.fadeOut(duration: 0.001), completionHandler: {
            self.addBase()
            self.addLabels()
        })
    }
    @IBAction func showAction(_ sender: Any) {
        clearBaseNode()
        if let _ = carNode {
            carNode?.runAction(SCNAction.fadeIn(duration: 0.001))
            currentAngleY = (cameraYAxis + .pi/2)
            let action = SCNAction.move(to: pointerNode.position, duration: 0.5)
            let actionRot = SCNAction.rotateTo(x: 0, y: (CGFloat(cameraYAxis + .pi/2)), z: 0, duration: 0.5)
            carNode!.runAction(action)
            carNode!.runAction(actionRot)
        } else {
            setupCarNode()
        }
    }
    
    // MARK: CUSTOM FUNCTIONS
    func setupAR() {
        self.scnView.autoenablesDefaultLighting = true
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        self.scnView.session.delegate = self
        self.scnView.session.run(configuration)
    }
    
    func setupPointerNode() {
        pointerNode = SCNNode(geometry: SCNPlane(width: 0.4, height: 0.4))
        pointerNode.geometry?.firstMaterial?.diffuse.contents = UIImage.init(imageLiteralResourceName: "pointer4")
        pointerNode.eulerAngles = SCNVector3Make(0,.pi/2,.pi/2)
    }
    
    func resetPointerNode() {
        DispatchQueue.main.async {
            if let hitTestResult = self.scnView.hitTest(self.screenCenter, types: [.existingPlane,.estimatedHorizontalPlane]).first {
                let transform = hitTestResult.worldTransform
                let thirdColumn = transform.columns.3
                self.pointerNode.position = SCNVector3Make(thirdColumn.x, thirdColumn.y, thirdColumn.z)
                if self.shouldAddPointerNode {
                    self.scnView.scene.rootNode.addChildNode(self.pointerNode)
                    self.shouldAddPointerNode = false
                    self.cameraYAxis = (self.scnView.session.currentFrame?.camera.eulerAngles.y)!
                }
            }
        }
    }
    
    func setupCarNode() {
        let scene = SCNScene(named: "art.scnassets/audi.scn")
        if let scnnode = scene?.rootNode.childNode(withName: "audi", recursively: true) {
            addGestureRecognizer()
            carNode = scnnode
            carNode!.scale = SCNVector3(0.02, 0.02, 0.02)
            let (a,b) = (carNode?.boundingBox)!
            carNode!.pivot = SCNMatrix4MakeTranslation(0, Float((a.y-b.y)/2), 0)
            carNode!.position = pointerNode.position
            scnView.scene.rootNode.addChildNode(carNode!)
        }
    }
    func clearBaseNode() {
        baseNode?.enumerateChildNodes({ (node, _) in
            node.removeFromParentNode()
        })
        baseNode?.removeFromParentNode()
    }
    func addBase() {
        let base = SCNBox(width: 0.4, height: 0.05, length: 0.1, chamferRadius: 0.02)
        base.firstMaterial?.diffuse.contents = UIColor.black
        base.firstMaterial?.specular.contents = UIColor.white
        self.baseNode = SCNNode(geometry: base)
        self.scnView.scene.rootNode.addChildNode(self.baseNode!)
        self.baseNode!.position = self.pointerNode.position
        self.carNode?.position = self.pointerNode.position
        self.baseNode?.scale = baseScale
        self.baseNode!.eulerAngles = SCNVector3Make(0,(self.cameraYAxis),0)

    }
    func addLabels() {
        
        let v = createBars(text: "Health")
        let w = createBars(text: "KMs")
        let x = createBars(text: "Scratch")
        let y = createBars(text: "Milage")
        let z = createBars(text: "Engine")
        let (head,tag) = createLabels()
        
        v.0.position.x += 0.16
        w.0.position.x += 0.08
        y.0.position.x -= 0.08
        z.0.position.x -= 0.16
        
        let v_h:CGFloat = 0.25
        let w_h:CGFloat = 0.1
        let x_h:CGFloat = 0.15
        let y_h:CGFloat = 0.3
        let z_h:CGFloat = 0.2
        
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1
        
        (v.0.geometry as! SCNCylinder).height = v_h
        (w.0.geometry as! SCNCylinder).height = w_h
        (x.0.geometry as! SCNCylinder).height = x_h
        (y.0.geometry as! SCNCylinder).height = y_h
        (z.0.geometry as! SCNCylinder).height = z_h
        
        v.0.pivot = SCNMatrix4MakeTranslation(0, Float(-(v_h/2)), 0)
        w.0.pivot = SCNMatrix4MakeTranslation(0, Float(-(w_h/2)), 0)
        x.0.pivot = SCNMatrix4MakeTranslation(0, Float(-(x_h/2)), 0)
        y.0.pivot = SCNMatrix4MakeTranslation(0, Float(-(y_h/2)), 0)
        z.0.pivot = SCNMatrix4MakeTranslation(0, Float(-(z_h/2)), 0)
        
        v.1.position.y = Float(v_h/2 + 0.03)
        w.1.position.y = Float(w_h/2 + 0.03)
        x.1.position.y = Float(x_h/2 + 0.03)
        y.1.position.y = Float(y_h/2 + 0.03)
        z.1.position.y = Float(z_h/2 + 0.03)
        
        head.position.y += 0.5
        tag.position.y += 0.4
        SCNTransaction.commit()
    }
    func createLabels() -> (SCNNode,SCNNode){
        let carName = Utility().createNewBubbleParentNode("Audi SportBack", shouldAddLine: false, color: UIColor.red, fontSize:0.30)
        let price = Utility().createNewBubbleParentNode("Price: Rs 34,54,400", shouldAddLine: false, color: UIColor.brown, fontSize:0.20)
        self.baseNode!.addChildNode(carName)
        self.baseNode!.addChildNode(price)
        return (carName,price)
    }
    func createBars(text: String) -> (SCNNode,SCNNode) {
        let bar = SCNCylinder(radius: 0.02, height: 0)
        bar.firstMaterial?.diffuse.contents = labelColors[labelIndex]
        bar.firstMaterial?.specular.contents = UIColor.black
        
        let label = Utility().createNewBubbleParentNode(text, shouldAddLine: false, color: UIColor.white, fontSize:0.15)
        let barNode = SCNNode(geometry: bar)
        barNode.addChildNode(label)
        self.baseNode!.addChildNode(barNode)
        labelIndex += 1
        if labelIndex > labelColors.count-1 {
            labelIndex = 0
        }
        return (barNode,label)
    }
    
    func addGestureRecognizer() {
        let rotateGesture = UIPanGestureRecognizer(target: self, action: #selector(rotateNode(_:)))
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(scaleNode(_:)))
        self.scnView.addGestureRecognizer(rotateGesture)
        self.scnView.addGestureRecognizer(pinchGesture)
    }
    
    @objc func rotateNode(_ gesture: UIPanGestureRecognizer) {
        
        guard let _ = carNode else { return }
        
        let translation = gesture.translation(in: gesture.view)
        var newAngleY = (Float)(translation.x)*(.pi)/180.0
        
        newAngleY += currentAngleY
        carNode!.eulerAngles.y = newAngleY
        
        if gesture.state == .ended{
            currentAngleY = newAngleY
        }
        
    }
    @objc func scaleNode(_ gesture: UIPinchGestureRecognizer) {
        guard let _ = carNode else { return }
        if gesture.state == .changed {
            
            let pinchScaleX: CGFloat = gesture.scale * CGFloat((carNode!.scale.x))
            let pinchScaleY: CGFloat = gesture.scale * CGFloat((carNode!.scale.y))
            let pinchScaleZ: CGFloat = gesture.scale * CGFloat((carNode!.scale.z))
            carNode!.scale = SCNVector3Make(Float(pinchScaleX), Float(pinchScaleY), Float(pinchScaleZ))
            let (a,b) = (carNode?.boundingBox)!
            carNode!.pivot = SCNMatrix4MakeTranslation(0, Float((a.y-b.y)/2), 0)
            if let _ = baseNode {
                let pinchScaleX2: CGFloat = gesture.scale * CGFloat((baseNode!.scale.x))
                let pinchScaleY2: CGFloat = gesture.scale * CGFloat((baseNode!.scale.y))
                let pinchScaleZ2: CGFloat = gesture.scale * CGFloat((baseNode!.scale.z))
                baseNode!.scale = SCNVector3Make(Float(pinchScaleX2), Float(pinchScaleY2), Float(pinchScaleZ2))
                baseScale = baseNode!.scale
            }
            gesture.scale = 1
        }
    }
    
}

extension ARViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        resetPointerNode()
    }
}

extension ARViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        cameraYAxis = frame.camera.eulerAngles.y
    }
}

extension UIFont {
    func withTraits(traits:UIFontDescriptor.SymbolicTraits...) -> UIFont {
        let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits))
        return UIFont(descriptor: descriptor!, size: 0)
    }
}
