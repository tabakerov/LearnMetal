//
//  Renderer.swift
//  firstMetalApp
//
//  Created by Dima on 25/01/2021.
//  Copyright © 2021 Dima. All rights reserved.
//

import MetalKit

class Renderer: NSObject {
    
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!

    let vertexData: [Float]
    let vertexBuffer: MTLBuffer
    let renderState: MTLRenderPipelineState
    let computeState: MTLComputePipelineState
    var generationA: MTLTexture
    var generationB: MTLTexture
    var cellsWide = 100
    var cellsHigh = 100
    var cellSize = 4
    var generation = 0
    
    init(metalView: MTKView) {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let comandQueue = device.makeCommandQueue() else {
                fatalError("GPU not here")
        }
        Renderer.device = device
        Renderer.commandQueue = comandQueue
        metalView.device = device
        
        vertexData = [-1.0, -1.0, 0.0, 1.0,
                       1.0, -1.0, 0.0, 1.0,
                      -1.0,  1.0, 0.0, 1.0,
                      -1.0,  1.0, 0.0, 1.0,
                       1.0, -1.0, 0.0, 1.0,
                       1.0,  1.0, 0.0, 1.0]
        let dataSize = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertexData,
                                         length: dataSize,
                                         options: [])!


        let library = device.makeDefaultLibrary()
        let vertexFn = library?.makeFunction(name: "vertex_shader")
        let fragmentFn = library?.makeFunction(name: "fragment_shader")
        
        let renderDesc = MTLRenderPipelineDescriptor()
        renderDesc.vertexFunction = vertexFn
        renderDesc.fragmentFunction = fragmentFn
        renderDesc.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        renderState = try! device.makeRenderPipelineState(descriptor: renderDesc)
        
        let computeFn = library?.makeFunction(name: "generation")
        computeState = try! device.makeComputePipelineState(function: computeFn!)
        
        (generationA, generationB) = Self.makeTextures(device: device,
                                         width: cellsWide,
                                         height: cellsHigh)
        
        super.init()
        
        metalView.clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 0.8, alpha: 1.0)
        metalView.delegate = self
        
        restart(random: true)
    }


func currentGenerationTexture() -> MTLTexture {
  generation % 2 == 0 ? generationA : generationB
}

func nextGenerationTexture() -> MTLTexture {
  generation % 2 == 0 ? generationB : generationA
}

static func makeTextures(device: MTLDevice,
                           width: Int,
                           height: Int) -> (MTLTexture, MTLTexture) {
    let textureDescriptor = MTLTextureDescriptor()
    textureDescriptor.storageMode = .managed
    textureDescriptor.usage = [.shaderWrite, .shaderRead]
    textureDescriptor.pixelFormat = .r8Uint
    textureDescriptor.width = width
    textureDescriptor.height = height
    textureDescriptor.depth = 1
    
    let generationA = device.makeTexture(descriptor: textureDescriptor)!
    let generationB = device.makeTexture(descriptor: textureDescriptor)!
    
    return (generationA, generationB)
  }

func restart(random: Bool) {
    generation = 0
    var seed = [UInt8](repeating: 0, count: cellsWide * cellsHigh)
    if random {
      let numberOfCells = cellsWide * cellsHigh
      let numberOfLiveCells = Int(pow(Double(numberOfCells), 0.8))
      for _ in (0..<numberOfLiveCells) {
        let r = (0..<numberOfCells).randomElement()!
        seed[r] = 1
      }
    }
    currentGenerationTexture().replace(
      region: MTLRegionMake2D(0, 0, cellsWide, cellsHigh),
      mipmapLevel: 0,
      withBytes: seed,
      bytesPerRow: cellsWide * MemoryLayout<UInt8>.stride
    )
  }
}

extension Renderer: MTKViewDelegate {

  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
  
  func draw(in view: MTKView) {
    guard
        let buffer = Renderer.commandQueue.makeCommandBuffer(),
      let desc = view.currentRenderPassDescriptor,
      let renderEncoder = buffer.makeRenderCommandEncoder(descriptor: desc)
      else { return }
    
    renderEncoder.setRenderPipelineState(renderState)
    renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    renderEncoder.setFragmentTexture(currentGenerationTexture(), index: 0)
    renderEncoder.drawPrimitives(type: .triangle,
                                 vertexStart: 0,
                                 vertexCount: 6)
    renderEncoder.endEncoding()
    
    guard
      let computeEncoder = buffer.makeComputeCommandEncoder()
      else { return }
    
    computeEncoder.setComputePipelineState(computeState)
    computeEncoder.setTexture(currentGenerationTexture(), index: 0)
    computeEncoder.setTexture(nextGenerationTexture(), index: 1)
    let threadWidth = computeState.threadExecutionWidth
    let threadHeight = computeState.maxTotalThreadsPerThreadgroup / threadWidth
    let threadsPerThreadgroup = MTLSizeMake(threadWidth, threadHeight, 1)
    let threadsPerGrid = MTLSizeMake(cellsWide, cellsHigh, 1)
    computeEncoder.dispatchThreads(threadsPerGrid,
                                   threadsPerThreadgroup: threadsPerThreadgroup)
    computeEncoder.endEncoding()
      
    if let drawable = view.currentDrawable {
      buffer.present(drawable)
    }
    buffer.commit()

    generation += 1
  }
}
