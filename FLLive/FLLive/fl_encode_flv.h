//
//  fl_encode_flv.h
//  FLLive
//
//  Created by clarence on 17/3/14.
//  Copyright © 2017年 gitKong. All rights reserved.
//

#ifndef fl_encode_flv_h
#define fl_encode_flv_h

#include <stdio.h>
/*
 *  BY gitKong
 *
 *  h264数据转flv格式，flv 格式可参考：http://blog.csdn.net/leixiaohua1020/article/details/17934487
 */

typedef char FL_byte;
typedef unsigned int FL_int4;

/*
 *  BY gitKong
 *
 *  Flv Header
 */
typedef struct{
    FL_byte fl_signature[3];// 文件标识，3个字节，总为"FLV"（0x46，0x4c，0x66）
    FL_byte fl_version;// 版本，1个字节，目前是0x01
    FL_byte fl_flags;// 1个字节，前5位保留，必须为0，第6位表示是否存在音频tag，第7位保留，必须为0，第8位表示是否存在视频tag
    FL_int4 fl_headerSize;// 4个字节，为从File Header 开始到 File body开始的字节数，版本1中总为9个字节
}FL_flv_header;

/*
 *  BY gitKong
 *
 *  Flv body
 */
typedef struct{
    FL_int4 fl_previousTagSize;//
    FL_flv_body_tag fl_flv_body_tag;
}FL_flv_body;

/*
 *  BY gitKong
 *
 *  Flv body 的 tag
 */
typedef struct{
    FL_flv_body_tag_header fl_flv_body_tag_header;// tag 的 header
    // 在union 中所有的数据成员共用一个空间，同一时间只能储存其中一个数据成员，所有的数据成员具有相同的起始地址
    union{
        FL_flv_body_tag_audio_data fl_flv_body_tag_audio_data;
        FL_flv_body_tag_video_data fl_flv_body_tag_video_data;
        FL_flv_body_tag_script_data fl_flv_body_tag_script_data;
    };
}FL_flv_body_tag;

#pragma mark -- Flv body 的 tag 的 header
/*
 *  BY gitKong
 *
 *  Flv body 的 tag 的 header
 */
typedef struct{
    FL_byte fl_type;// 1字节，表示tag类型，包括音频（0x08），视频（0x09），script data（0x12），其他类型值被保留
    FL_byte fl_dataSize[3];// 3个字节，表示tag 的 data的大小
    FL_byte fl_timeStamp[3];// 3个字节，表示该tag 的时间戳
    FL_byte fl_timeStamp_ex;// 1个字节，表示时间戳的拓展字节，但24位数不够的时候，该字节的时间戳为最高位时间戳拓展为32位
    FL_byte fl_streamID[3];// 3个字节，总为0
    
}FL_flv_body_tag_header;

#pragma mark -- Flv body 的 tag 的 data
/*
 *  BY gitKong
 *
 *  Flv body 的 tag 的 audio data（包括音频参数、音频数据）
 */
typedef struct{
    FL_flv_body_tag_audio_data_params fl_flv_body_tag_audio_data_params;// 1个字节，包含了音频数据的参数信息
    FL_data *fl_data;// 音频数据
}FL_flv_body_tag_audio_data;

/*
 *  BY gitKong
 *
 *  Flv body 的 tag 的 audio data 的 音频参数
 */
typedef struct{
    FL_int4 fl_audioEncodeTyoe;// 4bit，音频编码类型0-15
    FL_int4 fl_sampleRate;// 2bit 采样率0-3
    FL_int4 fl_precision;// 1bit 精度0-1
    FL_int4 fl_precision;// 1bit 音频类型0-1
}FL_flv_body_tag_audio_data_params;

/*
 *  BY gitKong
 *
 *  Flv body 的 tag 的 video data
 */
typedef struct{
    FL_flv_body_tag_video_data_params fl_flv_body_tag_video_data_params;//1字节，包含视频数据的参数信息
    FL_data *fl_data;// 视频数据
}FL_flv_body_tag_video_data;

/*
 *  BY gitKong
 *
 *  Flv body 的 tag 的 video data 的 视频参数
 */
typedef struct{
    FL_int4 fl_frameType;// 4bit，视频帧类型1-5
    FL_int4 fl_videoEncodeType;// 4bit 视频编码类型1-7
}FL_flv_body_tag_video_data_params;

/*
 *  BY gitKong
 *
 *  Flv body 的 tag 的 script data
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
 *  文件数据
 */
typedef struct{
    uint32_t fl_size;//有效数据长度
    uint32_t fl_alloc_size;//分配的数据长度
    uint32_t fl_curr_pos;//读取或写入的位置
    uint8_t *fl_data;//实际数据
}FL_data;

#endif /* fl_encode_flv_h */
