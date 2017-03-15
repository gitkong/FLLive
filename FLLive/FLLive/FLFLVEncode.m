//
//  FLFLVEncode.m
//  FLLive
//
//  Created by clarence on 17/3/15.
//  Copyright © 2017年 gitKong. All rights reserved.
//

#import "FLFLVEncode.h"

#pragma mark -- flv header create
FL_flv_header *fl_flv_header_create(){
    FL_flv_header *fl_flv_header = (FL_flv_header *)malloc(sizeof(FL_flv_header));
    memset(fl_flv_header, 0, sizeof(FL_flv_header));
    fl_flv_header->fl_signature[0] = 0x46;
    fl_flv_header->fl_signature[1] = 0x4c;
    fl_flv_header->fl_signature[2] = 0x56;
    fl_flv_header->fl_version = 0x01;
    fl_flv_header->fl_flags = 0x01;
    fl_flv_header->fl_dataOffset = 0x09;
    return fl_flv_header;
}

#pragma mark -- flv body create
/*
 *  BY gitkong
 *
 *  private method - create flv_body_tag_audio_data
 */
FL_flv_body_tag_audio_data *fl_flv_body_tag_audio_data_create(FL_data *fl_data,
                                                              FL_byte fl_AACPacketType){
    FL_flv_body_tag_audio_data *fl_flv_body_tag_audio_data = (FL_flv_body_tag_audio_data *)malloc(sizeof(FL_flv_body_tag_audio_data));
    memset(fl_flv_body_tag_audio_data, 0, sizeof(FL_flv_body_tag_audio_data));
    
    FL_flv_body_tag_audio_data_params fl_flv_body_tag_audio_data_params;
    fl_flv_body_tag_audio_data_params.fl_audioType = 0x01;
    fl_flv_body_tag_audio_data_params.fl_audioEncodeTyoe = 0x16;// 10-AAC
    fl_flv_body_tag_audio_data_params.fl_precision = 0x01;//音频采样精度 0-8bits;1-16bits
    fl_flv_body_tag_audio_data_params.fl_sampleRate = 0x00;// 音频采样率 0-5.5KHz;1-11KHz;2-22KHz;3-44KHz
    fl_flv_body_tag_audio_data->fl_flv_body_tag_audio_data_params = fl_flv_body_tag_audio_data_params;
    /*
     *  BY gitkong
     *
     *  0: AAC sequence header 首次发送必须是fl_config_data
     */
    if (fl_flv_body_tag_audio_data->fl_AACPacketType == 0x00) {
        fl_flv_body_tag_audio_data->fl_config_data = fl_data;
    }
    else{
        fl_flv_body_tag_audio_data->fl_frame_data = fl_data;
    }
    return fl_flv_body_tag_audio_data;
}

/*
 *  BY gitkong
 *
 *  private method - create flv_body_tag_video_data
 */
FL_flv_body_tag_video_data *fl_flv_body_tag_video_data_create(FL_data *fl_data,
                                                              FL_int4 fl_frameType,
                                                              FL_byte fl_AVCPacketType,
                                                              FL_byte fl_compositionTime[3]){
    FL_flv_body_tag_video_data *fl_flv_body_tag_video_data = (FL_flv_body_tag_video_data *)malloc(sizeof(FL_flv_body_tag_video_data));
    memset(fl_flv_body_tag_video_data, 0, sizeof(FL_flv_body_tag_video_data));
    
    FL_flv_body_tag_video_data_params fl_flv_body_tag_video_data_params;
    fl_flv_body_tag_video_data_params.fl_frameType = fl_frameType;
    fl_flv_body_tag_video_data_params.fl_videoEncodeType = 0x07;// AVC
    
    fl_flv_body_tag_video_data->fl_flv_body_tag_video_data_params = fl_flv_body_tag_video_data_params;
    if (fl_AVCPacketType == 0x00) {//AVC序列头
        fl_flv_body_tag_video_data->fl_config_data = fl_data;
        // cts 为 0
        memset(fl_flv_body_tag_video_data->fl_compositionTime, 0, 3 * sizeof(FL_byte));
    }
    else if (fl_AVCPacketType == 0x01){// AVC NALU单元
        fl_flv_body_tag_video_data->fl_data = fl_data;
        // cts
        memcpy(fl_flv_body_tag_video_data->fl_compositionTime, fl_compositionTime, 3 * sizeof(FL_byte));
    }
    else{
        fl_flv_body_tag_video_data->fl_data = NULL;
        // cts 为 0
        memset(fl_flv_body_tag_video_data->fl_compositionTime, 0, 3 * sizeof(FL_byte));
    }
    return fl_flv_body_tag_video_data;
}

