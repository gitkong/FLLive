//
//  ViewController.m
//  FLLive
//
//  Created by clarence on 17/3/1.
//  Copyright © 2017年 gitKong. All rights reserved.
//

#import "ViewController.h"
#import "FLAVCaptureManager.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    FLAVCaptureManager *capture = [[FLAVCaptureManager alloc] init];
    capture.fl_previewView = self.view;
    capture.fl_videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
//    UIView *firstView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 200)];
//    FLAVCaptureManager *capture = [[FLAVCaptureManager alloc] init];
//    capture.fl_isFont = NO;
//    capture.fl_previewView = firstView;
//    [self.view addSubview:firstView];
    
//    UIView *secondView = [[UIView alloc] initWithFrame:CGRectMake(0, 300, [UIScreen mainScreen].bounds.size.width, 200)];
//    FLAVCaptureManager *capture1 = [[FLAVCaptureManager alloc] init];
//    capture1.fl_previewView = secondView;
//    [self.view addSubview:secondView];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
