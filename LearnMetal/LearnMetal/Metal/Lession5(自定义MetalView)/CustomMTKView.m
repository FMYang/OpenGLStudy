//
//  CustomMTKView.m
//  LearnMetal
//
//  Created by yfm on 2022/7/8.
//

#import "CustomMTKView.h"
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>

@interface CustomMTKView() <CALayerDelegate> {
    CADisplayLink *_displayLink;
    
#if !RENDER_ON_MAIN_THREAD
    // Secondary thread containing the render loop
    NSThread *_renderThread;

    // Flag to indcate rendering should cease on the main thread
    BOOL _continueRunLoop;
#endif
}
@end

@implementation CustomMTKView

///////////////////////////////// 公共逻辑（APPKit和UIKit） ///////////////////////////////////
- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        [self initCommon];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder]) {
        [self initCommon];
    }
    return self;
}

- (void)initCommon {
    _metalLayer = (CAMetalLayer *)self.layer;
    
    self.layer.delegate = self;
}

//////////////////////////////////
#pragma mark - Render Loop Control
//////////////////////////////////

#if ANIMATION_RENDERING
- (void)dealloc {
    [self stopRenderLoop];
}

#else

#pragma mrak - CALayerDelegate

- (void)displayLayer:(CALayer *)layer {
    [self renderOnEvent];
}

- (void)drawLayer:(CALayer *)layer
        inContext:(CGContextRef)ctx {
    [self renderOnEvent];
}

- (void)drawRect:(CGRect)rect {
    [self renderOnEvent];
}

- (void)renderOnEvent {
#if RENDER_ON_MAIN_THREAD
    [self render];
#else
    // Dispatch rendering on a concurrent queue
    dispatch_queue_t globalQueue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
    dispatch_async(globalQueue, ^(){
        [self render];
    });
#endif
}

#endif // END !ANIMAITON_RENDERING

///////////////////////
#pragma mark - Resizing
///////////////////////

#if AUTOMATICALLY_RESIZE

- (void)resizeDrawable:(CGFloat)scaleFactor {
    CGSize newSize = self.bounds.size;
    newSize.width *= scaleFactor;
    newSize.height *= scaleFactor;
    
    if(newSize.width <= 0 || newSize.height <= 0) {
        return;
    }
    
#if RENDER_ON_MAIN_THREAD
    if(newSize.width == _metalLayer.drawableSize.width &&
       newSize.height == _metalLayer.drawableSize.height) {
        return;
    }
    
    _metalLayer.drawableSize = newSize;
    
    [_delegate drawableResize:newSize];
#else
    // All AppKit and UIKit calls which notify of a resize are called on the main thread.  Use
    // a synchronized block to ensure that resize notifications on the delegate are atomic
    @synchronized(_metalLayer)
    {
        if(newSize.width == _metalLayer.drawableSize.width &&
           newSize.height == _metalLayer.drawableSize.height)
        {
            return;
        }

        _metalLayer.drawableSize = newSize;

        [_delegate drawableResize:newSize];
    }
#endif
}

#endif

//////////////////////
#pragma mark - Drawing
//////////////////////

- (void)render {
#if RENDER_ON_MAIN_THREAD
    [_delegate renderToMetalLayer:_metalLayer];
#else
    @synchronized (_metalLayer) {
        [_delegate renderToMetalLayer:_metalLayer];
    }
#endif
}



////////////////////////////////// UIKit //////////////////////////////////
+ (Class)layerClass {
    return CAMetalLayer.class;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    
#if ANIMATION_RENDERING
    if(self.window == nil) {
        [_displayLink invalidate];
        _displayLink = nil;
        return;
    }
    
    [self setupCADisplayLinkForScreen:self.window.screen];
    
#if RENDER_ON_MAIN_THREAD
    
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
#else // IF !RENDER_ON_MAIN_THREAD
    
    @synchronized (self) {
        _continueRunLoop = NO;
    }
    
    _renderThread =  [[NSThread alloc] initWithTarget:self selector:@selector(runThread) object:nil];
    _continueRunLoop = YES;
    [_renderThread start];

#endif // END !RENDER_ON_MAIN_THREAD
#endif // ANIMATION_RENDERING
    
#if AUTOMATICALLY_RESIZE
    [self resizeDrawable:self.window.screen.nativeScale];
#else
    // Notify delegate of default drawable size when it can be calculated
    CGSize defaultDrawableSize = self.bounds.size;
    defaultDrawableSize.width *= self.layer.contentsScale;
    defaultDrawableSize.height *= self.layer.contentsScale;
    [self.delegate drawableResize:defaultDrawableSize];
#endif
}

//////////////////////////////////
#pragma mark - Render Loop Control
//////////////////////////////////

#if ANIMATION_RENDERING

- (void)setPaused:(BOOL)paused {
    _paused = paused;
    
    _displayLink.paused = paused;
}

- (void)setupCADisplayLinkForScreen:(UIScreen *)screen {
    [self stopRenderLoop];
    
    _displayLink = [screen displayLinkWithTarget:self selector:@selector(render)];
    
    _displayLink.paused = self.paused;
    
    _displayLink.preferredFramesPerSecond = 60;
}

- (void)didEnterBackground:(NSNotification*)notification
{
    self.paused = YES;
}

- (void)willEnterForeground:(NSNotification*)notification
{
    self.paused = NO;
}

- (void)stopRenderLoop {
    [_displayLink invalidate];
}

#if !RENDER_ON_MAIN_THREAD
- (void)runThread {
    NSRunLoop *runloop = [NSRunLoop currentRunLoop];
    [_displayLink addToRunLoop:runloop forMode:@"AAPLDisplayLinkMode"];
    
    BOOL continueRunLoop = YES;
    
    while (continueRunLoop) {
        @autoreleasepool {
            [runloop runMode:@"AAPLDisplayLinkMode" beforeDate:[NSDate distantFuture]];
        }
        
        @synchronized (self) {
            continueRunLoop = _continueRunLoop;
        }
    }
}
#endif

#endif

#if AUTOMATICALLY_RESIZE

- (void)setContentScaleFactor:(CGFloat)contentScaleFactor {
    [self resizeDrawable:self.window.screen.nativeScale];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self resizeDrawable:self.window.screen.nativeScale];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self resizeDrawable:self.window.screen.nativeScale];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self resizeDrawable:self.window.screen.nativeScale];
}

#endif

@end
