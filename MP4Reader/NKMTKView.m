//
//  NKMTKView.m
//  MP4Reader
//
//  Created by Xiaoxueyuan on 2019/11/13.
//  Copyright © 2019 Xiaoxueyuan. All rights reserved.
//

#import "NKMTKView.h"
#import "XYShaderTypes.h"

@interface NKMTKView () <MTKViewDelegate>

@property (nonatomic, assign) vector_uint2 viewportSize;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLTexture> texture;
@property (nonatomic, strong) id<MTLBuffer> rgbVertices;
@property (nonatomic, strong) id<MTLBuffer> alphaVertices;
@property (nonatomic, assign) NSUInteger numRgbVertices;
@property (nonatomic, assign) NSUInteger numAlphaVertices;

@end

@implementation NKMTKView

+ (instancetype)view {
    NKMTKView *view = [[NKMTKView alloc] initWithFrame:CGRectZero device:MTLCreateSystemDefaultDevice()];
    [view commonInit];
    return view;
}

- (void)commonInit {
    self.delegate = self;
    //设置为0 手动调用draw来刷新
    self.preferredFramesPerSecond = 0;
    //设置为透明
    self.layer.opaque = NO;
    CVMetalTextureCacheCreate(NULL, NULL, self.device, NULL, &_textureCache);
    self.viewportSize = (vector_uint2){self.drawableSize.width, self.drawableSize.height};
    [self setupPipeline];
    [self setupVertex];
}

// 设置渲染管道
-(void)setupPipeline {
    id<MTLLibrary> defaultLibrary = [self.device newDefaultLibrary]; // .metal
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"]; // 顶点shader，vertexShader是函数名
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"]; // 片元shader，fragmentShader是函数名
    
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat; // 设置颜色格式
    self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:NULL]; // 创建图形渲染管道，耗性能操作不宜频繁调用
    self.commandQueue = [self.device newCommandQueue]; // CommandQueue是渲染指令队列，保证渲染指令有序地提交到GPU
}

- (void)setupVertex {
    //取左边的真实颜色
    XYVertex rgbVertices[] = {
        {{-1, -1},{0, 1}},
        {{-1, 1},{0, 0}},
        {{1, -1},{0.5, 1}},
        {{1, 1},{0.5, 0}}
    };
    //取右边的遮罩通过灰度来计算alpha
    XYVertex alphaVertices[] = {
        {{-1, -1},{0.5, 1}},
        {{-1, 1},{0.5, 0}},
        {{1, -1},{1, 1}},
        {{1, 1},{1, 0}}
    };
    self.rgbVertices = [self.device newBufferWithBytes:rgbVertices
                                                length:sizeof(rgbVertices)
                                               options:MTLResourceStorageModeShared]; // 创建顶点缓存
    
    self.numRgbVertices = sizeof(rgbVertices) / sizeof(XYVertex); // 顶点个数
    
    self.alphaVertices = [self.device newBufferWithBytes:alphaVertices
                                                length:sizeof(alphaVertices)
                                               options:MTLResourceStorageModeShared]; // 创建顶点缓存
    
    self.numAlphaVertices = sizeof(alphaVertices) / sizeof(XYVertex); // 顶点个数
}

- (void)renderSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    CVMetalTextureRef tmpTexture = NULL;
    // 如果MTLPixelFormatBGRA8Unorm和摄像头采集时设置的颜色格式不一致，则会出现图像异常的情况；
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &tmpTexture);
    if(status == kCVReturnSuccess) {
        self.drawableSize = CGSizeMake(width, height);
        self.texture = CVMetalTextureGetTexture(tmpTexture);
    }
    if (tmpTexture) {
        CFRelease(tmpTexture);
    }
//    CVPixelBufferRelease(pixelBuffer);
//    CMSampleBufferInvalidate(sampleBuffer);
    [self draw];
}

- (void)clean {
    self.paused = YES;
    [self releaseDrawables];
    
}

#pragma mark - delegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    self.viewportSize = (vector_uint2){size.width, size.height};
}

- (void)drawInMTKView:(MTKView *)view {
    // 每次渲染都要单独创建一个CommandBuffer
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    // MTLRenderPassDescriptor描述一系列attachments的值，类似GL的FrameBuffer；同时也用来创建MTLRenderCommandEncoder
    if(renderPassDescriptor && self.texture) {
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.f, 0.f, 0.f, 0.f); // 设置默认颜色
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor]; //编码绘制指令的Encoder // 设置显示区域
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, self.viewportSize.x, self.viewportSize.y, -1.0, 1.0 }];
        [renderEncoder setRenderPipelineState:self.pipelineState]; // 设置渲染管道，以保证顶点和片元两个shader会被调用
        
        [renderEncoder setVertexBuffer:self.rgbVertices offset:0 atIndex:XYVertexInputRGBVertices]; // 设置顶点缓存
        
        [renderEncoder setVertexBuffer:self.alphaVertices offset:0 atIndex:XYVertexInputAlphaVertices];
        
        [renderEncoder setFragmentTexture:self.texture atIndex:XYTextureIndexBaseColor];
        
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4]; // 绘制
        
        [renderEncoder endEncoding]; // 结束
        
        [commandBuffer presentDrawable:view.currentDrawable]; // 显示
    }
    
    [commandBuffer commit]; // 提交；
}

@end
