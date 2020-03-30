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
    var visualizedPlanes = [ARAnchor]()

    let playerEntity = Player(target: .camera)
    
    var boardAnchorID: UUID = UUID()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        hasMapped = false
        arView.scene.addAnchor(playerEntity)
        
        let arConfig = ARWorldTrackingConfiguration()
        arConfig.planeDetection = .horizontal
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            arConfig.frameSemantics.insert(.personSegmentationWithDepth)
        } else {
            print("This device does not support People Occlusion with Depth")
        }
                
        arView.session.delegate = self
        arView.session.run(arConfig)
        
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        
        //visualizePlanes(anchors: anchors)
        
        /*if (hasMapped) {
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
        }*/
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        
        /*let visualizedPlanes = anchors.filter() {anc in self.visualizedPlanes.contains(anc)}
        updatePlaneVisual(anchors: visualizedPlanes)
        
        let nonVisualizedPlanes = anchors.filter() {anc in
            !self.visualizedPlanes.contains(anc)}
        visualizePlanes(anchors: nonVisualizedPlanes, floor: true)*/
        
        for anc in anchors {
            
            guard !hasMapped else {break}
            guard let planeAnchor = anc as? ARPlaneAnchor else {return}
            
            if isValidSurface(plane: planeAnchor) {
                let planeAnchorEntity = AnchorEntity(anchor: planeAnchor)
                
                generateBoard(planeAnchor: planeAnchor, anchorEntity: planeAnchorEntity)
                
                self.arView.scene.addAnchor(planeAnchorEntity)
                hasMapped = true
                boardAnchorID = planeAnchor.identifier
            }
        }
        
    }
    
    func visualizePlanes(anchors: [ARAnchor]) {
        for anc in anchors {
            
            guard let planeAnchor = anc as? ARPlaneAnchor else {return}
            let planeAnchorEntity = AnchorEntity(anchor: planeAnchor)
                        
            for point in planeAnchor.geometry.boundaryVertices {
                let pointEntity = ModelEntity.init(mesh: MeshResource.generatePlane(width: 0.01, depth: 0.01))
                pointEntity.transform = Transform(translation: point)
                planeAnchorEntity.addChild(pointEntity)
            }
            
            let planeModel = ModelEntity()
            planeModel.model = ModelComponent(mesh: MeshResource.generatePlane(width: planeAnchor.extent.x, depth: planeAnchor.extent.z), materials: [SimpleMaterial(color: SimpleMaterial.Color.blue.withAlphaComponent(CGFloat(0.1)), isMetallic: true)])
            planeModel.transform = Transform(pitch: 0, yaw: 0, roll: 0)
            
            planeAnchorEntity.addChild(planeModel)
            
            planeAnchorEntity.name = planeAnchor.identifier.uuidString
            
            arView.scene.addAnchor(planeAnchorEntity)
            self.visualizedPlanes.append(planeAnchor)
        }
    }
    
    func visualizePlanes(anchors: [ARAnchor], floor: Bool) {
        let validAnchors = anchors.filter() {anc in
            guard let planeAnchor = anc as? ARPlaneAnchor else {return false}
            return isValidSurface(plane: planeAnchor) == floor
        }
        
        visualizePlanes(anchors: validAnchors)
    }
    
    func updatePlaneVisual(anchors: [ARAnchor]) {
        for anc in anchors {
            
            guard let planeAnchor = anc as? ARPlaneAnchor else {return}
            
            guard let planeAnchorEntity = self.arView.scene.findEntity(named: planeAnchor.identifier.uuidString) else {return}
            
            var newBoundaries = [ModelEntity]()
            
            for point in planeAnchor.geometry.boundaryVertices {
                let pointEntity = ModelEntity.init(mesh: MeshResource.generatePlane(width: 0.01, depth: 0.01))
                pointEntity.transform = Transform(translation: point)
                newBoundaries.append(pointEntity)
            }
            
            planeAnchorEntity.children.replaceAll(newBoundaries)
            
            let modelEntity = ModelEntity(mesh: MeshResource.generatePlane(width: planeAnchor.extent.x, depth: planeAnchor.extent.z), materials: [SimpleMaterial(color: SimpleMaterial.Color.blue.withAlphaComponent(CGFloat(0.1)), isMetallic: true)])
            
            planeAnchorEntity.addChild(modelEntity)
        }
    }
    
    func isValidSurface(plane: ARPlaneAnchor) -> Bool {
        guard plane.alignment == .horizontal else {return false}
        let boundaryOne = plane.extent.x
        let boundaryTwo = plane.extent.z
        return min(boundaryOne, boundaryTwo) >= 1 && max(boundaryOne, boundaryTwo) >= 2
    }
    
    func updateCustomUI(message: String) {
        print(message)
    }
    
    
    func generateBoard(planeAnchor: ARPlaneAnchor, anchorEntity: AnchorEntity) {
        
        guard isValidSurface(plane: planeAnchor) else {return}
        
        let xExtent = planeAnchor.extent.x
        let zExtent = planeAnchor.extent.z
        
        var currentX = xExtent
        var currentZ = zExtent
        
        while currentX > 0 {
            while currentZ > 0 {
                let newTile = Tile(name: String(format: "Tile (%f,%f)", currentX, currentZ), x: (currentX/2) - (Tile().tileSize.x/2), z: (currentZ/2) - (Tile().tileSize.z/2))
                anchorEntity.addChild(newTile)
                currentZ -= Tile().tileSize.z
            }
            currentZ = zExtent
            currentX -= Tile().tileSize.x
        }
        
    }
    
    //Will require a board object
    func updateBoard(planeAnchor: ARPlaneAnchor, anchorEntity: AnchorEntity) {
        
    }
    
}
