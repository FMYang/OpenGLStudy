//
//  ZYMetalGrayFilter1.m
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/20.
//

#import "ZYMetalGrayFilter1.h"

@implementation ZYMetalGrayFilter1

- (instancetype)init {
    if(self = [super initWithFragmentFunction:@"grayFilterFragmentShader"]) {
        
    }
    return self;
}

@end
