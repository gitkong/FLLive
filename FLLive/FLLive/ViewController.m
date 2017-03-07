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
@property (nonatomic,strong)FLAVCaptureManager *capture;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.capture = [[FLAVCaptureManager alloc] init];
    
//    UIView *preview = [[UIView alloc] initWithFrame:self.view.bounds];
//    [self.view addSubview:preview];
//    capture.fl_previewView = preview;
//    [capture switchCamera];
//    capture.fl_captureSessionPreset = FLCaptureSessionPreset_3840x2160;
    
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


-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    self.capture.fl_previewView = self.view;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
