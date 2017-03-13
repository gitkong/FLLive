//
//  FLVideoEncoder.h
//  FLLive
//
//  Created by clarence on 17/3/7.
//  Copyright © 2017年 gitKong. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;
#import "FLAVConfig.h"
@interface FLVideoEncoder : NSObject

@property (nonatomic,strong)FLVideoConfig *fl_videoConfig;

/*
 *  BY gitKong
 *
 *  将采集的CMSampleBufferRef 转换为YUV数据
 */
- (NSData *)fl_SampleBufferToYuvData:(CMSampleBufferRef)sampleBufferRef;

- (void)fl_open;

- (void)fl_close;

@end
