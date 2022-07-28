//
//  FMFilterListVC.m
//  FMGPUImageFilterList
//
//  Created by yfm on 2022/7/28.
//

#import "FMFilterListVC.h"
#import "FMFilterVC.h"

@interface FMFilterListVC () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic) UITableView *tableView;
@end

@implementation FMFilterListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Filter List";
    
    [self.view addSubview:self.tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return GPUIMAGE_NUMFILTERS;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    cell.textLabel.textColor = [UIColor blackColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    NSString *title = @"";
    NSString *subTitlte = @"";
    switch (indexPath.row) {
        case GPUIMAGE_SATURATION: title = @"Saturation"; subTitlte = @"饱和度"; break;
        case GPUIMAGE_CONTRAST: title = @"Contrast"; subTitlte = @"对比度"; break;
        case GPUIMAGE_BRIGHTNESS: title = @"Brightness"; subTitlte = @"亮度"; break;
        case GPUIMAGE_LEVELS: title = @"Levels"; subTitlte = @"色阶"; break;
        case GPUIMAGE_EXPOSURE: title = @"Exposure"; subTitlte = @"曝光"; break;
        case GPUIMAGE_RGB: title = @"RGB"; subTitlte = @"RGB"; break;
        case GPUIMAGE_HUE: title = @"Hue"; subTitlte = @"色度"; break;
        case GPUIMAGE_WHITEBALANCE: title = @"White balance"; subTitlte = @"白平衡"; break;
        case GPUIMAGE_MONOCHROME: title = @"Monochrome"; subTitlte = @"单色"; break;
        case GPUIMAGE_FALSECOLOR: title = @"False color"; subTitlte = @"色彩替换，替换亮部和暗部色彩"; break;
        case GPUIMAGE_SHARPEN: title = @"Sharpen"; subTitlte = @"锐化"; break;
        case GPUIMAGE_UNSHARPMASK: title = @"Unsharp mask"; subTitlte = @"反遮罩锐化"; break;
        case GPUIMAGE_GAMMA: title = @"Gamma"; subTitlte = @"伽马线"; break;
        case GPUIMAGE_TONECURVE: title = @"Tone curve"; subTitlte = @"色调曲线"; break;
        case GPUIMAGE_HIGHLIGHTSHADOW: title = @"Highlights and shadows"; subTitlte = @"提亮阴影"; break;
        case GPUIMAGE_HAZE: title = @"Haze"; subTitlte = @"朦胧加暗"; break;
        case GPUIMAGE_CHROMAKEYNONBLEND: title = @"Chroma key"; subTitlte = @"色度键混合"; break;
        case GPUIMAGE_HISTOGRAM: title = @"Histogram"; subTitlte = @"色彩直方图，显示在图片上"; break;
//        case GPUIMAGE_HISTOGRAM_EQUALIZATION: title = @"Histogram Equalization"; break;
        case GPUIMAGE_AVERAGECOLOR: title = @"Average color"; subTitlte = @"像素平均色值"; break;
        case GPUIMAGE_LUMINOSITY: title = @"Luminosity"; subTitlte = @"亮度平均"; break;
        case GPUIMAGE_THRESHOLD: title = @"Threshold"; subTitlte = @""; break;
        case GPUIMAGE_ADAPTIVETHRESHOLD: title = @"Adaptive threshold"; subTitlte = @"自适应阈值"; break;
        case GPUIMAGE_AVERAGELUMINANCETHRESHOLD: title = @"Average luminance threshold"; subTitlte = @"像素色值亮度平均，图像黑白（漫画效果）"; break;
        case GPUIMAGE_CROP: title = @"Crop"; subTitlte = @"剪裁"; break;
        case GPUIMAGE_TRANSFORM: title = @"Transform (2-D)"; subTitlte = @"形状变化2D"; break;
        case GPUIMAGE_TRANSFORM3D: title = @"Transform (3-D)"; subTitlte = @"形状变化3D"; break;
        case GPUIMAGE_MASK: title = @"Mask"; subTitlte = @"遮罩混合"; break;
        case GPUIMAGE_COLORINVERT: title = @"Color invert"; subTitlte = @"反色"; break;
        case GPUIMAGE_GRAYSCALE: title = @"Grayscale"; subTitlte = @"灰度"; break;
        case GPUIMAGE_SEPIA: title = @"Sepia tone"; subTitlte = @"褐色（怀旧）"; break;
        case GPUIMAGE_MISSETIKATE: title = @"Miss Etikate (Lookup)"; subTitlte = @"Miss Etikate (Lookup"; break;
        case GPUIMAGE_SOFTELEGANCE: title = @"Soft elegance (Lookup)"; subTitlte = @"Soft elegance (Lookup"; break;
        case GPUIMAGE_AMATORKA: title = @"Amatorka (Lookup)"; subTitlte = @"Amatorka (Lookup"; break;
        case GPUIMAGE_PIXELLATE: title = @"Pixellate"; subTitlte = @"像素化"; break;
        case GPUIMAGE_POLARPIXELLATE: title = @"Polar pixellate"; subTitlte = @"同心圆像素化"; break;
        case GPUIMAGE_PIXELLATE_POSITION: title = @"Pixellate (position)"; subTitlte = @"像素化指定位置"; break;
        case GPUIMAGE_POLKADOT: title = @"Polka dot"; subTitlte = @"像素圆点花样"; break;
        case GPUIMAGE_HALFTONE: title = @"Halftone"; subTitlte = @"点染,图像黑白化，由黑点构成原图的大致图形"; break;
        case GPUIMAGE_CROSSHATCH: title = @"Crosshatch"; subTitlte = @"交叉线阴影，形成黑白网状画面"; break;
        case GPUIMAGE_SOBELEDGEDETECTION: title = @"Sobel edge detection"; subTitlte = @"Sobel边缘检测算法(白边，黑内容，有点漫画的反色效果)"; break;
        case GPUIMAGE_PREWITTEDGEDETECTION: title = @"Prewitt edge detection"; subTitlte = @"普瑞维特(Prewitt)边缘检测(效果与Sobel差不多，貌似更平滑)"; break;
        case GPUIMAGE_CANNYEDGEDETECTION: title = @"Canny edge detection"; subTitlte = @"Canny边缘检测算法（比Sobel更强烈的黑白对比度）"; break;
        case GPUIMAGE_THRESHOLDEDGEDETECTION: title = @"Threshold edge detection"; subTitlte = @"阈值边缘检测（效果与上差别不大）"; break;
        case GPUIMAGE_XYGRADIENT: title = @"XY derivative"; subTitlte = @"XYDerivative边缘检测，画面以蓝色为主，绿色为边缘，带彩色"; break;
        case GPUIMAGE_HARRISCORNERDETECTION: title = @"Harris corner detection"; subTitlte = @"Harris角点检测，会有绿色小十字显示在图片角点处"; break;
        case GPUIMAGE_NOBLECORNERDETECTION: title = @"Noble corner detection"; subTitlte = @"Noble角点检测，检测点更多"; break;
        case GPUIMAGE_SHITOMASIFEATUREDETECTION: title = @"Shi-Tomasi feature detection"; subTitlte = @"ShiTomasi角点检测，与上差别不大"; break;
        case GPUIMAGE_HOUGHTRANSFORMLINEDETECTOR: title = @"Hough transform line detection"; subTitlte = @"线条检测"; break;
        case GPUIMAGE_BUFFER: title = @"Image buffer"; subTitlte = @"Image buffer"; break;
        case GPUIMAGE_MOTIONDETECTOR: title = @"Motion detector"; subTitlte = @"动作检测"; break;
        case GPUIMAGE_LOWPASS: title = @"Low pass"; subTitlte = @"用于图像加亮"; break;
        case GPUIMAGE_HIGHPASS: title = @"High pass"; subTitlte = @"图像低于某值时显示为黑"; break;
        case GPUIMAGE_SKETCH: title = @"Sketch"; subTitlte = @"素描"; break;
        case GPUIMAGE_THRESHOLDSKETCH: title = @"Threshold Sketch"; subTitlte = @"阀值素描，形成有噪点的素描"; break;
        case GPUIMAGE_TOON: title = @"Toon"; subTitlte = @"卡通效果（黑色粗线描边）"; break;
        case GPUIMAGE_SMOOTHTOON: title = @"Smooth toon"; subTitlte = @"相比上面的效果更细腻，上面是粗旷的画风"; break;
        case GPUIMAGE_TILTSHIFT: title = @"Tilt shift"; subTitlte = @"条纹模糊，中间清晰，上下两端模糊"; break;
        case GPUIMAGE_CGA: title = @"CGA colorspace"; subTitlte = @"CGA色彩滤镜，形成黑、浅蓝、紫色块的画面"; break;
        case GPUIMAGE_CONVOLUTION: title = @"3x3 convolution"; subTitlte = @"3x3卷积，高亮大色块变黑，加亮边缘、线条等"; break;
        case GPUIMAGE_EMBOSS: title = @"Emboss"; subTitlte = @"浮雕效果，带有点3d的感觉"; break;
        case GPUIMAGE_LAPLACIAN: title = @"Laplacian"; subTitlte = @"Laplacian"; break;
        case GPUIMAGE_POSTERIZE: title = @"Posterize"; subTitlte = @"色调分离，形成噪点效果"; break;
        case GPUIMAGE_SWIRL: title = @"Swirl"; subTitlte = @"漩涡，中间形成卷曲的画面"; break;
        case GPUIMAGE_BULGE: title = @"Bulge"; subTitlte = @"凸起失真，鱼眼效果"; break;
        case GPUIMAGE_SPHEREREFRACTION: title = @"Sphere refraction"; subTitlte = @"球形折射，图形倒立"; break;
        case GPUIMAGE_GLASSSPHERE: title = @"Glass sphere"; subTitlte = @"水晶球效果"; break;
        case GPUIMAGE_PINCH: title = @"Pinch"; subTitlte = @"收缩失真，凹面镜"; break;
        case GPUIMAGE_STRETCH: title = @"Stretch"; subTitlte = @"凸起失真，鱼眼效果"; break;
        case GPUIMAGE_DILATION: title = @"Dilation"; subTitlte = @"扩展边缘模糊，变黑白"; break;
        case GPUIMAGE_EROSION: title = @"Erosion"; subTitlte = @"侵蚀边缘模糊，变黑白"; break;
        case GPUIMAGE_OPENING: title = @"Opening"; subTitlte = @"黑白色调模糊"; break;
        case GPUIMAGE_CLOSING: title = @"Closing"; subTitlte = @"黑白色调模糊，暗色会被提亮"; break;
        case GPUIMAGE_PERLINNOISE: title = @"Perlin noise"; subTitlte = @"柏林噪点，花边噪点"; break;
        case GPUIMAGE_VORONOI: title = @"Voronoi"; subTitlte = @"Voronoi"; break;
        case GPUIMAGE_MOSAIC: title = @"Mosaic"; subTitlte = @"黑白马赛克"; break;
        case GPUIMAGE_LOCALBINARYPATTERN: title = @"Local binary pattern"; subTitlte = @"图像黑白化，并有大量噪点"; break;
        case GPUIMAGE_CHROMAKEY: title = @"Chroma key blend (green)"; subTitlte = @"色度键混合"; break;
        case GPUIMAGE_DISSOLVE: title = @"Dissolve blend"; subTitlte = @"溶解"; break;
        case GPUIMAGE_SCREENBLEND: title = @"Screen blend"; subTitlte = @"屏幕包裹,通常用于创建亮点和镜头眩光"; break;
        case GPUIMAGE_COLORBURN: title = @"Color burn blend"; subTitlte = @"色彩加深混合"; break;
        case GPUIMAGE_COLORDODGE: title = @"Color dodge blend"; subTitlte = @"色彩减淡混合"; break;
        case GPUIMAGE_LINEARBURN: title = @"Linear burn blend"; subTitlte = @"Linear burn blend"; break;
        case GPUIMAGE_ADD: title = @"Add blend"; subTitlte = @"通常用于创建两个图像之间的动画变亮模糊效果"; break;
        case GPUIMAGE_DIVIDE: title = @"Divide blend"; subTitlte = @"通常用于创建两个图像之间的动画变暗模糊效果"; break;
        case GPUIMAGE_MULTIPLY: title = @"Multiply blend"; subTitlte = @"通常用于创建阴影和深度效果"; break;
        case GPUIMAGE_OVERLAY: title = @"Overlay blend"; subTitlte = @"叠加,通常用于创建阴影效果"; break;
        case GPUIMAGE_LIGHTEN: title = @"Lighten blend"; subTitlte = @"减淡混合,通常用于重叠类型"; break;
        case GPUIMAGE_DARKEN: title = @"Darken blend"; subTitlte = @"加深混合,通常用于重叠类型"; break;
        case GPUIMAGE_EXCLUSIONBLEND: title = @"Exclusion blend"; subTitlte = @"排除混合"; break;
        case GPUIMAGE_DIFFERENCEBLEND: title = @"Difference blend"; subTitlte = @"差异混合,通常用于创建更多变动的颜色"; break;
        case GPUIMAGE_SUBTRACTBLEND: title = @"Subtract blend"; subTitlte = @"差值混合,通常用于创建两个图像之间的动画变暗模糊效果"; break;
        case GPUIMAGE_HARDLIGHTBLEND: title = @"Hard light blend"; subTitlte = @"强光混合,通常用于创建阴影效果"; break;
        case GPUIMAGE_SOFTLIGHTBLEND: title = @"Soft light blend"; subTitlte = @"柔光混合"; break;
        case GPUIMAGE_COLORBLEND: title = @"Color blend"; subTitlte = @"Color blend"; break;
        case GPUIMAGE_HUEBLEND: title = @"Hue blend"; subTitlte = @"色度混合"; break;
        case GPUIMAGE_SATURATIONBLEND: title = @"Saturation blend"; subTitlte = @"饱和度混合"; break;
        case GPUIMAGE_LUMINOSITYBLEND: title = @"Luminosity blend"; subTitlte = @"亮度混合"; break;
        case GPUIMAGE_NORMALBLEND: title = @"Normal blend"; subTitlte = @"正常"; break;
        case GPUIMAGE_POISSONBLEND: title = @"Poisson blend"; subTitlte = @"Poisson blend"; break;
        case GPUIMAGE_OPACITY: title = @"Opacity adjustment"; subTitlte = @"不透明度"; break;
        case GPUIMAGE_KUWAHARA: title = @"Kuwahara"; subTitlte = @"桑原(Kuwahara)滤波,水粉画的模糊效果；处理时间比较长，慎用"; break;
        case GPUIMAGE_KUWAHARARADIUS3: title = @"Kuwahara (fixed radius)"; subTitlte = @"Kuwahara (fixed radius"; break;
        case GPUIMAGE_VIGNETTE: title = @"Vignette"; subTitlte = @"晕影，形成黑色圆形边缘，突出中间图像的效果"; break;
        case GPUIMAGE_GAUSSIAN: title = @"Gaussian blur"; subTitlte = @"高斯模糊"; break;
        case GPUIMAGE_MEDIAN: title = @"Median (3x3)"; subTitlte = @"中间值，有种稍微模糊边缘的效果"; break;
        case GPUIMAGE_BILATERAL: title = @"Bilateral blur"; subTitlte = @"双边模糊"; break;
        case GPUIMAGE_MOTIONBLUR: title = @"Motion blur"; subTitlte = @"Motion blur"; break;
        case GPUIMAGE_ZOOMBLUR: title = @"Zoom blur"; subTitlte = @"Zoom blur"; break;
        case GPUIMAGE_BOXBLUR: title = @"Box blur"; subTitlte = @"盒状模糊"; break;
        case GPUIMAGE_GAUSSIAN_SELECTIVE: title = @"Gaussian selective blur"; subTitlte = @"高斯模糊，选择部分清晰"; break;
        case GPUIMAGE_GAUSSIAN_POSITION: title = @"Gaussian (centered)"; subTitlte = @"高斯模糊，中间部分清晰"; break;
//        case GPUIMAGE_IOSBLUR: title = @"iOS 7 blur"; break;
        case GPUIMAGE_UIELEMENT: title = @"UI element"; subTitlte = @"UI element"; break;
        case GPUIMAGE_CUSTOM: title = @"Custom"; subTitlte = @"自定义"; break;
        case GPUIMAGE_FILECONFIG: title = @"Filter Chain"; subTitlte = @"滤镜链"; break;
        case GPUIMAGE_FILTERGROUP: title = @"Filter Group"; subTitlte = @"滤镜组"; break;
        case GPUIMAGE_FACES: title = @"Face Detection"; subTitlte = @"人脸检测"; break;
    }
    
    cell.textLabel.text = title;
    cell.detailTextLabel.text = subTitlte;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    FMFilterVC *vc = [[FMFilterVC alloc] initWithFilterType:(GPUImageShowcaseFilterType)indexPath.row];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark -
- (UITableView *)tableView {
    if(!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.frame = self.view.bounds;
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

@end
