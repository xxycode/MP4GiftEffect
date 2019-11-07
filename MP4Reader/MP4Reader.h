//
//  MP4Reader.h
//  MP4Reader
//
//  Created by Xiaoxueyuan on 2019/11/7.
//  Copyright © 2019 Xiaoxueyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@class MP4Reader;

NS_ASSUME_NONNULL_BEGIN

@protocol MP4ReaderDelegate <NSObject>

@optional

- (void)MP4Reader:(MP4Reader *)reader didOutputVideoSampleBuffer:(CMSampleBufferRef)videoSampleBuffer;

- (void)MP4ReaderDidFinishedReadFile:(MP4Reader *)reader;

@end

@interface MP4Reader : NSObject

@property (nonatomic, weak) id<MP4ReaderDelegate> delegate;

@property (nonatomic, assign) NSTimeInterval readTimeInterval;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithFilePath:(NSString *)filePath NS_DESIGNATED_INITIALIZER;

- (void)startRead;

@end

NS_ASSUME_NONNULL_END
