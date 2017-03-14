//
//  FLVideoConfig.h
//  FLLive
//
//  Created by clarence on 17/3/6.
//  Copyright © 2017年 gitKong. All rights reserved.
//
/*
 *  BY gitKong
 *
 *  主要用于编码
 */
#import <Foundation/Foundation.h>
@import UIKit;
@import AVFoundation;

@interface FLAudioConfig : NSObject
/*
 *  BY gitKong
 *
 *  码率
 */
@property (nonatomic,assign)NSInteger fl_bitrate;
/*
 *  BY gitKong
 *
 *  通道数
 */
@property (nonatomic,assign)NSInteger fl_channelCount;
/*
 *  BY gitKong
 *
 *  采样率,可选 44100 22050 11025 5500
 */
@property (nonatomic,assign)NSInteger fl_sampleRate;
/*
 *  BY gitKong
 *
 *  采样大小,可选 16 8
 */
@property (nonatomic,assign)NSInteger f_sampleSize;
@end

@interface FLVideoConfig : NSObject
/*
 *  BY gitKong
 *
 *  采集分辨率大小,默认 540 * 960,貌似要对应采集质量，否则会出现视频变形
 */
@property (nonatomic,assign)CGSize fl_videoSize;
/*
 *  BY gitKong
 *
 *  码率
 */
@property (nonatomic,assign)NSInteger fl_bitrate;
/*
 *  BY gitKong
 *
 *  帧率
 */
@property (nonatomic,assign)NSInteger fl_fps;
/*
 *  BY gitKong
 *
 *  video orientatation(推流方向)
 */
@property (nonatomic,assign)AVCaptureVideoOrientation fl_videoOrientation;

@end
