//
//  FMDownloadModel.m
//  FMDownloadDemo
//
//  Created by yfm on 2021/10/26.
//

#import "FMDownloadModel.h"

@implementation FMDownloadModel

+ (NSArray<FMDownloadModel *> *)allModels {
    NSMutableArray *arr = @[].mutableCopy;
    NSArray *titles = @[@"文件1", @"文件2", @"文件3"];
    for(int i = 0; i < titles.count; i++) {
        FMDownloadModel *model = [[FMDownloadModel alloc] init];
        model.fileName = titles[i];
        model.status = FMDownloadStatusNormal;
        model.progress = 0.0;
        [arr addObject:model];
    }
    return arr;
}

@end
