//
//  FMFilterVC.m
//  GPUImageExample
//
//  Created by yfm on 2021/9/24.
//

#import "FMFilterVC.h"
#import "FMCameraVC.h"

@interface FMFilterVC () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) NSArray *datasource;
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation FMFilterVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView reloadData];
}

#pragma mark -
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datasource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.textLabel.text = self.datasource[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *name = self.datasource[indexPath.row];
    FMCameraVC *vc = [[FMCameraVC alloc] initWithFilterName:name];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}
#pragma mark -
- (UITableView *)tableView {
    if(!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.frame = self.view.bounds;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [_tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"cell"];
        [self.view addSubview:_tableView];
    }
    return _tableView;
}

- (NSArray *)datasource {
    if(!_datasource) {
        _datasource = @[@"GPUImageBrightnessFilter",
                        @"GPUImageExposureFilter",
                        @"GPUImageContrastFilter",
                        @"GPUImageSaturationFilter",
                        @"GPUImageGammaFilter",
                        @"GPUImageEmbossFilter"];
    }
    return _datasource;
}

@end
