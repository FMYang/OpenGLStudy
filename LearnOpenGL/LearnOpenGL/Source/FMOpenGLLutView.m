//
//  FMOpenGLLutView.m
//  LearnOpenGL
//
//  Created by yfm on 2021/9/3.
//

#import "FMOpenGLLutView.h"
#import <Masonry/Masonry.h>

/////////////////////////////////////////////
@interface FMLutModel : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *cover;
@property (nonatomic, copy) NSString *lutIcon;
@property (nonatomic, assign) BOOL selected;

+ (NSArray<FMLutModel *> *)allModels;

@end

@implementation FMLutModel

+ (NSArray<FMLutModel *> *)allModels {
    NSArray *names = @[@"美化", @"Log", @"青橙", @"灰橙", @"黑金", @"蓝冰", @"赛博朋克", @"胶片01", @"胶片02",  @"胶片03", @"胶片04", @"胶片05", @"牛仔", @"玫瑰", @"香槟", @"罗兰", @"极光", @"初音", @"和煦", @"仲夏", @"晴空", @"梦境", @"青葱", @"加州", @"海岛", @"旺角", @"暮色"];
    NSArray *pngCovers = @[@"胶片01", @"胶片02",  @"胶片03", @"胶片04", @"胶片05", @"灰橙", @"黑金", @"蓝冰", @"赛博朋克", @"青橙"];
    NSMutableArray *models = @[].mutableCopy;
    
    FMLutModel *model = [[FMLutModel alloc] init];
    model.name = @"原图";
    model.selected = YES;
    [models addObject:model];

    for(int i = 0; i < names.count; i++) {
        NSString *name = names[i];
        FMLutModel *model = [[FMLutModel alloc] init];
        model.name = name;
        model.lutIcon = [NSString stringWithFormat:@"%@.png", name];
        if([pngCovers containsObject:name]) {
            model.cover = [NSString stringWithFormat:@"%@_cover.png", name];
        } else {
            model.cover = [NSString stringWithFormat:@"%@_cover.jpeg", name];
        }
        [models addObject:model];
    }
        
    return models;
}

@end

//////////////////////////////////////////
@interface FMLutCell: UICollectionViewCell
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UILabel *nameLabel;

- (void)configCell:(FMLutModel *)model;
@end

@implementation FMLutCell

- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)configCell:(FMLutModel *)model {
    self.nameLabel.text = model.name;
    NSString *coverPath = [[NSBundle mainBundle] pathForResource:model.cover ofType:nil];
    self.coverImageView.image = [UIImage imageWithContentsOfFile:coverPath];
    if(model.selected) {
        self.coverImageView.layer.borderColor = [UIColor.redColor colorWithAlphaComponent:0.4].CGColor;
        self.coverImageView.layer.borderWidth = 2;
    } else {
        self.coverImageView.layer.borderColor = UIColor.clearColor.CGColor;
        self.coverImageView.layer.borderWidth = 0;
    }
    self.nameLabel.textColor = model.selected ? UIColor.redColor : UIColor.whiteColor;
}

- (void)setupUI {
    self.backgroundColor = UIColor.clearColor;
    [self addSubview:self.coverImageView];
    [self addSubview:self.nameLabel];
    
    [self.coverImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(0).offset(10);
        make.left.mas_equalTo(0);
        make.width.height.mas_equalTo(50);
    }];
    
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.coverImageView.mas_bottom).offset(5);
        make.left.right.mas_equalTo(0);
        make.height.mas_equalTo(20);
    }];
}

- (UIImageView *)coverImageView {
    if(!_coverImageView) {
        _coverImageView = [[UIImageView alloc] init];
        _coverImageView.layer.cornerRadius = 8;
        _coverImageView.layer.masksToBounds = YES;
    }
    return _coverImageView;
}

