//
//  ViewController.h
//  OpenGL_ES_Lession1
//
//  Created by yfm on 2021/6/2.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface ViewController : GLKViewController {
    // 定点数据的缓存标识符
    GLuint vertexbufferID;
}

@property (nonatomic, strong) GLKBaseEffect *baseEffect;

@end

