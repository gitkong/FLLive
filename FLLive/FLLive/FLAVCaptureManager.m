//
//  FLAVCaptureManager.m
//  FLLive
//
//  Created by clarence on 17/3/1.
//  Copyright © 2017年 gitKong. All rights reserved.
//

#import "FLAVCaptureManager.h"

@interface FLAVCaptureManager ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
@property (nonatomic,strong)AVCaptureSession *session;
// input
@property (nonatomic,strong)AVCaptureDeviceInput *fontCaptureInput;
@property (nonatomic,strong)AVCaptureDeviceInput *backCaptureInput;
@property (nonatomic,weak)AVCaptureDeviceInput *videoCaptureInput;
@property (nonatomic,strong)AVCaptureDeviceInput *audioCaptureInput;

// output
@property (nonatomic,strong)AVCaptureVideoDataOutput *videoCaptureOutput;
@property (nonatomic,strong)AVCaptureAudioDataOutput *audioCaptureOutput;
@end

@implementation FLAVCaptureManager

- (instancetype)init{
    if (self = [super init]) {
        // check auth
        [self fl_checkAuth];
        
    }
    return self;
}

- (instancetype)initWithVideoConfig:(FLVideoConfig *)videoConfig audioConfig:(FLAudioConfig *)audioConfig{
    if (self = [super init]) {
        
    }
    return self;
}

- (void)fl_defaultConfig{
    self.fl_isFont = YES;
}

/**
 *  @author gitKong
 *
 *  check user authorize，if already auth，then init capture
 */
- (void)fl_checkAuth{
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized:{
            // already authorize,init capture session
            [self fl_initCaptureSession];
            break;
        }
        case AVAuthorizationStatusNotDetermined:{
            // waiting user to authorize
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    [self fl_initCaptureSession];
                }
                else{
                    [self fl_showAuthTip];
                }
            }];
            break;
        }
        default:
            [self fl_showAuthTip];
            break;
    }
}

/**
 *  @author gitKong
 *
 *  init capture session to manage video & audio events(input & output)
 */
- (void)fl_initCaptureSession{
    self.session = [[AVCaptureSession alloc] init];
    [self.session beginConfiguration];
    
    // setting input & output config
    [self fl_initCaptureInput];
    [self fl_initCaptureOutput];
    [self fl_initCapturePreset:AVCaptureSessionPresetHigh];
    [self.session commitConfiguration];
    [self fl_defaultConfig];
    [self.session startRunning];
    // setting fps
    [self fl_updateFps:self.fl_videoConfig.fl_fps];
}


/**
 *  @author gitKong
 *
 *  init capture device，camera capture position、inputDevice
 */
- (void)fl_initCaptureInput{
    // get all videoDevices
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    // init video input
    self.fontCaptureInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.firstObject error:&error];
    self.backCaptureInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.lastObject error:&error];
    self.videoCaptureInput = self.fontCaptureInput;
    // init audio input
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    self.audioCaptureInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    
    // add input
    if ([self.session canAddInput:self.videoCaptureInput]) {
        [self.session addInput:self.videoCaptureInput];
    }
    if ([self.session canAddInput:self.audioCaptureInput]) {
        [self.session addInput:self.audioCaptureInput];
    }
    
}

/**
 *  @author gitKong
 *
 *  init capture output, send out "YUV" data for video,"PCM" data for audio
 */
- (void)fl_initCaptureOutput{
    self.videoCaptureOutput = [[AVCaptureVideoDataOutput alloc] init];
    // default queue
    dispatch_queue_t outputCaptureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    // init video output
    [self.videoCaptureOutput setSampleBufferDelegate:self queue:outputCaptureQueue];
    // discard late video frames
    self.videoCaptureOutput.alwaysDiscardsLateVideoFrames = YES;
    // setting video output data format (YUV or RGB) , the only supported key is kCVPixelBufferPixelFormatTypeKey. Supported pixel formats are kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange and kCVPixelFormatType_32BGRA.
    [self.videoCaptureOutput setVideoSettings:@{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)}];
    // setting video output config
    [self fl_videoOutputConfig];
    
    // init audio output
    self.audioCaptureOutput = [[AVCaptureAudioDataOutput alloc] init];
    [self.audioCaptureOutput setSampleBufferDelegate:self queue:outputCaptureQueue];
    
    // add output
    if ([self.session canAddOutput:self.videoCaptureOutput]) {
        [self.session addOutput:self.videoCaptureOutput];
    }
    if ([self.session canAddOutput:self.audioCaptureOutput]) {
        [self.session addOutput:self.audioCaptureOutput];
    }
    
}

- (void)fl_videoOutputConfig{
    
    for (AVCaptureConnection *connection in self.videoCaptureOutput.connections) {
        // setting preffer stabilizationMode to prevent shaking.防抖动
        if (connection.isVideoStabilizationSupported) {
            [connection setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeAuto];
        }
        // whether the video flowing through the connection should be rotated to a given orientation.视频旋转到给定方向
        if (connection.isVideoOrientationSupported) {
            [connection setVideoOrientation:self.fl_videoConfig.fl_videoOrientation ? self.fl_videoConfig.fl_videoOrientation : AVCaptureVideoOrientationPortrait];
        }
        // whether the video flowing through the connection should be mirrored about its vertical axis.视频是否应围绕其垂直轴进行镜像
        if (connection.isVideoMirroringSupported) {
            [connection setVideoMirrored:NO];
        }
    }
}

