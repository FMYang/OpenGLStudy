//
//  ZYMetalDevice.m
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/14.
//

#import "ZYMetalDevice.h"

@implementation ZYMetalDevice
@synthesize textureCache = _textureCache;
@synthesize commandQueue = _commandQueue;
@synthesize device = _device;
@synthesize library = _library;

+ (ZYMetalDevice *)shared {
    static ZYMetalDevice *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if(self = [super init]) {
        _device = MTLCreateSystemDefaultDevice();
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, _device, nil, &_textureCache);
        _commandQueue = [_device newCommandQueue];
        _library = [_device newDefaultLibrary];
    }
    return self;
}

@end
