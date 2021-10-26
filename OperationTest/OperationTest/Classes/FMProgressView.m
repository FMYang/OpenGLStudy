//
//  FMProgressView.m
//  FMDownloadDemo
//
//  Created by yfm on 2021/10/26.
//

#import "FMProgressView.h"

@interface FMProgressView()

@property (nonatomic, strong) CAShapeLayer *progressLayer;

@end

@implementation FMProgressView

- (instancetype)init {
    if(self = [super init]) {
        [self setSubviews];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.progressLayer.frame = self.bounds;
    self.progressLayer.cornerRadius = self.bounds.size.height / 2;
}

- (void)setSubviews {
    [self.layer addSublayer:self.progressLayer];
}

#pragma mark - setter
- (void)setProgress:(float)progress {
    _progress = progress;
    
    float w = progress * self.bounds.size.width;
    if(w <= self.bounds.size.width) {
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, w, self.bounds.size.height) cornerRadius:2];
        self.progressLayer.path = path.CGPath;
    }
}

- (void)updateProgress {
    self.progress = self.progress;
}

- (void)setFillColor:(UIColor *)fillColor {
    self.progressLayer.fillColor = fillColor.CGColor;
}

#pragma mark - getter
- (CAShapeLayer *)progressLayer {
    if(!_progressLayer) {
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.fillColor = UIColor.whiteColor.CGColor;
    }
    return _progressLayer;
}

@end
