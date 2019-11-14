//
//  NKMTKView.h
//  MP4Reader
//
//  Created by Xiaoxueyuan on 2019/11/13.
//  Copyright © 2019 Xiaoxueyuan. All rights reserved.
//

#import <MetalKit/MetalKit.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface NKMTKView : MTKView

+ (instancetype)view;

- (void)renderSampleBuffer:(CMSampleBufferRef)sampleBuffer;

- (void)clean;

@end

NS_ASSUME_NONNULL_END
