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
/*
 *  BY gitkong
 *
 *  编码回话
 */
@property (nonatomic,assign)VTCompressionSessionRef encodeSession;
/*
 *  BY gitkong
 *
 *  通过信号量控制方法的调用顺序
 */
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
/*
 *  BY gitkong
 *
 *  因为sps、pps数据都是一样的，缓存起来
 */
@property (nonatomic,strong)NSData *spsPpsData;
/*
 *  BY gitkong
 *
 *  是否关键帧，flv格式拼接需要
 */
@property (nonatomic,assign)BOOL isKeyFrame;
/*
 *  BY gitkong
 *
 *  真实的视频帧（每帧数据就是一个NAL单元（SPS与PPS除外））
 */
@property (nonatomic,strong)NSData *naluData;
@end

@implementation FLVideoEncoder
/*
 *  BY gitkong
 *
 *  编码回调，异步执行
 */
static void fl_VTCompressionOutputCallback(
                                    void * CM_NULLABLE outputCallbackRefCon,// 回调的引用者，就是当前的实例对象
                                    void * CM_NULLABLE sourceFrameRefCon,// VTCompressionSessionEncodeFrame 帧对象
                                    OSStatus status,// 编码压缩是否成功标识
                                           VTEncodeInfoFlags infoFlags,// 编码操作中的包含信息 Contains information about the encode operation.The kVTEncodeInfo_Asynchronous bit may be set if the encode ran asynchronously.The kVTEncodeInfo_FrameDropped bit may be set if the frame was dropped.
                                 CM_NULLABLE CMSampleBufferRef sampleBuffer){// 包含编码压缩后的数据
    // 获取当前实例对象
    FLVideoEncoder *encoder = (__bridge FLVideoEncoder *)outputCallbackRefCon;
    // 编码压缩是否成功
    if (status == noErr) {
        // 通过dispatch_semaphore_signal信号 + 1 控制信号发送，wait等待，非0才往下执行
        dispatch_semaphore_signal(encoder.semaphore);
        NSLog(@"[%s]--编码失败",__func__);
    }
    // 数据是否完整没错误，通过CMSampleBufferDataIsReady  Whether or not the CMSampleBuffer's data is ready.  True is returned for special marker buffers, even though they have no data. False is returned if there is an error.
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        dispatch_semaphore_signal(encoder.semaphore);
        NSLog(@"[%s]--编码后数据不完整，有错误",__func__);
    }
    // 是否当前帧是关键帧，需要标记区分
    
    BOOL isKeyFrame = !CFDictionaryContainsKey( (CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0)), kCMSampleAttachmentKey_NotSync);
    encoder.isKeyFrame = isKeyFrame;
    /*
     *  BY gitkong
     *
     *  获取sps pps 数据（H.264的SPS和PPS串，包含了初始化H.264解码器所需要的信息参数，包括编码所用的profile，level，图像的宽和高，deblock滤波器等，数据处理时，sps pps 数据可以作为一个普通h264帧，放在h264视频流的最前面）
     
     *  因为解码器只是在第一次执行编码的时候，才编码出 SPS、PPS、和I_Frame,可以在编码器编码出每个关键帧都加上SPS、PPS ，据说通常情况编码器编出的 SPS、PPS是一样的，所以这种方法耗费资源。因此在上一个判断中判断有没有spsPpsData，有就不获取
     */
    if (!encoder.spsPpsData) {
        if (isKeyFrame) {
            // 获取sps pps 数据
            
            /*
             此时这个sps 和 pps 已经是拼接好的,如果要单独获取，可以用下面的方法：
             CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
             size_t sparameterSetSize, sparameterSetCount;
             // 获取sps
             const uint8_t *sparameterSet;
             OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, 0 );
             
             // 获取pps
             size_t pparameterSetSize, pparameterSetCount;
             const uint8_t *pparameterSet;
             OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0 );
             */
            CMFormatDescriptionRef sampleBufFormat = CMSampleBufferGetFormatDescription(sampleBuffer);
            /*
             CMVideoFormatDescription:
             mediaType:'vide'
             mediaSubType:'avc1'
             mediaSpecific:
             codecType: 'avc1'        dimensions: 1920 x 1080
             extensions:
             "CVImageBufferColorPrimaries" = "ITU_R_709_2"
             "FormatName" = "GoPro AVC encoder"
             "SpatialQuality" = 0
             "Version" = 0
             "CVImageBufferTransferFunction" = "ITU_R_709_2"
             "CVImageBufferChromaLocationBottomField" = "Left"
             "CVPixelAspectRatio" =
             "HorizontalSpacing" = 1
             "VerticalSpacing" = 1
             "RevisionLevel" = 0
             "TemporalQuality" = 0
             "CVImageBufferYCbCrMatrix" = "ITU_R_709_2"
             "CVImageBufferChromaLocationTopField" = "Left"
             "VerbatimISOSampleEntry" = 0x000000b7617663310000000000000001 ... 0001000428ee3830
             "SampleDescriptionExtensionAtoms" =
             avcC = 0x01640029ffe1003827640029ac34c807 ... 0001000428ee3830
             "FullRangeVideo" = true
             "CVFieldCount" = 1
             "Depth" = 24
             */
            NSDictionary *dict = (__bridge NSDictionary *)CMFormatDescriptionGetExtensions(sampleBufFormat);
            encoder.spsPpsData = dict[@"SampleDescriptionExtensionAtoms"][@"avcC"];
            /*
             *  BY gitkong
             *
             *  获取sps pps 数据后可以继续进行下一步
             */
            dispatch_semaphore_signal(encoder.semaphore);
        }
    }
    
    // 获取真正的视频帧
    /*
     *  BY gitkong
     *
     *  在H.264/AVC视频编码标准中，整个系统框架被分为了两个层面：视频编码层面（VCL）和网络抽象层面（NAL）。其中，前者负责有效表示视频数据的内容，而后者则负责格式化数据并提供头信息，以保证数据适合各种信道和存储介质上的传输。因此我们平时的每帧数据就是一个NAL单元（SPS与PPS除外）。在实际的H264数据帧中，往往帧前面带有00 00 00 01 或 00 00 01分隔符，一般来说编码器编出的首帧数据为PPS与SPS，接着为I帧……
     
        H264结构中，一个视频图像编码后的数据叫做一帧，一帧由一个片（slice）或多个片组成，一个片由一个或多个宏块（MB）组成，一个宏块由16x16的yuv数据组成。宏块作为H264编码的基本单位。
     */
    /*
     *  BY gitkong
     *
     *  NAL以NALU（NAL unit）为单元来支持编码数据在基于分组交换技术网络中传输。它定义了符合传输层或存储介质要求的数据格式，同时给出头信息，从而提供了视频编码和外部世界的接口
     
        解码器可以很方便的检测出NAL的分界，依次取出NAL进行解码。但为了节省码流，H.264没有另外在NAL的头部设立表示起始位置的句法元素。如果编码数据是存储在介质上的，由于NAL是依次紧密相连的，解码器就无法在数据流中分辨出每个NAL的起始位置和终止位置。
        解决方案：在每个NAL前添加起始码：0X000001
     
        因为是实时推流，获取一个NAL数据，就传输出去，因此不需要添加0X000001，如果是存储在文件中，就需要
     */
    
    // 通过CMSampleBufferGetDataBuffer 获取视频数据缓存器，包含视频数据，The result will be NULL if the CMSampleBuffer does not contain a CMBlockBuffer, if the CMSampleBuffer contains a CVImageBuffer, or if there is some other error.
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    if (blockBuffer) {
        /*
         *  BY gitkong
         *
         *  通过 CMBlockBufferGetDataPointer 获取视频数据操作的指针，A pointer into a memory block is returned
         which corresponds to the offset within the CMBlockBuffer. The number of bytes addressable at the
         pointer can also be returned，那么如果设置
         *  第二个参数： offset， 在偏移范围内的偏移值，返回指向存储器块的指针其对应于CMBlockBuffer内的偏移，设置0不偏移
         *  第三个参数： lengthAtOffset，	On return, contains the amount of data available at the specified offset. May be NULL，就是说获取指定偏移的有效数据，设置NULL就可以
         *  第四个参数：totalLength， On return, contains the block buffer's total data length (from offset 0). May be NULL.就是block buffer 的总数据长度，从偏移为0开始算
         *  第五个参数：dataPointer，		On return, contains a pointer to the data byte at the specified offset; lengthAtOffset bytes are
         available at this address. May be NULL.就是视频数据指针,char **类型
         */
        // block buffer 的总数据长度，size_t就是unsigned int 无符号int，32位系统 4个字节
        size_t blockDataLength;
        // 视频数据指针
        size_t *blockData = nil;
        status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &blockDataLength, (char **)&blockData);
        if (status == noErr) {
            /*
             *  BY gitkong
             *
             *  当前读取到的数据位置（地址）
             */
            size_t currReadPos = 0;
            //一般情况下都是只有1帧，在最开始编码的时候有2帧，取最后一帧，此时一帧的开始使用4字节表示
            /*
             *  BY gitkong
             *
             *  int 是 4个字节，因为要取开始编码的第二帧，就是说少了一个int，4个字节，所以要减去4
             */
            while (currReadPos < blockDataLength - 4) {
                // 一个 nalu 数据的长度
                uint32_t naluLen = 0;
                // 由指向blockData + currReadPos地址的连续4个字节的数据拷贝到nalulen指向的地址中
                memcpy(&naluLen, blockData + currReadPos, 4);
                
                /*
                 *  BY gitkong
                 *
                 *  CFSwapInt32BigToHost 单字节不需要转换，32位的数量型需要对4个字节进行反转，16位的要对2个字节进行反转，将32位的整数从big-endian 转换成主机系统的endian格式（字节顺序处理方式）http://www.doc88.com/p-2905571595364.html
                 
                 *  当源和宿主系统的字节顺序处理方式是一样的话，这个函数就什么都不处理
                 */
                naluLen = CFSwapInt32BigToHost(naluLen);
                
                //naluData 即为一帧h264数据。
                //如果保存到文件中，需要将此数据前加上 [0 0 0 1] 4个字节，按顺序写入到h264文件中。
                //如果推流，需要将此数据前加上4个字节表示数据长度的数字，此数据需转为大端字节序。
                //关于大端和小端模式，请参考此网址：http://blog.csdn.net/hackbuteer1/article/details/7722667
                encoder.naluData = [NSData dataWithBytes:blockData + currReadPos + 4 length:naluLen];
                
                currReadPos += 4 + naluLen;
            }
        }
        else{
            NSLog(@"获取H264数据失败");
        }
    }
    else{
        NSLog(@"the CMSampleBuffer does not contain a CMBlockBuffer");
    }
    /*
     *  BY gitkong
     *
     *  获取sps pps 数据后可以继续进行下一步
     */
    if (encoder.spsPpsData) {
        dispatch_semaphore_signal(encoder.semaphore);
    }
    // 不管有没有naluData 都要发个信号，避免H264转flv格式的时候长时间等待
    dispatch_semaphore_signal(encoder.semaphore);
}

