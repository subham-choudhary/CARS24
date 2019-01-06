//
//  Utility.swift
//  CARS24
//
//  Created by Choudhary, Subham on 05/01/19.
//  Copyright © 2019 Choudhary, Subham. All rights reserved.
//

import Foundation
import UIKit
import ARKit
class Utility {
    
    func createNewBubbleParentNode(_ text : String, shouldAddLine: Bool, color: UIColor, fontSize: CGFloat ) -> SCNNode {
        
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        let bubbleDepth : Float = 0.01
        
        // BUBBLE-TEXT
        let bubble = SCNText(string: text, extrusionDepth: CGFloat(bubbleDepth))
        var font = UIFont(name: "Futura", size: fontSize)
        font = font?.withTraits(traits: .traitBold)
        bubble.font = font
        bubble.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        bubble.firstMaterial?.diffuse.contents = color
        bubble.firstMaterial?.specular.contents = UIColor.black
        bubble.firstMaterial?.isDoubleSided = true
        bubble.chamferRadius = CGFloat(bubbleDepth)
        
        // BUBBLE NODE
        let (minBound, maxBound) = bubble.boundingBox
        let bubbleNode = SCNNode(geometry: bubble)
        bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, bubbleDepth/2)
        bubbleNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        
        // CENTRE POINT NODE
        let sphere = SCNSphere(radius: 0.01)
        sphere.firstMaterial?.diffuse.contents = UIColor.black
        let sphereNode = SCNNode(geometry: sphere)
        
        //Line
        let line = SCNCylinder(radius: 0.02, height: 0.4)
        line.firstMaterial?.diffuse.contents = UIColor.gray
        let lineNode = SCNNode(geometry: line)
        
        // BUBBLE PARENT NODE
        let bubbleNodeParent = SCNNode()
        if shouldAddLine {
            bubbleNodeParent.addChildNode(lineNode)
            lineNode.position.y = bubbleNode.position.y + 0.2
            bubbleNodeParent.addChildNode(sphereNode)
        }
        bubbleNodeParent.addChildNode(bubbleNode)
        bubbleNodeParent.constraints = [billboardConstraint]
        
        bubbleNode.position.y = bubbleNode.position.y
        return bubbleNodeParent
    }
}


