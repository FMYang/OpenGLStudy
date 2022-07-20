//
//  ZYMetalFilter.h
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/20.
//

#import <Foundation/Foundation.h>
#import "ZYMetalOutput.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZYMetalFilter : ZYMetalOutput <ZYMetalInput> 

- (void)push:(CVPixelBufferRef)pixelBuffer frameTime:(CMTime)frameTime;

- (id)initWithFragmentFunction:(NSString *)function;

@end

NS_ASSUME_NONNULL_END
