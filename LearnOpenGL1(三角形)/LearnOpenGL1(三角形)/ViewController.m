//
//  ViewController.m
//  LearnOpenGL1(三角形)
//
//  Created by yfm on 2021/8/23.
//

#import "ViewController.h"
#import "FMTriangleView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    FMTriangleView *triangleView = [[FMTriangleView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    [self.view addSubview:triangleView];
}


@end
