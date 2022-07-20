//
//  AppDelegate.m
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/13.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "FMMetalGPU1FilterVC.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.backgroundColor = UIColor.whiteColor;
//    ViewController *vc = [[ViewController alloc] init];
    FMMetalGPU1FilterVC *vc = [[FMMetalGPU1FilterVC alloc] init];
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
