//
//  FMOpenGLVC.m
//  LearnOpenGL
//
//  Created by yfm on 2021/8/26.
//

#import "FMOpenGLVC.h"

@interface FMOpenGLVC ()
@property (nonatomic) NSString *className;
@end

@implementation FMOpenGLVC

- (instancetype)initWithClassName:(NSString *)className {
    if(self = [super init]) {
        _className = className;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    
    Class cls = NSClassFromString(self.className);
    UIView *subView = [[cls alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:subView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
