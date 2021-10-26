//
//  FMDownloadCell.h
//  FMDownloadDemo
//
//  Created by yfm on 2021/10/26.
//

#import <UIKit/UIKit.h>
#import "FMDownloadModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface FMDownloadCell : UITableViewCell

@property (nonatomic) void (^taskBlock)(FMDownloadModel *);

- (void)configCell:(FMDownloadModel *)model;

@end

NS_ASSUME_NONNULL_END
