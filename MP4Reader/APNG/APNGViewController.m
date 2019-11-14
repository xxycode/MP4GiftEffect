//
//  APNGViewController.m
//  MP4Reader
//
//  Created by Xiaoxueyuan on 2019/11/14.
//  Copyright © 2019 Xiaoxueyuan. All rights reserved.
//

#import "APNGViewController.h"
#import <YYImage.h>

@interface APNGViewController ()

@property (weak, nonatomic) IBOutlet YYAnimatedImageView *imageView;

@end

@implementation APNGViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)playAction:(id)sender {
    YYImage *image = [YYImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"000_iSpt.png" ofType:nil]];
    self.imageView.image = image;
}

@end
