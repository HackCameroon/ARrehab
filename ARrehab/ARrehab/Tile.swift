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
    
    static let tileSize = SIMD3<Float>(0.5, 0.01, 0.5)
    var tileName: String
    let coords : Coordinates
    
    required init(name: String, x: Float, z: Float) {
        self.tileName = name
        
        self.coords = Coordinates(x: x, z: z)
        
        super.init()
        
        self.components[ModelComponent] = ModelComponent(mesh: MeshResource.generateBox(size: Tile.tileSize, cornerRadius: 0.2), materials: [SimpleMaterial()])
        self.components[CollisionComponent] = CollisionComponent(shapes: [ShapeResource.generateBox(width: 0.5, height: 4.0, depth: 0.5)], mode: .trigger, filter: .sensor)
        
        self.transform.translation = SIMD3(x, 0.0, z)
        print("Generated Tile: " + name)
        
    }
    
    required init() {
        fatalError("Can't instantiate a Tile with no paramaters")
    }
}

extension Tile {
    
    //Data structure for storing and providing access to a Tile's x and z coordinates
    struct Coordinates : Hashable, Equatable {
        var x : Float
        var z : Float
    }
    
}