/*
 *  BY gitkong
 *
 *  private method - create flv_body_tag_script_data
 */
FL_flv_body_tag_script_data *fl_flv_body_tag_script_data_create(double fl_duration,
                                                                double fl_width,
                                                                double fl_height,
                                                                double fl_video_data_rate,
                                                                double fl_frame_rate,
                                                                double fl_video_codec_id,
                                                                double fl_audio_sample_rate,
                                                                double fl_audio_sample_size,
                                                                uint8_t fl_stereo,
                                                                double fl_audio_codec_id,
                                                                double fl_file_size){
    FL_flv_body_tag_script_data *fl_flv_body_tag_script_data = (FL_flv_body_tag_script_data *)malloc(sizeof(FL_flv_body_tag_script_data));
    memset(fl_flv_body_tag_script_data, 0, sizeof(FL_flv_body_tag_script_data));
    
    fl_flv_body_tag_script_data->fl_duration = fl_duration;
    fl_flv_body_tag_script_data->fl_width = fl_width;
    fl_flv_body_tag_script_data->fl_height = fl_height;
    fl_flv_body_tag_script_data->fl_video_data_rate = fl_video_data_rate;
    fl_flv_body_tag_script_data->fl_frame_rate = fl_frame_rate;
    fl_flv_body_tag_script_data->fl_video_codec_id = fl_video_codec_id;
    fl_flv_body_tag_script_data->fl_audio_sample_rate = fl_audio_sample_rate;
    fl_flv_body_tag_script_data->fl_audio_sample_size = fl_audio_sample_size;
    fl_flv_body_tag_script_data->fl_stereo = fl_stereo;
    fl_flv_body_tag_script_data->fl_audio_codec_id = fl_audio_codec_id;
    fl_flv_body_tag_script_data->fl_file_size = fl_file_size;
    
    return fl_flv_body_tag_script_data;
}

/*
 *  BY gitkong
 *
 *  private base method - create flv_body_tag
 */
FL_flv_body_tag *fl_flv_body_tag_create(FL_flv_body_tag_type fl_flv_body_tag_type,
                                        FL_data *fl_data,
                                        FL_byte fl_timeStamp[3],
                                        FL_int4 fl_frameType){
    FL_flv_body_tag *fl_flv_body_tag = (FL_flv_body_tag *)malloc(sizeof(FL_flv_body_tag));
    memset(fl_flv_body_tag, 0, sizeof(FL_flv_body_tag));
    /*
     *  BY gitkong
     *
     *  设置tag header
     */
    FL_flv_body_tag_header fl_flv_body_tag_header;
    // tag data 的数据大小
    memcpy(fl_flv_body_tag_header.fl_dataSize, fl_data->fl_dataSize, 3 * sizeof(FL_byte));
    // ID 一定为 0
    memset(fl_flv_body_tag_header.fl_streamID, 0, 3 * sizeof(FL_byte));
    // 时间戳
    memcpy(fl_flv_body_tag_header.fl_timeStamp, fl_timeStamp, sizeof(fl_flv_body_tag_header.fl_timeStamp));
    
    switch (fl_flv_body_tag_type) {
        case FL_flv_body_tag_type_audio:{
            // header 类型
            fl_flv_body_tag_header.fl_type = 0x08;
            break;
        }
        case FL_flv_body_tag_type_video:{
            fl_flv_body_tag_header.fl_type = 0x09;
            break;
        }
        case FL_flv_body_tag_type_script:{
            fl_flv_body_tag_header.fl_type = 0x12;
            break;
        }
    }
    return fl_flv_body_tag;
}

