//
//  FLAVCaptureManager.h
//  FLLive
//
//  Created by clarence on 17/3/1.
//  Copyright © 2017年 gitKong. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;
#import "FLAVConfig.h"
#import "FLVideoEncoder.h"

typedef NS_ENUM(NSUInteger, FLCaptureSessionPreset) {
    FLCaptureSessionPreset_High,//iOS 4.0+
    FLCaptureSessionPreset_Medium,//iOS 4.0+
    FLCaptureSessionPreset_Low,//iOS 4.0+
    FLCaptureSessionPreset_352x288,//iOS 5.0+
    FLCaptureSessionPreset_640x480,//iOS 4.0+
    FLCaptureSessionPreset_960x540,//iOS 5.0+
    FLCaptureSessionPreset_1280x720,//iOS 4.0+
    FLCaptureSessionPreset_1920x1080,//iOS 5.0+
    FLCaptureSessionPreset_3840x2160//iOS 9.0+
};

@interface FLAVCaptureManager : NSObject
/*
 *  BY gitKong
 *
 *  视频编码配置
 */
@property (nonatomic,strong)FLVideoConfig *fl_videoConfig;
/*
 *  BY gitKong
 *
 *  音频编码配置
 */
@property (nonatomic,strong)FLAudioConfig *fl_audioConfig;

@property (nonatomic,strong)FLVideoEncoder *fl_videoEncoder;

/*
 *  BY gitKong
 *
 *  whether camera position is font or not,default is YES,setting NO to change camera position to back(前置/后置摄像头)
 */
@property (nonatomic,assign)BOOL fl_isFont;

/*
 *  BY gitKong
 *
 *  capture session preset,default is FLCaptureSessionPreset_960x540 (采集质量)
 */
@property (nonatomic,assign)FLCaptureSessionPreset fl_captureSessionPreset;

/*
 *  BY gitKong
 *
 *  preview view(显示的view)
 */
@property (nonatomic,strong)UIView *fl_previewView;


- (instancetype)initWithVideoConfig:(FLVideoConfig *)videoConfig audioConfig:(FLAudioConfig *)audioConfig;

@end
