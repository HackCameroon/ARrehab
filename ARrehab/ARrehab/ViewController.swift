//
//  ViewController.swift
//  ARrehab
//
//  Created by Eric Wang on 2/12/20.
//  Copyright © 2020 Eric Wang. All rights reserved.
//

import UIKit
import RealityKit
import ARKit
import Combine

class ViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet var arView: ARView!
    
    var hasMapped: Bool!

    let playerEntity = Player(target: .camera)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hasMapped = false
        arView.scene.addAnchor(playerEntity)
        
        let objectDetectionConfig = ARObjectScanningConfiguration()
        objectDetectionConfig.planeDetection = .horizontal
        
        arView.session.delegate = self
        arView.session.run(objectDetectionConfig)
        
        /*let arConfig = ARWorldTrackingConfiguration()
        arConfig.planeDetection = .horizontal
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            arConfig.frameSemantics.insert(.personSegmentationWithDepth)
        } else {
            print("This device does not support People Occlusion with Depth")
        }
                
        arView.session.delegate = self
        arView.session.run(arConfig)*/
        
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        if (hasMapped) {
            return
        }
        var anc: ARAnchor?
        anchors.forEach {anchor in
            guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
            if (planeAnchor.alignment == .horizontal) { // TODO: change to classification == .floor, Get the planeAnchor to make sure that the plane is large enough
                anc = planeAnchor
                self.hasMapped = true
            }
        }
        if (hasMapped) {
            let ancEntity = AnchorEntity(anchor: anc!)
            for x in -1 ... 1 {
                for z in -1 ... 1 {
                    let tile: Tile = Tile(name: String(format: "Tile (%d,%d)", x, z), x: Float(x)/2.0, z: Float(z)/2.0)
                    ancEntity.addChild(tile)
                }
            }
            
            playerEntity.addCollision()
            
            self.arView.scene.addAnchor(ancEntity)
        }
    }
    
    func updateCustomUI(message: String) {
        print(message)
    }
    
}
