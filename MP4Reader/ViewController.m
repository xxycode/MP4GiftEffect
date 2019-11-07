//
//  ViewController.m
//  MP4Reader
//
//  Created by Xiaoxueyuan on 2019/11/7.
//  Copyright © 2019 Xiaoxueyuan. All rights reserved.
//

#import "ViewController.h"
#import "MP4Reader.h"

@interface ViewController ()<MP4ReaderDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (strong, nonatomic) MP4Reader *mp4Reader;

@property (nonatomic, strong) NSMutableArray *frames;

@property (nonatomic, assign) BOOL playing;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"example" ofType:@"mp4"];
    self.frames = @[].mutableCopy;
    self.mp4Reader = [[MP4Reader alloc] initWithFilePath:filePath];
    self.mp4Reader.readTimeInterval = 0.04;
    self.mp4Reader.delegate = self;
}

- (IBAction)readAction:(id)sender {
    self.playing = YES;
    [self.mp4Reader startRead];
    [self startRender];
}

- (void)startRender {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (self.playing) {
            UIImage *image = nil;
            @synchronized (self) {
                image = self.frames.firstObject;
                if (image) {
                    NSLog(@"before:%d",(int)self.frames.count);
                    [self.frames removeObjectAtIndex:0];
                    NSLog(@"after:%d",(int)self.frames.count);
                }
            }
            if (image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.imageView.image = image;
                });
            }
            [NSThread sleepForTimeInterval:0.043];
        }
    });
}

- (void)MP4Reader:(MP4Reader *)reader didOutputVideoSampleBuffer:(CMSampleBufferRef)videoSampleBuffer {
    UIImage *image = [self imageFromSampleBufferRef:videoSampleBuffer];
    @synchronized (self) {
        [self.frames addObject:image];
    }
}

- (void)MP4ReaderDidFinishedReadFile:(MP4Reader *)reader {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.playing = NO;
    });
}

- (UIImage *)imageFromSampleBufferRef:(CMSampleBufferRef)sampleBufferRef {
    // 为媒体数据设置一个CMSampleBufferRef
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBufferRef);
    // 锁定 pixel buffer 的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    // 得到 pixel buffer 的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // 得到 pixel buffer 的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到 pixel buffer 的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);

    // 创建一个依赖于设备的 RGB 颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphic context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    //根据这个位图 context 中的像素创建一个 Quartz image 对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁 pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

    // 释放 context 和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    // 用 Quzetz image 创建一个 UIImage 对象
    UIImage *image = [UIImage imageWithCGImage:quartzImage];

    // 释放 Quartz image 对象
    CGImageRelease(quartzImage);
    CFRelease(imageBuffer);
    return image;

}

@end
