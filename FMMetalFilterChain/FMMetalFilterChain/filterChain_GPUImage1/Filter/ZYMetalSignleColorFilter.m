//
//  ZYMetalSignleColorFilter.m
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/26.
//

#import "ZYMetalSignleColorFilter.h"

@implementation ZYMetalSignleColorFilter

- (instancetype)init {
    if(self = [super initWithFragmentFunction:@"singleColorFilterFragmentShader"]) {
        
    }
    return self;
}

@end