- (UILabel *)nameLabel {
    if(!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = UIColor.whiteColor;
        _nameLabel.font = [UIFont systemFontOfSize:10];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _nameLabel;
}

@end
/////////////////////////////////////////////

NSString *const lutVertexShaderSource = SHADER_STRING(
    attribute vec4 position;
    attribute vec2 a_texCoordIn;
    varying vec2 v_TexCoordOut;

    void main(void) {
        v_TexCoordOut = a_texCoordIn;
        gl_Position = position;
    }
);

NSString *const lutFragmentShaderSource = SHADER_STRING(
    precision mediump float;

    varying vec2 v_TexCoordOut;
    uniform sampler2D inputImageTexture;
    uniform sampler2D inputImageTexture2; // lookup texture
    uniform int original; // 接收CPU发送到GPU的数据，确定是否显示原图
    uniform float sliderValue;
                                                        
    void main()
    {
        vec4 textureColor = texture2D(inputImageTexture, v_TexCoordOut);
        if(original == 0) {
            // 显示原图
            gl_FragColor = textureColor;
        } else {
            // 使用lut滤镜
            float blueColor = textureColor.b * 63.0;

            vec2 quad1;
            quad1.y = floor(floor(blueColor) / 8.0);
            quad1.x = floor(blueColor) - (quad1.y * 8.0);

            vec2 quad2;
            quad2.y = floor(ceil(blueColor) / 8.0);
            quad2.x = ceil(blueColor) - (quad2.y * 8.0);

            vec2 texPos1;
            texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
            texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

            vec2 texPos2;
            texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
            texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

            vec4 newColor1 = texture2D(inputImageTexture2, texPos1);
            vec4 newColor2 = texture2D(inputImageTexture2, texPos2);

            // mix(v1, v2, a) = v1 * (1 - a) + v2 * a
            vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
            gl_FragColor = mix(textureColor, vec4(newColor.rgb, textureColor.w), sliderValue);
        }
    }
);

@interface FMOpenGLLutView() <UICollectionViewDelegate, UICollectionViewDataSource> {
    NSString *lutImageName;
    GLuint scrTexture;
    GLuint lutTexture;
}

@property (nonatomic) UIView *bottomView;
@property (nonatomic) UICollectionView *lutCollectionView;
@property (nonatomic) NSArray<FMLutModel *> *datasource;
@property (nonatomic) NSInteger selectedIndex;
@property (nonatomic) UISlider *slider;

@end

@implementation FMOpenGLLutView

- (void)dealloc {
    [self clear];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        _selectedIndex = 0;
        [self setupUI];
    }
    return self;
}

- (void)render {
    // 顶点位置
    const GLfloat vertices[] = {
        -1.0, -1.0, 0.0,   //左下
        1.0,  -1.0, 0.0,   //右下
        -1.0, 1.0,  0.0,   //左上
        1.0,  1.0,  0.0};  //右上
    
    // 纹理坐标
    static const GLfloat coords[] = {
        0.0, 0.0,
        1.0, 0.0,
        0.0, 1.0,
        1.0, 1.0,
    };
    
    // 左旋转90度
    static const GLfloat rotateLeftCoords[] = {
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
    };

    // Y轴翻转的纹理坐标
    static const GLfloat rotateYCoords[] = {
        0.0, 1.0,
        1.0, 1.0,
        0.0, 0.0,
        1.0, 0.0,
    };
        
//    float scale = UIScreen.mainScreen.scale;
//    float h = (srcImage.size.width / srcImage.size.height) * UIScreen.mainScreen.bounds.size.width * scale;
//    glViewport(0, UIScreen.mainScreen.bounds.size.height * 0.5 * scale - h * 0.5, UIScreen.mainScreen.bounds.size.width * scale, h);
    
    
    [self createProgramWithVertexShader:lutVertexShaderSource fragmentShader:lutFragmentShaderSource];
    glUseProgram(self.program);
    
    glEnableVertexAttribArray(glGetAttribLocation(self.program, "position"));
    glVertexAttribPointer(glGetAttribLocation(self.program, "position"), 3, GL_FLOAT, GL_FALSE, 0, vertices);
    
    glVertexAttribPointer(glGetAttribLocation(self.program, "a_texCoordIn"), 2, GL_FLOAT, GL_FALSE, 0, rotateYCoords);
    glEnableVertexAttribArray(glGetAttribLocation(self.program, "a_texCoordIn"));
    
    // 原始图片纹理
    glActiveTexture(GL_TEXTURE0);
    if(scrTexture == 0) {
        UIImage *srcImage = [UIImage imageNamed:@"2.jpeg"];
        scrTexture = [self genTextureFromImage:srcImage];
    }
    glBindTexture(GL_TEXTURE_2D, scrTexture);
    // 指向编号为0的纹理
    glUniform1i(glGetUniformLocation(self.program, "inputImageTexture"), 0);
    
    // lut图片纹理
    glActiveTexture(GL_TEXTURE1);
    if(lutTexture == 0) {
        UIImage *lutImage = [UIImage imageNamed:lutImageName];
        lutTexture = [self genTextureFromImage:lutImage];
    }
    glBindTexture(GL_TEXTURE_2D, lutTexture);
    // 指向编号为1的纹理
    glUniform1i(glGetUniformLocation(self.program, "inputImageTexture2"), 1);
    
    glUniform1i(glGetUniformLocation(self.program, "original"), (GLint)self.selectedIndex);
    glUniform1f(glGetUniformLocation(self.program, "sliderValue"), self.slider.value);
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.frameBuffer);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (GLuint)genTextureFromImage:(UIImage *)image {
    CGImageRef imageRef = [image CGImage];
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    CGRect rect = CGRectMake(0, 0, width, height);
    GLubyte *textureData = (GLubyte *)malloc(width * height * 4);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(textureData, width, height, bitsPerComponent, bytesPerRow, colorSpaceRef, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
//    CGContextTranslateCTM(context, 0, height);
//    CGContextScaleCTM(context, 1.0f, -1.0f);

    CGContextClearRect(context, rect);
    CGContextDrawImage(context, rect, imageRef);
    
    glEnable(GL_TEXTURE_2D);
    
    GLuint texureName;
    glGenTextures(1, &texureName);
    glBindTexture(GL_TEXTURE_2D, texureName);
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
    glBindTexture(GL_TEXTURE_2D, 0); //解绑
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpaceRef);
    free(textureData);
    return texureName;
}

