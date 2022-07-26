//
//  ZYMetalOutputFilter.h
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/26.
//

#import "ZYMetalFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZYMetalOutputFilter : ZYMetalFilter

- (ZYMetalFrameBuffer *)getFrameBuffer;

@end

NS_ASSUME_NONNULL_END
