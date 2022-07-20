//
//  ZYCustomFilter.h
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/13.
//

#import "ZYMetalBaseFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZYCustomFilter : ZYMetalBaseFilter <ZYMetalFilterRenderCommand>

@property (nonatomic, readonly) NSString *functionName;

@end

NS_ASSUME_NONNULL_END
