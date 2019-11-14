//
//  PNGSequenceViewController.m
//  MP4Reader
//
//  Created by Xiaoxueyuan on 2019/11/14.
//  Copyright © 2019 Xiaoxueyuan. All rights reserved.
//

#import "PNGSequenceViewController.h"

@interface PNGSequenceViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation PNGSequenceViewController

- (void)viewDidLoad {
    // Do any additional setup after loading the view.
}

- (IBAction)playAction:(id)sender {
    //qiuhun_00025
    NSMutableArray *arr = @[].mutableCopy;
    for (int i = 25; i <= 237; ++i) {
        @autoreleasepool {
            NSString *namePrefix = @"qiuhun_00";
            if (i < 100) {
                namePrefix = @"qiuhun_000";
            }
            NSString *fullName = [NSString stringWithFormat:@"%@%d.png", namePrefix, i];
            UIImage *image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:fullName ofType:nil]];
            if (image) {
                [arr addObject:image];
            }
        }
    }
    self.imageView.animationImages = arr;
    //24fps
    self.imageView.animationDuration = arr.count * (1.0 / 24);
    [self.imageView startAnimating];
}

- (void)dealloc {
    self.imageView.animationImages = nil;
    NSLog(@"%s", __func__);
}

@end
