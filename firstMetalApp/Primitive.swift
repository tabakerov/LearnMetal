//
//  Primitive.swift
//  firstMetalApp
//
//  Created by Dima on 25/01/2021.
//  Copyright © 2021 Dima. All rights reserved.
//

import MetalKit

class Primitive {
  static func makeCube(device: MTLDevice, size: Float) -> MDLMesh {
    let allocator = MTKMeshBufferAllocator(device: device)
    let mesh = MDLMesh(boxWithExtent: [size, size, size],
                       segments: [1, 1, 1],
                       inwardNormals: false,
                       geometryType: .triangles,
                       allocator: allocator)
    return mesh
  }
}
