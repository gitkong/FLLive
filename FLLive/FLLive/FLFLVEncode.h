//
//  FLFLVEncode.h
//  FLLive
//
//  Created by clarence on 17/3/15.
//  Copyright © 2017年 gitKong. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 *  BY gitKong
 *
 *  h264数据转flv格式，flv 格式可参考：官方文档、http://blog.csdn.net/leixiaohua1020/article/details/17934487
 */

typedef char FL_byte;
typedef unsigned int FL_int4;


#pragma mark -- Flv body 的 tag 的 header
/*
 *  BY gitKong
 *
 *  Flv body 的 tag 的 header
 */
typedef struct{
    FL_byte fl_type;// 1字节，表示tag类型，包括音频（0x08），视频（0x09），script data（0x12），其他类型值被保留,10进制表示：8、9、18
    FL_byte fl_dataSize[3];// 3个字节，表示tag 的 data的大小
    FL_byte fl_timeStamp[3];// 3个字节，表示该tag 的时间戳,就是dts：解码时间，也就是rtp包中传输的时间戳，表明解码的顺序。单位单位为1/90000 秒
    FL_byte fl_timeStamp_ex;// 1个字节，表示时间戳的拓展字节，但24位数不够的时候，该字节的时间戳为最高位时间戳拓展为32位
    FL_byte fl_streamID[3];// 3个字节，总为0
}FL_flv_body_tag_header;

#pragma mark -- Flv body 的 tag 的 data
/*
 *  BY gitKong
 *
 *  文件数据
 */
typedef struct{
    FL_byte fl_dataSize[3];//有效数据长度,对应tag header 的 fl_dataSize
    uint8_t *fl_data;//实际数据
}FL_data;

/*
 *  BY gitKong
 *
 *  Flv body 的 tag 的 audio data 的 音频参数
 */
typedef struct{
    FL_int4 fl_audioEncodeTyoe;// 4bit，音频编码类型0-15
    FL_int4 fl_sampleRate;// 2bit 音频采样率 0-5.5KHz;1-11KHz;2-22KHz;3-44KHz(For AAC: always 3)
    FL_int4 fl_precision;// 1bit 音频采样精度 (Size of each sample. This parameter only pertains to uncompressed formats. Compressed formats always decode to 16 bits internally. 0 = snd8Bit 1 = snd16Bit)
    FL_int4 fl_audioType;// 1bit 音频类型0-sndMono；1-sndStereo（Mono or stereo sound For Nellymoser: always 0 For AAC: always 1）
}FL_flv_body_tag_audio_data_params;
/*
 *  BY gitKong
 *
 *  Flv body 的 tag 的 audio data（包括音频参数、音频数据）
 */
typedef struct{
    FL_flv_body_tag_audio_data_params fl_flv_body_tag_audio_data_params;// 1个字节，包含了音频数据的参数信息
    FL_byte fl_AACPacketType;// aac 包类型，1字节，如果fl_audioEncodeTyoe==10(AAC)会有这个字段，否则没有。(0: AAC sequence header 1: AAC raw)
    FL_data *fl_config_data;//audio config data(fl_AACPacketType == 0) 包含了aac转流所需的必备内容，需要作为第一个audio tag发送。
    FL_data *fl_frame_data;// 音频数据(fl_AACPacketType == 1)
}FL_flv_body_tag_audio_data;

/*
 *  BY gitKong
 *
 *  Flv body 的 tag 的 video data 的 视频参数
 */
typedef struct{
    FL_int4 fl_frameType;// 4bit，视频帧类型1-5（1- keyframe （for AVC，a seekable frame）；2-inter frame （for AVC，a nonseekable frame）；3-disposable inter frame （H.263 only）；4-generated keyframe （reserved for server use）；5-video info/command frame）
    FL_int4 fl_videoEncodeType;// 4bit 视频编码类型1-7（1-JPEG （currently unused）；2-Sorenson H.263；3-Screen video；4-On2 VP6；5-On2 VP6 with alpha channel；6-Screen video version 2；7-AVC）
}FL_flv_body_tag_video_data_params;

