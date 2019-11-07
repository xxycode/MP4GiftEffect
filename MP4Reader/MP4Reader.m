//
//  MP4Reader.m
//  MP4Reader
//
//  Created by Xiaoxueyuan on 2019/11/7.
//  Copyright © 2019 Xiaoxueyuan. All rights reserved.
//

#import "MP4Reader.h"
#import <AVFoundation/AVFoundation.h>

@interface MP4Reader()

@property (nonatomic, strong) AVURLAsset *asset;

@property (nonatomic, strong) AVAssetReader *reader;

@property (nonatomic, strong) NSArray *videoTracks;

@property (nonatomic, strong) dispatch_queue_t readerQueue;

@end

@implementation MP4Reader

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    
    if (self) {
        if (filePath && filePath.length > 0) {
            NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
            self.asset = [[AVURLAsset alloc] initWithURL:fileUrl options:nil];
            self.readTimeInterval = 1.0/30;
            NSError *error = nil;
            self.reader = [[AVAssetReader alloc] initWithAsset:self.asset error:&error];
            self.readerQueue = dispatch_queue_create("com.xxy.mp4reader", DISPATCH_QUEUE_SERIAL);
        }
    }
    return self;
}

- (void)startRead {
    dispatch_async(self.readerQueue, ^{
        self.videoTracks = [self.asset tracksWithMediaType:AVMediaTypeVideo].copy;
        AVAssetTrack *videoTrack = self.videoTracks.firstObject;
        if (videoTrack) {
            int m_pixelFormatType;
            //视频播放时，
            m_pixelFormatType = kCVPixelFormatType_32BGRA;
            // 其他用途，如视频压缩
            //m_pixelFormatType = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
            NSMutableDictionary *options = [NSMutableDictionary dictionary];
            [options setObject:@(m_pixelFormatType) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
            AVAssetReaderTrackOutput *videoReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:options];
            [self.reader addOutput:videoReaderOutput];
            [self.reader startReading];
            while ([self.reader status] == AVAssetReaderStatusReading && videoTrack.nominalFrameRate > 0) {
                // 读取 video sample
                CMSampleBufferRef videoBuffer = [videoReaderOutput copyNextSampleBuffer];
                if (self.delegate && [self.delegate respondsToSelector:@selector(MP4Reader:didOutputVideoSampleBuffer:)]) {
                    [self.delegate MP4Reader:self didOutputVideoSampleBuffer:videoBuffer];
                }
                
                // 根据需要休眠一段时间；比如上层播放视频时每帧之间是有间隔的,这里的 sampleInternal 我设置为0.001秒
                [NSThread sleepForTimeInterval:self.readTimeInterval];
            }
            if (self.delegate && [self.delegate respondsToSelector:@selector(MP4ReaderDidFinishedReadFile:)]) {
                [self.delegate MP4ReaderDidFinishedReadFile:self];
            }
        }
    });
}

@end
