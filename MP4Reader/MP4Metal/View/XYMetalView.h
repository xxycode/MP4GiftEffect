//
//  XYMetalView.h
//  LearnMetal
//
//  Created by XiaoXueYuan on 2019/1/10.
//  Copyright © 2019 xxy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface XYMetalView : UIView

- (void)renderSampleBuffer:(CMSampleBufferRef)sampleBuffer;

- (void)clean;

@end

NS_ASSUME_NONNULL_END
