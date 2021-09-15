//
//  GLProgram.h
//  GPUImage
//
//  Created by yfm on 2021/9/14.
//
//  着色器程序面向对象封装

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

NS_ASSUME_NONNULL_BEGIN

@interface GLProgram : NSObject {
    GLuint          program,
    vertShader,
    fragShader;
}

@property(readwrite, copy, nonatomic) NSString *vertexShaderLog;
@property(readwrite, copy, nonatomic) NSString *fragmentShaderLog;
@property(readwrite, copy, nonatomic) NSString *programLog;

- (id)initWithVertexShaderString:(NSString *)vShaderString
            fragmentShaderString:(NSString *)fShaderString;

- (BOOL)link;
- (void)use;
- (void)validate;

@end

NS_ASSUME_NONNULL_END