// 获取滤镜图片
//- (void)getImageFromBuffe:(int)width withHeight:(int)height {
//    GLint x = 0, y = 0;
//    NSInteger dataLength = width * height * 4;
//    GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));
//
//    glPixelStorei(GL_PACK_ALIGNMENT, 4);
//    glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
//
//    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
//    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
//    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
//                                    ref, NULL, true, kCGRenderingIntentDefault);
//
//
//    UIGraphicsBeginImageContext(CGSizeMake(width, height));
//    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
//    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
//    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, width, height), iref);
//    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//
//    free(data);
//    CFRelease(ref);
//    CFRelease(colorspace);
//    CGImageRelease(iref);
//}

- (void)clear {
    if(self.program) {
        glDeleteProgram(self.program);
        self.program = 0;
    }
    
    if(scrTexture) {
        glDeleteTextures(1, &scrTexture);
        scrTexture = 0;
    }
    
    if(lutTexture) {
        glDeleteTextures(1, &lutTexture);
        lutTexture = 0;
    }
}

- (void)sliderAction:(UISlider *)slider {
//    [self clear];
    [self render];
}

///////////////////////////// UI /////////////////////////////////////////////
#pragma mark -
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.datasource.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FMLutCell *cell = (FMLutCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    FMLutModel *model = self.datasource[indexPath.row];
    [cell configCell:model];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedIndex = indexPath.row;
    FMLutModel *model = self.datasource[indexPath.row];
    lutImageName = model.lutIcon;
    
    [self.datasource enumerateObjectsUsingBlock:^(FMLutModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.selected = NO;
    }];
    
    model.selected = YES;
    [self.lutCollectionView reloadData];
    
    self.slider.value = 1.0;
    [self clear];
    [self render];
}

#pragma mark - UI
- (void)setupUI {
    [self addSubview:self.slider];
    [self addSubview:self.bottomView];
    [self.bottomView addSubview:self.lutCollectionView];
    
    [self.slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.bottomView.mas_top).offset(-10);
        make.left.equalTo(self).offset(40);
        make.right.equalTo(self.mas_right).offset(-40);
        make.height.mas_equalTo(44);
    }];
    
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.height.mas_equalTo(80 + UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom);
        } else {
            make.height.mas_equalTo(80);
        }
        make.left.right.bottom.mas_equalTo(0);
    }];
    
    [self.lutCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bottomView).offset(5);
        make.left.right.mas_equalTo(0);
        make.height.mas_equalTo(80);
    }];
}

- (UIView *)bottomView {
    if(!_bottomView) {
        _bottomView = [[UIView alloc] init];
        _bottomView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.3];
    }
    return _bottomView;
}

- (UICollectionView *)lutCollectionView {
    if(!_lutCollectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake(50, 80);
        layout.minimumLineSpacing = 20;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _lutCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _lutCollectionView.backgroundColor = UIColor.clearColor;
        _lutCollectionView.contentInset = UIEdgeInsetsMake(0, 20, 0, 20);
        _lutCollectionView.showsVerticalScrollIndicator = NO;
        _lutCollectionView.showsHorizontalScrollIndicator = NO;
        _lutCollectionView.dataSource = self;
        _lutCollectionView.delegate = self;
        [_lutCollectionView registerClass:FMLutCell.class forCellWithReuseIdentifier:@"cell"];
        [self addSubview:_lutCollectionView];
    }
    return _lutCollectionView;
}

- (UISlider *)slider {
    if(!_slider) {
        _slider = [[UISlider alloc] init];
        _slider.minimumValue = 0.0;
        _slider.maximumValue = 1.0;
        _slider.value = 1.0;
        _slider.tintColor = UIColor.whiteColor;
        [_slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
    }
    return _slider;
}

- (NSArray<FMLutModel *> *)datasource {
    if(!_datasource) {
        _datasource = [FMLutModel allModels];
    }
    return _datasource;
}

@end

