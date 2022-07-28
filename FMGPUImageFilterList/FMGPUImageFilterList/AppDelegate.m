//
//  AppDelegate.m
//  FMGPUImageFilterList
//
//  Created by yfm on 2022/7/28.
//

#import "AppDelegate.h"
#import "FMFilterListVC.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.backgroundColor = UIColor.whiteColor;
    FMFilterListVC *vc = [[FMFilterListVC alloc] init];
    UIViewController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
