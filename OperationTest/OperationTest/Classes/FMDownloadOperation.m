//
//  FMDownloadOperation.m
//  OperationTest
//
//  Created by yfm on 2021/10/26.
//

#import "FMDownloadOperation.h"

@implementation FMDownloadOperation

- (void)main {
    for(int i = 0; i<99999; i++) {
        if(!self.isCancelled) {
            NSLog(@"task%@ %d", self.name, i);
        }
    }
    
    NSRunLoop *runloop = [NSRunLoop currentRunLoop];
    while ([runloop runMode:NSDefaultRunLoopMode beforeDate:NSDate.distantFuture]) {
        continue;
    }
}

@end