- (void)fl_initCapturePreset:(NSString *)captureSessionPreset{
    if (![self.session canSetSessionPreset:captureSessionPreset]) {
        @throw [NSException exceptionWithName:@"Not supported captureSessionPreset" reason:[NSString stringWithFormat:@"captureSessionPreset is [%@]",captureSessionPreset] userInfo:nil];
//        NSLog(@"Not supported captureSessionPreset:%@",[NSString stringWithFormat:@"captureSessionPreset is [%@]",captureSessionPreset]);
    }
    self.session.sessionPreset = captureSessionPreset;
}


#pragma mark -- Setter & Getter

- (void)setFl_isFont:(BOOL)fl_isFont{
    if (_fl_isFont == fl_isFont) {
        return;
    }
    if (!fl_isFont) {
        self.videoCaptureInput = self.fontCaptureInput;
    }
    else{
        self.videoCaptureInput = self.backCaptureInput;
    }
    [self fl_updateFps:self.fl_videoConfig.fl_fps];
    _fl_isFont = fl_isFont;
}

- (void)setVideoCaptureInput:(AVCaptureDeviceInput *)videoCaptureInput{
    if ([_videoCaptureInput isEqual:videoCaptureInput]) {
        return;
    }
    [self.session beginConfiguration];
    if (_videoCaptureInput) {
        [self.session removeInput:_videoCaptureInput];
    }
    if ([self.session canAddInput:videoCaptureInput]) {
        [self.session addInput:videoCaptureInput];
    }
    // reset config because add new input
    [self fl_videoOutputConfig];
    
    [self.session commitConfiguration];
    
    _videoCaptureInput = videoCaptureInput;
}


- (void)setFl_captureSessionPreset:(FLCaptureSessionPreset)fl_captureSessionPreset{
    _fl_captureSessionPreset = fl_captureSessionPreset;
    NSString *captureSessionPreset = nil;
    switch (fl_captureSessionPreset) {
        case FLCaptureSessionPreset_High:
            captureSessionPreset = AVCaptureSessionPresetHigh;
            break;
        case FLCaptureSessionPreset_Medium:
            captureSessionPreset = AVCaptureSessionPresetMedium;
            break;
        case FLCaptureSessionPreset_Low:
            captureSessionPreset = AVCaptureSessionPresetLow;
            break;
        case FLCaptureSessionPreset_352x288:
            captureSessionPreset = AVCaptureSessionPreset352x288;
            break;
        case FLCaptureSessionPreset_960x540:
            captureSessionPreset = AVCaptureSessionPresetiFrame960x540;
        case FLCaptureSessionPreset_1280x720:
            captureSessionPreset = AVCaptureSessionPreset1280x720;
            break;
        case FLCaptureSessionPreset_1920x1080:
            captureSessionPreset = AVCaptureSessionPreset1920x1080;
            break;
        case FLCaptureSessionPreset_3840x2160:
            captureSessionPreset = AVCaptureSessionPreset3840x2160;
            break;
        default:
            break;
    }
    [self.session beginConfiguration];
    // reset preset
    [self fl_initCapturePreset:captureSessionPreset];
    [self.session commitConfiguration];
}

- (void)setFl_previewView:(UIView *)fl_previewView{
    _fl_previewView = fl_previewView;
    AVCaptureVideoPreviewLayer *layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.frame = fl_previewView.bounds;
    [fl_previewView.layer addSublayer:layer];
}

- (void)fl_deatroySession{
    if (self.session) {
        if ([self.session isRunning]) {
            [self.session stopRunning];
        }
        [self.audioCaptureOutput setSampleBufferDelegate:nil queue:dispatch_get_main_queue()];
        [self.videoCaptureOutput setSampleBufferDelegate:nil queue:dispatch_get_main_queue()];
        [self.session removeInput:self.videoCaptureInput];
        [self.session removeInput:self.audioCaptureInput];
        [self.session removeOutput:self.videoCaptureOutput];
        [self.session removeOutput:self.audioCaptureOutput];
    }
    self.session = nil;
}

#pragma mark -- AVCaptureVideoDataOutputSampleBufferDelegate
/**
 *  @author gitKong
 *
 *  output callback
 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    // 这里获取到 sampleBuffer 就要转换成 yuv 格式数据（通过CMSampleBufferGetImageBuffer）
}

#pragma mark -- private method

//修改fps
-(void)fl_updateFps:(NSInteger) fps{
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *vDevice in videoDevices) {
        float maxRate = [(AVFrameRateRange *)[vDevice.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0] maxFrameRate];
        if (maxRate >= fps) {
            if ([vDevice lockForConfiguration:NULL]) {
                // CMTimeMake(a,b)    a当前第几帧, b每秒钟多少帧.当前播放时间a/b
                vDevice.activeVideoMinFrameDuration = CMTimeMake(1, (int)fps);
                vDevice.activeVideoMaxFrameDuration = vDevice.activeVideoMinFrameDuration;
                [vDevice unlockForConfiguration];
            }
        }
    }
}
/**
 *  @author gitKong
 *
 *  show tip for user auth
 */
- (void)fl_showAuthTip{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"您还没开启授权，请打开--> 设置 -- > 隐私 --> 通用等权限设置" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}


@end
