//
//  ViewController.m
//  OperationTest
//
//  Created by yfm on 2021/10/26.
//

#import "ViewController.h"
#import "FMDownloadVC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    FMDownloadVC *vc = [[FMDownloadVC alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}


@end
