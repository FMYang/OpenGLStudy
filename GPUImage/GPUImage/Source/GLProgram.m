//
//  GLProgram.m
//  GPUImage
//
//  Created by yfm on 2021/9/14.
//

#import "GLProgram.h"

@interface GLProgram()

- (BOOL)compileShader:(GLuint *)shader
                 type:(GLenum)type
               string:(NSString *)shaderString;

@end

@implementation GLProgram

- (id)initWithVertexShaderString:(NSString *)vShaderString fragmentShaderString:(NSString *)fShaderString {
    if(self = [super init]) {
        _initialized = NO;
        
        attributes = @[].mutableCopy;
        uniforms = @[].mutableCopy;
        program = glCreateProgram();
        
        if(![self compileShader:&vertShader type:GL_VERTEX_SHADER string:vShaderString]) {
            NSLog(@"Failed to compile vertex shader");
        }
        
        if(![self compileShader:&fragShader type:GL_FRAGMENT_SHADER string:fShaderString]) {
            NSLog(@"Failed to compile fragment shader");
        }
        
        glAttachShader(program, vertShader);
        glAttachShader(program, fragShader);
    }
    return self;
}

-  (BOOL)compileShader:(GLuint *)shader type:(GLenum)type string:(NSString *)shaderString {
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[shaderString UTF8String];
    if(!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);

    if (status != GL_TRUE)
    {
        GLint logLength;
        glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0)
        {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(*shader, logLength, &logLength, log);
            if (shader == &vertShader)
            {
                self.vertexShaderLog = [NSString stringWithFormat:@"%s", log];
            }
            else
            {
                self.fragmentShaderLog = [NSString stringWithFormat:@"%s", log];
            }

            free(log);
        }
    }

    
    return status == GL_TRUE;
}

- (void)addAttribute:(NSString *)attributeName {
    if(![attributes containsObject:attributeName]) {
        [attributes addObject:attributeName];
        glBindAttribLocation(program, (GLuint)[self attributeIndex:attributeName], [attributeName UTF8String]);
    }
}

- (GLuint)attributeIndex:(NSString *)attributeName {
    return (GLuint)[attributes indexOfObject:attributeName];
}

- (GLuint)uniformIndex:(NSString *)uniformName {
    return glGetUniformLocation(program, [uniformName UTF8String]);
}


- (BOOL)link {
    GLint status;
    
    glLinkProgram(program);
    
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE)
        return NO;
    
    if (vertShader)
    {
        glDeleteShader(vertShader);
        vertShader = 0;
    }
    if (fragShader)
    {
        glDeleteShader(fragShader);
        fragShader = 0;
    }
    
    self.initialized = YES;

    return YES;
}

- (void)use {
    glUseProgram(program);
}

- (void)validate {
    GLint logLength;
    
    glValidateProgram(program);
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(program, logLength, &logLength, log);
        self.programLog = [NSString stringWithFormat:@"%s", log];
        free(log);
    }
}

- (void)dealloc {
    if(vertShader) {
        glDeleteShader(vertShader);
    }
    
    if(fragShader) {
        glDeleteShader(fragShader);
    }
    
    if(program) {
        glDeleteProgram(program);
    }
}

@end
