//
//  ViewController.m
//  LearnOpenGL1(三角形)
//
//  Created by yfm on 2021/8/23.
//

#import "ViewController.h"
#import "FMOpenGLVC.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *datasource;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Learn OpenGL";
    
    self.tableView.frame = self.view.bounds;
    [self.view addSubview:self.tableView];
}

#pragma mark -
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datasource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    NSDictionary *dic = self.datasource[indexPath.row];
    cell.textLabel.text = dic.allKeys[0];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dic = self.datasource[indexPath.row];
    NSString *className = dic.allValues[0];
    FMOpenGLVC *vc = [[FMOpenGLVC alloc] initWithClassName:className];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark -
- (UITableView *)tableView {
    if(!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        [_tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"cell"];
    }
    return _tableView;
}

- (NSArray *)datasource {
    return @[@{@"窗口": NSStringFromClass(FMOpenGLWindow.class)},
             @{@"三角形": NSStringFromClass(FMOpenGLTriangle.class)},
             @{@"着色器": NSStringFromClass(FMOpenGLShaderFinal.class)},
             @{@"纹理": NSStringFromClass(FMOpenGLTexture.class)},
             @{@"Lut": NSStringFromClass(FMOpenGLLutView.class)}];
}

@end
