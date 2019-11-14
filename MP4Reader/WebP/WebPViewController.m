//
//  WebPViewController.m
//  MP4Reader
//
//  Created by Xiaoxueyuan on 2019/11/14.
//  Copyright © 2019 Xiaoxueyuan. All rights reserved.
//

#import "WebPViewController.h"
#import <YYImage.h>

@interface WebPViewController ()

@property (weak, nonatomic) IBOutlet YYAnimatedImageView *imageView;

@end

@implementation WebPViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)playAction:(id)sender {
    YYImage *image = [YYImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"000_iSpt.webp" ofType:nil]];
    self.imageView.image = image;
}

@end
