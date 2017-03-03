//
//  FLAVCaptureManager.h
//  FLLive
//
//  Created by clarence on 17/3/1.
//  Copyright © 2017年 gitKong. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;
@import AVFoundation;

typedef NS_ENUM(NSUInteger, FLCaptureSessionPreset) {
    FLCaptureSessionPreset_High,//iOS 4.0+
    FLCaptureSessionPreset_Medium,//iOS 4.0+
    FLCaptureSessionPreset_Low,//iOS 4.0+
    FLCaptureSessionPreset_352x288,//iOS 5.0+
    FLCaptureSessionPreset_640x480,//iOS 4.0+
    FLCaptureSessionPreset_1280x720,//iOS 4.0+
    FLCaptureSessionPreset_1920x1080,//iOS 5.0+
    FLCaptureSessionPreset_3840x2160//iOS 9.0+
};

@interface FLAVCaptureManager : NSObject
/*
 *  BY gitKong
 *
 *  whether camera position is font or not,default is YES,setting NO to change camera position to back(前置/后置摄像头)
 */
@property (nonatomic,assign)BOOL fl_isFont;
/*
 *  BY gitKong
 *
 *  capture session preset,default is FLCaptureSessionPreset_High (采集质量)
 */
@property (nonatomic,assign)FLCaptureSessionPreset fl_captureSessionPreset;
/*
 *  BY gitKong
 *
 *  video orientatation(屏幕方向)
 */
@property (nonatomic,assign)AVCaptureVideoOrientation fl_videoOrientation;
/*
 *  BY gitKong
 *
 *  preview view(显示的view)
 */
@property (nonatomic,strong)UIView *fl_previewView;


@end
