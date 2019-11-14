//
//  LottieViewController.m
//  MP4Reader
//
//  Created by Xiaoxueyuan on 2019/11/14.
//  Copyright © 2019 Xiaoxueyuan. All rights reserved.
//

#import "LottieViewController.h"
#import <Lottie/Lottie.h>

@interface LottieViewController ()
@property (weak, nonatomic) IBOutlet LOTAnimationView *animationView;

@end

@implementation LottieViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)playAction:(id)sender {
    self.animationView.animation = @"data";
    [self.animationView playWithCompletion:^(BOOL animationFinished) {
      // Do Something
    }];
}


@end
