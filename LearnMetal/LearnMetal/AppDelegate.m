//
//  AppDelegate.m
//  LearnMetal
//
//  Created by yfm on 2021/10/12.
//

#import "AppDelegate.h"
#import "FilterChainVC.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.backgroundColor = UIColor.whiteColor;
    FilterChainVC *vc = [[FilterChainVC alloc] init];
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    return YES;
}



@end
