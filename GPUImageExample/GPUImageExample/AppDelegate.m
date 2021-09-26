//
//  AppDelegate.m
//  GPUImageExample
//
//  Created by yfm on 2021/9/24.
//

#import "AppDelegate.h"
#import "FMFilterVC.h"
#import "GPUImageHistogramFilterVC.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.backgroundColor = UIColor.whiteColor;
    
//    GPUImageHistogramFilterVC *vc = [[GPUImageHistogramFilterVC alloc] init];
//    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    FMFilterVC *vc = [[FMFilterVC alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];

    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
