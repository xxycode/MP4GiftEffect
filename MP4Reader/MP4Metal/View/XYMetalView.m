//
//  XYMetalView.m
//  LearnMetal
//
//  Created by XiaoXueYuan on 2019/1/10.
//  Copyright © 2019 xxy. All rights reserved.
//

#import "XYMetalView.h"
#import <Metal/Metal.h>
#import "XYShaderTypes.h"

@interface XYMetalView()

@property (nonatomic, strong) id <MTLDevice> device;

@property (nonatomic, strong) CAMetalLayer *metalLayer;

@property (nonatomic, strong) id <MTLRenderPipelineState> pipelineState;

@property (nonatomic, assign) CVMetalTextureCacheRef textureCache; //output

@property (nonatomic, strong) id <MTLTexture> texture;

@end

@implementation XYMetalView

- (void)awakeFromNib {
    [super awakeFromNib];
    [self commonInit];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.device = MTLCreateSystemDefaultDevice();
    self.backgroundColor = UIColor.clearColor;
    self.metalLayer = [CAMetalLayer layer];
    self.metalLayer.opaque = NO;
    self.metalLayer.frame = self.bounds;
    self.metalLayer.device = self.device;
    CVMetalTextureCacheCreate(NULL, NULL, self.device, NULL, &_textureCache);
    [self.layer addSublayer:self.metalLayer];
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setupPipeLine];
    self.metalLayer.frame = self.layer.bounds;
}

- (void)renderSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVMetalTextureRef tmpTexture = NULL;
    // 如果MTLPixelFormatBGRA8Unorm和摄像头采集时设置的颜色格式不一致，则会出现图像异常的情况；
    //CGFloat scale = NSScreen.mainScreen.backingScaleFactor;
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);

    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &tmpTexture);
    
    if(status == kCVReturnSuccess) {
        self.texture = CVMetalTextureGetTexture(tmpTexture);
        [self render];
    }
    if (tmpTexture) {
        CFRelease(tmpTexture);
    }
    CVPixelBufferRelease(pixelBuffer);
    CMSampleBufferInvalidate(sampleBuffer);
}

- (void)clean {
}

- (void)render {
    id <CAMetalDrawable> drawable = self.metalLayer.nextDrawable;
    if (drawable) {
        MTLRenderPassDescriptor *renderPassDescriptor = [[MTLRenderPassDescriptor alloc] init];
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.f, 0.f, 0.f, 0.f);
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        id <MTLCommandQueue> commandQueue = [self.device newCommandQueue];
        id <MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
        id <MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [commandEncoder setRenderPipelineState:self.pipelineState];
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
        [commandEncoder setVertexBytes:rgbVertices length:sizeof(rgbVertices) atIndex:XYVertexInputRGBVertices];
        [commandEncoder setVertexBytes:alphaVertices length:sizeof(alphaVertices) atIndex:XYVertexInputAlphaVertices];
        [commandEncoder setFragmentTexture:self.texture atIndex:XYTextureIndexBaseColor];
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
        [commandEncoder endEncoding];
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
    }
}

- (void)setupPipeLine {
    id <MTLLibrary> library = [self.device newDefaultLibrary];
    id <MTLFunction> vertexFunction = [library newFunctionWithName:@"vertexShader"];
    id <MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragmentShader"];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.vertexFunction = vertexFunction;
    pipelineDescriptor.fragmentFunction = fragmentFunction;
    pipelineDescriptor.colorAttachments[0].pixelFormat = self.metalLayer.pixelFormat;
    MTLRenderPipelineColorAttachmentDescriptor *renderbufferAttachment = pipelineDescriptor.colorAttachments[0];
    renderbufferAttachment.blendingEnabled = YES; //启用混合
    renderbufferAttachment.rgbBlendOperation = MTLBlendOperationAdd;
    renderbufferAttachment.alphaBlendOperation = MTLBlendOperationAdd;
    renderbufferAttachment.sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    renderbufferAttachment.sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    renderbufferAttachment.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    renderbufferAttachment.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;

    self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:nil];
}

- (void)dealloc {
    
}

@end
