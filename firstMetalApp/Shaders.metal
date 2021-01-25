//
//  Shaders.metal
//  firstMetalApp
//
//  Created by Dima on 25/01/2021.
//  Copyright © 2021 Dima. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct VertexIn {
    float4 position [[ attribute(0) ]];
};

vertex float4 vertex_main(const VertexIn vertexIn [[stage_in]], constant float &timer [[buffer(1)]]) {
    float4 position = vertexIn.position;
    position.y += timer;
    return position;
}

fragment float4 fragment_main(constant float &timer [[buffer(1)]]) {
    return float4(1, 0, timer*timer, 1);
}