/*
 *  BY gitkong
 *
 *  创建audio tag
 */
FL_flv_body_tag *fl_flv_body_audio_tag_create(FL_data *fl_data,
                                              FL_byte fl_timeStamp[3],
                                              FL_int4 fl_frameType,
                                              FL_byte fl_AACPacketType){
    FL_flv_body_tag *fl_flv_body_tag = fl_flv_body_tag_create(FL_flv_body_tag_type_audio, fl_data, fl_timeStamp, fl_frameType);
    fl_flv_body_tag->fl_flv_body_tag_audio_data = fl_flv_body_tag_audio_data_create(fl_data,fl_AACPacketType);
    return fl_flv_body_tag;
}

/*
 *  BY gitkong
 *
 *  创建 video tag
 */
FL_flv_body_tag *fl_flv_body_video_tag_create(FL_data *fl_data,
                                              FL_byte fl_timeStamp[3],
                                              FL_int4 fl_frameType,
                                              FL_byte fl_AVCPacketType,
                                              FL_byte fl_compositionTime[3]){
    FL_flv_body_tag *fl_flv_body_tag = fl_flv_body_tag_create(FL_flv_body_tag_type_video, fl_data, fl_timeStamp, fl_frameType);
    fl_flv_body_tag->fl_flv_body_tag_video_data = fl_flv_body_tag_video_data_create(fl_data, fl_frameType, fl_AVCPacketType,fl_compositionTime);
    return fl_flv_body_tag;
}

/*
 *  BY gitkong
 *
 *  创建 script tag
 */
FL_flv_body_tag *fl_flv_body_script_tag_create(FL_data *fl_data,
                                               FL_byte fl_timeStamp[3],
                                               FL_int4 fl_frameType,
                                               double fl_duration,
                                               double fl_width,
                                               double fl_height,
                                               double fl_video_data_rate,
                                               double fl_frame_rate,
                                               double fl_video_codec_id,
                                               double fl_audio_sample_rate,
                                               double fl_audio_sample_size,
                                               uint8_t fl_stereo,
                                               double fl_audio_codec_id,
                                               double fl_file_size){
    FL_flv_body_tag *fl_flv_body_tag = fl_flv_body_tag_create(FL_flv_body_tag_type_script, fl_data, fl_timeStamp, fl_frameType);
    fl_flv_body_tag->fl_flv_body_tag_script_data = fl_flv_body_tag_script_data_create(fl_duration,fl_width,fl_height,fl_video_data_rate,fl_frame_rate,fl_audio_codec_id,fl_audio_sample_rate,fl_audio_sample_size,fl_stereo,fl_audio_codec_id,fl_file_size);
    return fl_flv_body_tag;
}


FL_flv_body *fl_flv_body_create(FL_int4 fl_previousTagSize,
                                       FL_flv_body_tag_type fl_flv_body_tag_type,
                                       FL_data *fl_data,
                                       FL_byte fl_timeStamp[3],
                                       FL_int4 fl_frameType){
    FL_flv_body *fl_flv_body = (FL_flv_body *)malloc(sizeof(FL_flv_body));
    memset(fl_flv_body, 0, sizeof(FL_flv_body));
    fl_flv_body->fl_previousTagSize = fl_previousTagSize;
    fl_flv_body->fl_flv_body_tag = fl_flv_body_tag_create(fl_flv_body_tag_type,fl_data,fl_timeStamp,fl_frameType);
    return fl_flv_body;
}

