//
//  ViewController.swift
//  firstMetalApp
//
//  Created by Dima on 25/01/2021.
//  Copyright © 2021 Dima. All rights reserved.
//

import MetalKit

class ViewController: NSViewController {
    
    var renderer: Renderer?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let metalView = view as? MTKView else {
            fatalError("metal view not set up in storyboard")
        }
        
        renderer  = Renderer(metalView: metalView)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