- (void)fl_open{
    /*
     *  BY gitkong
     *
     *  创建编码session
     */
    OSStatus status = VTCompressionSessionCreate(NULL,// 1、回话的任务分发器，传NULL使用系统默认
                                                 (int32_t)self.fl_videoConfig.fl_videoSize.width,// 2、视频宽度
                                                 (int32_t)self.fl_videoConfig.fl_videoSize.height,// 3、视频高度
                                                 kCMVideoCodecType_H264, // 4、编码类型
                                                 NULL,// 5、指定编码器，NULL使用系统默认
                                                 NULL,// 6、源像素缓冲区的必需属性，在为源帧创建像素缓冲池时使用,NULL 表示不使用系统创建的
                                                 NULL,// 7、压缩数据的分发器，传NULL使用系统
                                                 fl_VTCompressionOutputCallback,// 8、异步编码回调,The callback to be called with compressed frames.This function may be called asynchronously, on a different thread from the one that calls VTCompressionSessionEncodeFrame.
                                                 (__bridge void * _Nullable)(self),// 9、这个参数会被原封不动地传入vtCompressionSessionCallback中，此参数为编码回调同外界通信的唯一参数
                                                 &_encodeSession// 10、编码回话对象
                                                 );
    
    if (status == noErr) {
        /*
         *  BY gitkong
         *
         *  设置session属性
         */
        
        // 1、设置h264编码协议等级，不同的清晰度使用不同的ProfileLevel
        VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Main_AutoLevel);
        // 2、设置编码码率
        VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(self.fl_videoConfig.fl_bitrate));
        // 3、关闭b帧（关闭重排frame）因为有了B帧（双向预测帧，根据前后的图像计算出本帧）后，编码顺序可能跟显示顺序不同
        VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
        // 4、设置关键帧的最大间隔，值越小，压缩率越低。值越大。压缩率越高。但是掉帧后果也越明显
        VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_MaxKeyFrameInterval,(__bridge CFTypeRef)@2);
        // 5、开启实时编码
        VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        /*
         *  BY gitkong
         *
         *  准备编码
         */
        status = VTCompressionSessionPrepareToEncodeFrames(_encodeSession);
        if (status != noErr) {
            NSLog(@"准备 encode 失败");
        }
    }
    else{
        NSLog(@"创建 encode session 失败");
    }
    
}

