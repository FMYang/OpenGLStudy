//
//  GPUImageColorConversion.h
//  GPUImage
//
//  Created by yfm on 2021/9/15.
//

#ifndef GPUImageColorConversion_h
#define GPUImageColorConversion_h

extern GLfloat *kColorConversion601;
extern GLfloat *kColorConversion601FullRange;
extern GLfloat *kColorConversion709;
extern NSString *const kGPUImageYUVVideoRangeConversionForRGFragmentShaderString;
extern NSString *const kGPUImageYUVFullRangeConversionForLAFragmentShaderString;
extern NSString *const kGPUImageYUVVideoRangeConversionForLAFragmentShaderString;

#endif

