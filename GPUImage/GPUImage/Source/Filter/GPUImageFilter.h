//
//  GPUImageFilter.h
//  GPUImage
//
//  Created by yfm on 2021/9/15.
//

#import "GPUImageOutput.h"

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

#define GPUImageHashIdentifier #
#define GPUImageWrappedLabel(x) x
#define GPUImageEscapedHashIdentifier(a) GPUImageWrappedLabel(GPUImageHashIdentifier)a

extern NSString *const kGPUImageVertexShaderString;
extern NSString *const kGPUImagePassthroughFragmentShaderString;

struct GPUVector4 {
    GLfloat one;
    GLfloat two;
    GLfloat three;
    GLfloat four;
};
typedef struct GPUVector4 GPUVector4;

struct GPUVector3 {
    GLfloat one;
    GLfloat two;
    GLfloat three;
};
typedef struct GPUVector3 GPUVector3;

struct GPUMatrix4x4 {
    GPUVector4 one;
    GPUVector4 two;
    GPUVector4 three;
    GPUVector4 four;
};
typedef struct GPUMatrix4x4 GPUMatrix4x4;

struct GPUMatrix3x3 {
    GPUVector3 one;
    GPUVector3 two;
    GPUVector3 three;
};
typedef struct GPUMatrix3x3 GPUMatrix3x3;


NS_ASSUME_NONNULL_BEGIN

@interface GPUImageFilter : GPUImageOutput <GPUImageInput> {
    GPUImageFramebuffer *firstInputFramebuffer;
    
    GLProgram *filterProgram;
    GLint filterPositionAttribute, filterTextureCoordinateAttribute;
    GLint filterInputTextureUniform;
    
    GPUImageRotationMode inputRotation;
        
    NSMutableDictionary *uniformStateRestorationBlocks;
    dispatch_semaphore_t imageCaptureSemaphore;

}

- (id)initWithFragmentShaderFromString:(NSString *)fragmentShaderString;
+ (const GLfloat *)textureCoordinatesForRotation:(GPUImageRotationMode)rotationMode;

- (CGSize)sizeOfFBO;

- (void)setUniformsForProgramAtIndex:(NSUInteger)programIndex;
- (void)setFloat:(GLfloat)floatValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
- (void)setMatrix4f:(GPUMatrix4x4)matrix forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;

@end

NS_ASSUME_NONNULL_END
