//
//  FMCameraContext.m
//  LearnOpenGL
//
//  Created by yfm on 2021/9/18.
//

#import "FMCameraContext.h"

@implementation FMCameraContext

@synthesize context = _context;
@synthesize coreVideoTextureCache = _coreVideoTextureCache;

- (instancetype)init {
    if(self = [super init]) {
        _contextQueue = dispatch_queue_create("com.yfm.openGLESContextQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

+ (FMCameraContext *)shared {
    static FMCameraContext *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

+ (void)useImageProcessingContext {
    [[FMCameraContext shared] useAsCurrentContext];
}

- (void)useAsCurrentContext {
    EAGLContext *currentContext = [self context];
    if ([EAGLContext currentContext] != currentContext)
    {
        [EAGLContext setCurrentContext:currentContext];
    }
}

- (EAGLContext *)context {
    if (_context == nil) {
        EAGLContext *eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        _context = eaglContext;
        [EAGLContext setCurrentContext:_context];
        glDisable(GL_DEPTH_TEST);
    }
    
    return _context;
}

- (CVOpenGLESTextureCacheRef)coreVideoTextureCache {
    if (_coreVideoTextureCache == NULL) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [self context], NULL, &_coreVideoTextureCache);
        
        if (err){
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
        }
    }
    return _coreVideoTextureCache;
}

- (void)presentBufferForDisplay {
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
