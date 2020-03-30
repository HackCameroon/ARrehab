//
//  Tile.swift
//  ARrehab
//
//  Created by Sanath Sengupta on 2/23/20.
//  Copyright © 2020 Eric Wang. All rights reserved.
//

import Foundation
import RealityKit
import CoreGraphics

class Tile : Entity, HasModel, HasCollision {
    
    var tileSize = SIMD3<Float>(0.5, 0.01, 0.5)
    
    var tileName: String
    
    required init(name: String, x: Float, z: Float) {
        
        self.tileName = name
        super.init()
        self.components[ModelComponent] = ModelComponent(mesh: MeshResource.generateBox(size: tileSize, cornerRadius: 0.2), materials: [SimpleMaterial()])
        self.components[CollisionComponent] = CollisionComponent(shapes: [ShapeResource.generateBox(width: 0.5, height: 4.0, depth: 0.5)], mode: .trigger, filter: .sensor)
        self.transform.translation = SIMD3<Float>(x,0.0,z)
        print("Generated Tile: " + name)
        
    }
    
    required init() {
        self.tileName = ""
        super.init()
    }
}
