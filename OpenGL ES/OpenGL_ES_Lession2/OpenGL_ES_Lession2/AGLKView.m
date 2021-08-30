//
//  AGLKView.m
//  OpenGL_ES_Lession2
//
//  Created by yfm on 2021/6/2.
//

#import "AGLKView.h"

@implementation AGLKView

@synthesize context = _context;

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame context:(EAGLContext *)aContext {
    if(self = [super initWithFrame:frame]) {
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        
        self.context = aContext;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder]) {
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    }
    return self;
}

- (void)setContext:(EAGLContext *)aContext {
    if(_context != aContext) {
        [EAGLContext setCurrentContext:_context];
        
        if(0 != defaultFrameBuffer) {
            glDeleteFramebuffers(1, &defaultFrameBuffer);
            defaultFrameBuffer = 0;
        }
        
        _context = aContext;
        
        if(nil != _context) {
            _context = aContext;
            [EAGLContext setCurrentContext:_context];
            
            glGenFramebuffers(1, &defaultFrameBuffer);
            glBindFramebuffer(GL_FRAMEBUFFER, defaultFrameBuffer);
            
            glGenRenderbuffers(1, &colorRenderBuffer);
            glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);
            
            glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderBuffer);
        }
    }
}

- (EAGLContext *)context {
    return _context;
}

- (void)display {
    [EAGLContext setCurrentContext:self.context];
    glViewport(0, 0, self.drawableWidth, self.drawableHeight);
    
    [self drawRect:self.bounds];
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)drawRect:(CGRect)rect {
    if(self.delegate) {
        [self.delegate glkView:self drawInRect:self.bounds];
    }
}

- (void)layoutSubviews {
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
    
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    if(status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"failed to make complete frame buffer object: %x", status);
    }
}

- (NSInteger)drawableWidth {
    GLint backingWidth;
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    
    return (NSInteger)backingWidth;
}

- (NSInteger)drawableHeight {
    GLint backingHeight;
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    return (NSInteger)backingHeight;
}

- (void)dealloc {
    if([EAGLContext currentContext] == _context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    _context = nil;
}

@end
