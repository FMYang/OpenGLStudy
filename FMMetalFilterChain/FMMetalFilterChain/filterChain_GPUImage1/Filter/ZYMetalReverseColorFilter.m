//
//  ZYMetalReverseColorFilter.m
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/20.
//

#import "ZYMetalReverseColorFilter.h"

@implementation ZYMetalReverseColorFilter

- (instancetype)init {
    if(self = [super initWithFragmentFunction:@"reverseColorFragmentShader"]) {
        
    }
    return self;
}

@end
