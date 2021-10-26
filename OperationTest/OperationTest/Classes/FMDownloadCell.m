//
//  FMDownloadCell.m
//  FMDownloadDemo
//
//  Created by yfm on 2021/10/26.
//

#import "FMDownloadCell.h"
#import "FMProgressView.h"
#import <Masonry/Masonry.h>

@interface FMDownloadCell()

@property (nonatomic) UILabel *fileNameLabel;
@property (nonatomic) FMProgressView *progressView;
@property (nonatomic) UIButton *pauseButton;
@property (nonatomic) FMDownloadModel *model;
@end

@implementation FMDownloadCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setupUI];
    }
    return self;
}

- (void)configCell:(FMDownloadModel *)model {
    self.model = model;
    self.fileNameLabel.text = model.fileName;
    self.progressView.progress = model.progress;
    NSString *str = (model.status == FMDownloadStatusDownloading) ? @"暂停" : @"下载";
    [self.pauseButton setTitle:str forState:UIControlStateNormal];
}

- (void)btnClick {
    if(self.taskBlock) {
        self.taskBlock(self.model);
    }
}

- (void)setupUI {
    [self.contentView addSubview:self.fileNameLabel];
    [self.contentView addSubview:self.progressView];
    [self.contentView addSubview:self.pauseButton];
    
    [self.fileNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(10);
        make.top.equalTo(self.contentView).offset(5);
        make.right.equalTo(self.pauseButton.mas_left).offset(-10);
    }];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(10);
        make.right.equalTo(self.contentView.mas_right).offset(-10);
        make.bottom.equalTo(self.contentView).offset(-10);
        make.height.mas_equalTo(4);
    }];
    
    [self.pauseButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView.mas_right);
        make.width.mas_equalTo(100);
        make.top.bottom.mas_equalTo(0);
    }];
}

- (UILabel *)fileNameLabel {
    if(!_fileNameLabel) {
        _fileNameLabel = [[UILabel alloc] init];
        _fileNameLabel.font = [UIFont systemFontOfSize:14];
        _fileNameLabel.textColor = UIColor.blackColor;
    }
    return _fileNameLabel;
}

- (FMProgressView *)progressView {
    if(!_progressView) {
        _progressView = [[FMProgressView alloc] init];
    }
    return _progressView;
}

- (UIButton *)pauseButton {
    if(!_pauseButton) {
        _pauseButton = [[UIButton alloc] init];
        [_pauseButton setTitleColor:UIColor.redColor forState:UIControlStateNormal];
        [_pauseButton addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _pauseButton;
}

@end
