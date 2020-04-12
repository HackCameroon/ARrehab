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
    
    var visualizedPlanes = [ARAnchor]()
    
    var hasMapped: Bool!
    
    let playerEntity = Player(target: .camera)
    var gameBoard: GameBoard = nil
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        hasMapped = false
        arView.scene.addAnchor(playerEntity)
        
        let arConfig = ARWorldTrackingConfiguration()
        arConfig.planeDetection = .horizontal
        
        //Checks if the device supports people occlusion
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            arConfig.frameSemantics.insert(.personSegmentationWithDepth)
        } else {
            print("This device does not support people occlusion")
        }
                
        arView.session.delegate = self
        arView.session.run(arConfig)
        
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        
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
            
            if isValidSurface(plane: planeAnchor, extent1: 1, extent2: 2) {
                visualizePlanes(anchors: [planeAnchor])
                generateBoard(planeAnchor: planeAnchor)
                hasMapped = true
            }
        }
        
    }
    
    /*
     Returns true if a given plane's extents match the given requirements
     Does not differentiate between x and z
     */
    func isValidSurface(plane: ARPlaneAnchor, extent1: Float, extent2: Float) -> Bool {
        guard plane.alignment == .horizontal else {return false}
        guard min(plane.extent.x, plane.extent.z) >= min(extent1, extent2) else {return false}
        guard max(plane.extent.x, plane.extent.z) >= max(extent1, extent2) else {return false}
        return true;
    }
    
    /*
     Takes a valid horizontal plane and generates a GameBoard object containing Tiles that fit within the plane at the time of function call
     Assigns the GameBoard object to the class var gameboard
     Adds the GameBoard's board anchor to the scene
     */
    func generateBoard(planeAnchor: ARPlaneAnchor) {
        
        guard isValidSurface(plane: planeAnchor, extent1: 1, extent2: 2) else {return}
        
        let xExtent = planeAnchor.extent.x
        let zExtent = planeAnchor.extent.z
        
        let xSize = Tile.tileSize.x
        let zSize = Tile.tileSize.z
        
        var currentX = xExtent/2
        var currentZ = zExtent/2
        
        var listOfTiles : [Tile] = []
        
        //Note: The adjustment present in the tile translation ensures that an appropriate vertex of the tile is at the given coordinates, rather than the center (so the tiles do not overextend the plane)
        while abs(currentX) <= xExtent/2 - xSize/2 {
            while abs(currentZ) <= zExtent/2 - zSize/2 {
                let newTile = Tile(name: String(format: "Tile (%f,%f)", currentX, currentZ), x: currentX - xSize/2, z: currentZ - zSize/2)
                listOfTiles.append(newTile)
                currentZ -= zSize
            }
            currentZ = zExtent/2
            currentX -= xSize
        }
        
        self.gameBoard = GameBoard(tiles: listOfTiles, surfaceAnchor: planeAnchor)
        self.arView.scene.addAnchor(self.gameBoard.board)
    }
    
}

extension ViewController {
    //Plane visualization methods, for use in development
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
            return isValidSurface(plane: planeAnchor, extent1: 1, extent2: 2) == floor
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
}
