//
//  FMDownloadModel.h
//  FMDownloadDemo
//
//  Created by yfm on 2021/10/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, FMDownloadStatus) {
    FMDownloadStatusNormal,
    FMDownloadStatusDownloading,
    FMDownloadStatusPause,
};

@interface FMDownloadModel : NSObject

@property (nonatomic) NSString *fileName;
@property (nonatomic) FMDownloadStatus status;
@property (nonatomic) float progress;

+ (NSArray<FMDownloadModel *> *)allModels;

@end

NS_ASSUME_NONNULL_END
