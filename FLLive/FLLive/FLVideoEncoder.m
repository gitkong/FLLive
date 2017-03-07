//
//  FLVideoEncoder.m
//  FLLive
//
//  Created by clarence on 17/3/7.
//  Copyright © 2017年 gitKong. All rights reserved.
//

#import "FLVideoEncoder.h"
@import VideoToolbox;

@interface FLVideoEncoder ()
@property (nonatomic,assign)VTCompressionSessionRef newSession;
@end

@implementation FLVideoEncoder

static void fl_VTCompressionOutputCallback(
                                    void * CM_NULLABLE outputCallbackRefCon,
                                    void * CM_NULLABLE sourceFrameRefCon,
                                    OSStatus status,
                                    VTEncodeInfoFlags infoFlags,
                                 CM_NULLABLE CMSampleBufferRef sampleBuffer ){
    
}

- (void)fl_start{
    /*
     *  BY gitkong
     *
     *  创建编码session
     */
    OSStatus status = VTCompressionSessionCreate(NULL,// 回话的任务分发器，传NULL使用系统默认
                                                 (int32_t)self.fl_videoConfig.fl_videoSize.width,// 视频宽度
                                                 (int32_t)self.fl_videoConfig.fl_videoSize.height,// 视频高度
                                                 kCMVideoCodecType_H264, // 编码类型
                                                 NULL,// 指定编码器，NULL使用系统默认
                                                 NULL,// 源像素缓冲区的必需属性，在为源帧创建像素缓冲池时使用,NULL 表示不使用系统创建的
                                                 NULL,// 压缩数据的分发器，传NULL使用系统
                                                 fl_VTCompressionOutputCallback,// 编码回调
                                                 (__bridge void * _Nullable)(self),// 这个参数会被原封不动地传入vtCompressionSessionCallback中，此参数为编码回调同外界通信的唯一参数
                                                 &_newSession);
    
}

- (void)fl_stop{
    
}

- (NSData *)fl_SampleBufferToYuvData:(CMSampleBufferRef)sampleBufferRef{
    /*
     *  BY gitkong
     *
     *  通过CMSampleBufferGetImageBuffer方法，获得CVImageBufferRef，这里面就包含了yuv420数据的指针
     */
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBufferRef);
    /*
     *  BY gitkong
     *
     *  操作像素数据的时候，需要加锁，通过CVPixelBufferLockBaseAddress
     */
    CVPixelBufferLockBaseAddress(pixelBuffer,0);
    // 图像宽度（像素）
    size_t pixelWidth = CVPixelBufferGetWidth(pixelBuffer);
    // 图像高度（像素）
    size_t pixelHeight = CVPixelBufferGetHeight(pixelBuffer);
    /*
     *  BY gitkong
     *
     *  计算YUV所需字节数，YUV420格式 先Y，后V，中间是U。其中的Y是 w * h，U和V是 w/2 * (h/2) 就是 w * h / 4，整个YUV 占用 w * h * 3 / 2 字节数（Y + U + V）
     */
    size_t y_size = pixelWidth * pixelHeight;
    size_t uv_size = y_size / 4;
    
    if (CVPixelBufferIsPlanar(pixelBuffer)) {
        // 分配YUV数据所需内存空间
        uint8_t *yuv_frame = malloc(y_size + 2 * uv_size);
        
        // 获取y数据、uv数据
        uint8_t *y_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        uint8_t *uv_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        // 填充到对应内存
        memcpy(yuv_frame, y_frame, y_size);
        memcpy(yuv_frame + y_size, uv_frame, uv_size * 2);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        /*
         *  BY gitkong
         *
         *  此时不能使用dataWithBytesNoCopy，因为yuv_frame 需要释放，需要copy一份给data，才能正常释放，不然一释放，data也不能正常获取
         */
        NSData *NV12Data = [NSData dataWithBytes:yuv_frame length:y_size + 2 * uv_size];
        // 释放
        free(yuv_frame);
        yuv_frame = NULL;
        
        // 此时数据是没有考虑横屏，默认是竖屏，如果要处理，可以使用第三方libyuv
        return NV12Data;
    }
    else{
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        NSLog(@"YUV is NOT Plane data from CMSampleBufferRef");
        return nil;
    }
}

@end
