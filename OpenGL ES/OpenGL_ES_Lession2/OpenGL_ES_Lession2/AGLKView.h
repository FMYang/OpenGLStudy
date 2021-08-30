//
//  AGLKView.h
//  OpenGL_ES_Lession2
//
//  Created by yfm on 2021/6/2.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

NS_ASSUME_NONNULL_BEGIN

@class EAGLContext;
@protocol AGLKViewDelegate;

@interface AGLKView : UIView {
    GLuint defaultFrameBuffer;
    GLuint colorRenderBuffer;
}

@property (nonatomic, weak) id <AGLKViewDelegate> delegate;
@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, readonly) NSInteger drawableWidth;
@property (nonatomic, readonly) NSInteger drawableHeight;

- (void)display;

@end

#pragma mark - AGLKViewDelegate

@protocol AGLKViewDelegate <NSObject>

@required
- (void)glkView:(AGLKView *)view drawInRect:(CGRect)rect;

@end

NS_ASSUME_NONNULL_END
