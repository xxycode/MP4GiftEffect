//
//  ViewController.m
//  MP4Reader
//
//  Created by Xiaoxueyuan on 2019/11/7.
//  Copyright © 2019 Xiaoxueyuan. All rights reserved.
//

#import "ViewController.h"
#import "MP4Reader.h"
#import "XYMetalView.h"
#import "NKMTKView.h"

@interface ViewController ()<MP4ReaderDelegate>

@property (strong, nonatomic) MP4Reader *mp4Reader;

@property (nonatomic, strong) NSMutableArray *frames;

@property (nonatomic, assign) BOOL readFinished;

@property (strong, nonatomic) NKMTKView *metalView;

@property (nonatomic, strong) CADisplayLink *timer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupSubview];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"example" ofType:@"mp4"];
    self.mp4Reader = [[MP4Reader alloc] initWithFilePath:filePath];
    self.mp4Reader.delegate = self;
}

- (void)setupSubview {
    [self.view addSubview:self.metalView];
    // center _metalView horizontally in self.view
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_metalView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    // align _metalView from the top
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-60-[_metalView]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_metalView)]];
    // width constraint
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_metalView(==307)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_metalView)]];
    // height constraint
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_metalView(==240)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_metalView)]];

}

- (NKMTKView *)metalView {
    if (_metalView) {
        return _metalView;
    }
    _metalView = [NKMTKView view];
    _metalView.translatesAutoresizingMaskIntoConstraints = NO;
    return _metalView;
}

//- (XYMetalView *)metalView {
//    if (_metalView) {
//        return _metalView;
//    }
//    _metalView = [[XYMetalView alloc] initWithFrame:CGRectZero];
//    _metalView.translatesAutoresizingMaskIntoConstraints = NO;
//    return _metalView;
//}

- (IBAction)readAction:(id)sender {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    [self.mp4Reader repareToRead];
    self.timer = [[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(linkAction)];
    if (@available(iOS 10.0, *)) {
        self.timer.preferredFramesPerSecond = 24;
    } else {
        self.timer.frameInterval = 1;
    }
    [self.timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
}

- (void)linkAction {
    NSLog(@"读取中");
    CMSampleBufferRef sampleBuffer = [self.mp4Reader readBuffer];
    if (sampleBuffer) {
        [self.metalView renderSampleBuffer:sampleBuffer];
//        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//        CVPixelBufferRelease(pixelBuffer);
//        CMSampleBufferInvalidate(sampleBuffer);
    }
}

- (void)MP4ReaderDidFinishedReadFile:(MP4Reader *)reader {
    NSLog(@"读完了");
//    self.mp4Reader = nil;
//    [self.timer invalidate];
//    self.timer = nil;
}

@end
