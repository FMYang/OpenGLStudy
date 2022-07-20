//
//  FMMetalView.h
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/20.
//

#import <MetalKit/MetalKit.h>
#import "ZYMetalContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface FMMetalView : MTKView <ZYMetalInput>

@end

NS_ASSUME_NONNULL_END
