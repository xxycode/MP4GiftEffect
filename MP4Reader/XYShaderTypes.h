//
//  XYShaderTypes.h
//  LearnMetal
//
//  Created by XiaoXueYuan on 2019/1/10.
//  Copyright © 2019 xxy. All rights reserved.
//

#ifndef XYShaderTypes_h
#define XYShaderTypes_h

#include <simd/simd.h>

typedef struct {
    vector_float2 position;
    vector_float2 textureCoordinate;
} XYVertex;

typedef enum XYTextureIndex {
    XYTextureIndexBaseColor = 0,
} XYTextureIndex;

typedef enum XYVertexInputIndex {
    XYVertexInputRGBVertices   = 0,
    XYVertexInputAlphaVertices = 1,
} XYVertexInputIndex;

#endif /* XYShaderTypes_h */
