//
//  ViewController.m
//  FMDownloadDemo
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
    // Do any additional setup after loading the view.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    FMDownloadVC *vc = [[FMDownloadVC alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