/*
 *  BY gitKong
 *
 *  Flv body 的 tag 的 video data
 */
typedef struct{
    FL_flv_body_tag_video_data_params fl_flv_body_tag_video_data_params;//1字节，包含视频数据的参数信息
    FL_byte fl_AVCPacketType;// avc 包类型，1字节，0: AVC sequence header(序列头) 1: AVC NALU（NALU单元） 2: AVC end of sequence (lower level NALU sequence ender is not required or supported)（AVC 序列结束，低级AVC不需要）
    FL_byte fl_compositionTime[3];// 如果AVC fl_AVCPacketType类型是1，则为cts偏移（cts = (pts - dts) / 90 ，cts的单位是毫秒），为0则为0，
    FL_data *fl_config_data;//如果AVC fl_AVCPacketType类型是0，则是解码器配置，sps，pps 携带数据。需要在第一个video tag时发送
    FL_data *fl_data;// NALU视频数据，对应fl_AVCPacketType为1
}FL_flv_body_tag_video_data;


/*
 *  BY gitKong
 *
 *  Flv body 的 tag 的 script data（控制帧）会放一些关于FLV视频和音频的元数据信息如：duration、width、height等。通常该类型Tag会跟在File Header后面作为第一个Tag出现，而且只有一个
 */
typedef struct{
    double fl_duration;// 时长
    double fl_width;// 视频宽度
    double fl_height;// 视频高度
    double fl_video_data_rate;// 视频码率
    double fl_frame_rate;// 视频帧率
    double fl_video_codec_id;// 视频编码方式
    double fl_audio_sample_rate;// 音频采样率
    double fl_audio_sample_size;// 音频采样精度
    uint8_t fl_stereo;// 是否立体声
    double fl_audio_codec_id;// 音频编码方式
    double fl_file_size;// 文件大小
}FL_flv_body_tag_script_data;

/*
 *  BY gitKong
 *
 *  Flv Header
 */
typedef struct{
    FL_byte fl_signature[3];// UI24 文件标识，3个字节，总为"FLV"（0x46，0x4c，0x56）
    FL_byte fl_version;// UI8 版本，1个字节，目前是0x01
    FL_byte fl_flags;// UI8 1个字节，前5位保留，必须为0，第6位表示是否存在音频tag(00000100->8->0x08)，第7位保留，必须为0，第8位表示是否存在视频tag(00000001->1->0x01),都有的情况（00000101->9->0x09）
    FL_int4 fl_dataOffset;// UI32 4个字节，为从File Header 开始到 File body开始的字节数，版本1中总为9个字节(The DataOffset field usually has a value of 9 for FLV version 1. This field is present to accommodate larger headers in future versions.)
}FL_flv_header;

/*
 *  BY gitKong
 *
 *  Flv body 的 tag
 */
typedef struct{
    FL_flv_body_tag_header fl_flv_body_tag_header;// tag 的 header
    // 在union 中所有的数据成员共用一个空间，同一时间只能储存其中一个数据成员，所有的数据成员具有相同的起始地址
    union{
        FL_flv_body_tag_audio_data *fl_flv_body_tag_audio_data;
        FL_flv_body_tag_video_data *fl_flv_body_tag_video_data;
        FL_flv_body_tag_script_data *fl_flv_body_tag_script_data;
    };
}FL_flv_body_tag;

/*
 *  BY gitKong
 *
 *  Flv body
 */
typedef struct{
    FL_int4 fl_previousTagSize;// 4字节，表示前一个tag的长度
    FL_flv_body_tag *fl_flv_body_tag;// tag
}FL_flv_body;

/*
 *  BY gitKong
 *
 *  Flv data
 */
typedef struct{
    FL_flv_header fl_flv_header;// tag header
    FL_flv_body fl_flv_body;// tag body
}FL_flv_data;

typedef enum{
    FL_flv_body_tag_type_audio,
    FL_flv_body_tag_type_video,
    FL_flv_body_tag_type_script
}FL_flv_body_tag_type;

#pragma mark -- create method


