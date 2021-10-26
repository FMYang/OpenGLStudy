//
//  FMDownloadVC.m
//  FMDownloadDemo
//
//  Created by yfm on 2021/10/26.
//

#import "FMDownloadVC.h"
#import "FMDownloadCell.h"
#import "FMDownloadModel.h"

@interface FMDownloadVC () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSArray *datasource;

@end

@implementation FMDownloadVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.tableView];
}

#pragma mark -
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datasource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FMDownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    FMDownloadModel *model = self.datasource[indexPath.row];
    [cell configCell:model];
    return cell;
}

#pragma mark -
- (UITableView *)tableView {
    if(!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [_tableView registerClass:FMDownloadCell.class forCellReuseIdentifier:@"cell"];
    }
    return _tableView;
}

- (NSArray *)datasource {
    if(!_datasource) {
        _datasource = [FMDownloadModel allModels];
    }
    return _datasource;
}

@end