- (void)fl_close{
    /*
     *  BY gitkong
     *
     *  发送一次信号，确保不会出现长时间等待
     */
    dispatch_semaphore_signal(self.semaphore);
    /*
     *  BY gitkong
     *
     *  销毁session，如果之前有多次retain，此时需要手动去release，否则此方法会release
     */
    VTCompressionSessionInvalidate(self.encodeSession);
    self.encodeSession = nil;
    self.naluData = nil;
    self.isKeyFrame = NO;
    self.spsPpsData = nil;
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
        /*
         *  BY gitkong
         *
         *  CVPixelBufferGetBaseAddressOfPlane 获取平面YUV数据，如果不是plane 返回NULL
         
         *  常见的YUV格式有YUY2、YUYV、YVYU、UYVY、AYUV、Y41P、Y411、Y211、IF09、IYUV、YV12、YVU9、YUV411、YUV420等。
         
         *  YUV格式通常有两大类：打包（packed）格式和平面（planar）格式。前者将YUV分量存放在同一个数组中，通常是几个相邻的像素组成一个宏像素（macro-pixel）；而后者使用三个数组分开存放YUV三个分量，就像是一个三维平面一样。YUY2到Y211都是打包格式，而IF09到YVU9都是平面格式。
         
         *  此时我们使用的是YUV420，yuv420也包含不同的数据排列格式：I420，NV12，NV21.而各种编码器最适合编码的格式还是yuv（NV12格式）。
         */
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

#pragma mark -- Setter & Getter

- (dispatch_semaphore_t)semaphore{
    if (_semaphore == nil) {
        /*
         *  BY gitkong
         *
         *  默认是没有信号量，遇到wait会一直等待，知道有signel
         */
        _semaphore = dispatch_semaphore_create(0);
    }
    return _semaphore;
}

@end
