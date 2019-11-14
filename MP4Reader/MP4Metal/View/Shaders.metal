//
//  Shaders.metal
//  LearnMetal
//
//  Created by XiaoXueYuan on 2019/1/10.
//  Copyright © 2019 xxy. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#import "XYShaderTypes.h"
typedef struct
{
    float4 position [[position]];
    float2 texCoords;
    float2 alphaCoords;
} RasterizerData;

vertex RasterizerData vertexShader(constant XYVertex *vertices [[buffer(XYVertexInputRGBVertices)]],
                                   constant XYVertex *avertices [[buffer(XYVertexInputAlphaVertices)]],
                                   uint vid [[vertex_id]]) {
    RasterizerData outVertex;
    outVertex.position = vector_float4(vertices[vid].position, 0.0, 1.0);
    outVertex.texCoords = vertices[vid].textureCoordinate;
    outVertex.alphaCoords = avertices[vid].textureCoordinate;
    return outVertex;
}

fragment float4 fragmentShader(RasterizerData inVertex [[stage_in]],
                               texture2d<float> tex2d [[texture(XYTextureIndexBaseColor)]]) {
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    float4 color = float4(tex2d.sample(textureSampler, inVertex.texCoords));
    float4 aColor = float4(tex2d.sample(textureSampler, inVertex.alphaCoords));
    float maskY = 0.299 * aColor.r + 0.587 * aColor.g + 0.114 * aColor.b;
//    float maskY = 0.257 * aColor.r + 0.504 * aColor.g + 0.098 * aColor.b;
    return float4(color.r,color.g,color.b,maskY);
}
