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

@property (nonatomic, strong) AVAssetReaderTrackOutput *readerVideoTrackOutput;



@end

@implementation MP4Reader

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    
    if (self) {
        if (filePath && filePath.length > 0) {
            NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
//            NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
            self.asset = [[AVURLAsset alloc] initWithURL:fileUrl options:nil];
            self.readerQueue = dispatch_queue_create("com.xxy.mp4reader", DISPATCH_QUEUE_SERIAL);
        }
    }
    return self;
}

- (void)repareToRead {
    self.videoTracks = [self.asset tracksWithMediaType:AVMediaTypeVideo].copy;
    AVAssetTrack *videoTrack = self.videoTracks.firstObject;
    NSError *error = nil;
    self.reader = [[AVAssetReader alloc] initWithAsset:self.asset error:&error];
    if (videoTrack) {
        int m_pixelFormatType;
        m_pixelFormatType = kCVPixelFormatType_32BGRA;
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        [options setObject:@(m_pixelFormatType) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        self.readerVideoTrackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:options];
        [self.reader addOutput:self.readerVideoTrackOutput];
        [self.reader startReading];
    } else {
        NSAssert(NO, @"No video track !!!");
    }
}

- (CMSampleBufferRef)readBuffer {
    CMSampleBufferRef sampleBufferRef = nil;
    @synchronized (self) {
        if (self.readerVideoTrackOutput) {
            sampleBufferRef = [self.readerVideoTrackOutput copyNextSampleBuffer];
        }
        
        if (self.reader && self.reader.status == AVAssetReaderStatusCompleted) {
            self.readerVideoTrackOutput = nil;
            self.reader = nil;
            if (self.delegate && [self.delegate respondsToSelector:@selector(MP4ReaderDidFinishedReadFile:)]) {
                [self.delegate MP4ReaderDidFinishedReadFile:self];
            }
        }
    }
    if (sampleBufferRef) {
        return (CMSampleBufferRef)CFAutorelease(sampleBufferRef);
    }
    return nil;
}

- (void)dealloc {
    [self.reader cancelReading];
    NSLog(@"%s",__func__);
}

@end
