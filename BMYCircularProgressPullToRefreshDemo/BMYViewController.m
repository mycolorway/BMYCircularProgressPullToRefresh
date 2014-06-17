//
//  BMYViewController.m
//  BMYPullToRefreshDemo
//
//  Created by Alberto De Bortoli on 18/05/2014.
//  Copyright (c) 2014 Beamly. All rights reserved.
//

#import "BMYViewController.h"
#import "BMYCircularProgressView.h"
#import "UIScrollView+BMYPullToRefresh.h"

@interface BMYViewController ()<
UITableViewDelegate,
UITableViewDataSource>

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end

@implementation BMYViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *logoImage = [UIImage imageNamed:@"bicon.png"];
    UIImage *backCircleImage = [UIImage imageNamed:@"light_circle.png"];
    UIImage *frontCircleImage = [UIImage imageNamed:@"dark_circle.png"];
    
    BMYCircularProgressView *progressView = [[BMYCircularProgressView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)
                                                                                      logo:logoImage
                                                                           backCircleImage:backCircleImage
                                                                          frontCircleImage:frontCircleImage];
    
    __weak typeof(self) weakSelf = self;
    
    [self.tableView addPullToRefreshWithHeight:60.0f actionHandler:^(BMYPullToRefreshView *pullToRefreshView) {
        int64_t delayInSeconds = 1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf.tableView.pullToRefreshView stopAnimating];
        });
    }];
    
    [self.tableView.pullToRefreshView setProgressView:progressView];
}

- (void)dealloc {
    [self.tableView tearDownPullToRefresh];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 15;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    cell.textLabel.text = NSLocalizedString(@"Pull me to refresh!", nil);
    return cell;
}

@end
