//
//  AppDelegate.m
//  FMGPUImageDemo
//
//  Created by yfm on 2021/8/30.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "SimpleImageFilterVC.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.backgroundColor = UIColor.whiteColor;
    SimpleImageFilterVC *vc = [[SimpleImageFilterVC alloc] init];
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
