//
//  FLVideoConfig.m
//  FLLive
//
//  Created by clarence on 17/3/6.
//  Copyright © 2017年 gitKong. All rights reserved.
//

#import "FLAVConfig.h"

@implementation FLAudioConfig

- (instancetype)init{
    if (self = [super init]) {
        self.fl_bitrate = 1000 * 1000;
        self.fl_channelCount = 1;
        self.f_sampleSize = 16;
        self.fl_sampleRate = 44100;
    }
    return self;
}

@end

@implementation FLVideoConfig

- (instancetype)init{
    if (self = [super init]) {
        self.fl_bitrate = 1000 * 1000;
        self.fl_fps = 20;
        self.fl_videoSize = CGSizeMake(540, 960);
        self.fl_videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    return self;
}

- (CGSize)fl_videoSize{
    if (self.fl_videoOrientation == AVCaptureVideoOrientationLandscapeRight || self.fl_videoOrientation == AVCaptureVideoOrientationLandscapeLeft) {
        return CGSizeMake(_fl_videoSize.height, _fl_videoSize.width);
    }
    return _fl_videoSize;
}

@end
