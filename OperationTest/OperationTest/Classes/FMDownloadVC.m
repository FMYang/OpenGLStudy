//
//  FMDownloadVC.m
//  FMDownloadDemo
//
//  Created by yfm on 2021/10/26.
//

#import "FMDownloadVC.h"
#import "FMDownloadCell.h"
#import "FMDownloadModel.h"
#import "FMDownloadOperation.h"

@interface FMDownloadVC () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSArray *datasource;

@property (nonatomic) NSOperationQueue *taskQueue;
@property (nonatomic) NSMutableArray *tasks;

@end

@implementation FMDownloadVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.tableView];
    
    for(int i = 0; i < self.datasource.count; i++) {
        FMDownloadModel *model = self.datasource[i];
        FMDownloadOperation *operation = [[FMDownloadOperation alloc] init];
        operation.name = [NSString stringWithFormat:@"%ld", model.taskId];
        [self.taskQueue addOperation:operation];
        [self.tasks addObject:operation];
//        [operation cancel];
    }
}

#pragma mark - task
- (void)excuteTask:(FMDownloadModel *)model {
    FMDownloadOperation *curOperation = nil;
    for(FMDownloadOperation *operation in self.tasks) {
        if(operation.name.integerValue == model.taskId) {
            curOperation = operation;
        }
    }
    
    if(model.status == FMDownloadStatusDownloading) {
        if(curOperation.isExecuting) {
            [curOperation cancel];
        }
        model.status = FMDownloadStatusPause;
    } else {
        if(!curOperation.isExecuting) {
            [curOperation start];
        }
        model.status = FMDownloadStatusDownloading;
    }
    [self.tableView reloadData];
}

- (void)taskAction:(NSNumber *)taskId {
    for(int i = 0; i<100000; i++) {
        NSLog(@"task id %ld", taskId.integerValue);
    }
}

#pragma mark -
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datasource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FMDownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    FMDownloadModel *model = self.datasource[indexPath.row];
    [cell configCell:model];
    __weak FMDownloadVC *weakSelf = self;
    cell.taskBlock = ^(FMDownloadModel * _Nonnull model) {
        [weakSelf excuteTask:model];
    };
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

- (NSMutableArray *)tasks {
    if(!_tasks) {
        _tasks = @[].mutableCopy;
    }
    return _tasks;
}

- (NSOperationQueue *)taskQueue {
    if(!_taskQueue) {
        _taskQueue = [[NSOperationQueue alloc] init];
        _taskQueue.maxConcurrentOperationCount = 3;
    }
    return _taskQueue;
}

@end
