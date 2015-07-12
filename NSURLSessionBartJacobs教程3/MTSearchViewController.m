//
//  MTSearchViewController.m
//  NSURLSessionBartJacobs教程3
//
//  Created by James Qiu on 7/11/15.
//  Copyright (c) 2015 sucex. All rights reserved.
//

#import "MTSearchViewController.h"

@interface MTSearchViewController ()<UIScrollViewDelegate>

@property (strong, nonatomic) NSURLSession *session;
@property (strong, nonatomic) NSURLSessionDataTask *dataTask;
@property (strong, nonatomic) NSMutableArray *podcasts;

@end


static NSString *SearchCell = @"SearchCell";

@implementation MTSearchViewController


- (NSURLSession *)session {
    if (!_session) {
        // Initialize Session Configuration
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        // Configure Session Configuration
        [sessionConfiguration setHTTPAdditionalHeaders:@{ @"Accept" : @"application/json" }];
        
        // Initialize Session
        _session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    }
    
    return _session;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Show Keyboard
    [self.searchBar becomeFirstResponder];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
}



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.podcasts ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.podcasts ? self.podcasts.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SearchCell forIndexPath:indexPath];
    
    // Fetch Podcast
    NSDictionary *podcast = [self.podcasts objectAtIndex:indexPath.row];
    
    // Configure Table View Cell
    [cell.textLabel setText:[podcast objectForKey:@"collectionName"]];
    [cell.detailTextLabel setText:[podcast objectForKey:@"artistName"]];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Fetch Podcast
    NSDictionary *podcast = [self.podcasts objectAtIndex:indexPath.row];
    
    // Update User Defatuls
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:podcast forKey:@"MTPodcast"];
    [ud synchronize];
    
    // Dismiss View Controller
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)resetSearch {
    // Update Data Source
    [self.podcasts removeAllObjects];
    
    // Update Table View
    [self.tableView reloadData];
}

- (NSURL *)urlForQuery:(NSString *)query {
    query = [query stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/search?media=podcast&entity=podcast&term=%@", query]];
}

- (void)processResults:(NSArray *)results {
    if (!self.podcasts) {
        self.podcasts = [NSMutableArray array];
    }
    
    // Update Data Source
    [self.podcasts removeAllObjects];
    [self.podcasts addObjectsFromArray:results];
    
    // Update Table View
    [self.tableView reloadData];
}

- (void)performSearch {
    NSString *query = self.searchBar.text;
    
    if (self.dataTask) {
        
        [self.dataTask cancel]; //If it is set, we call cancel on it. This is important as we don't want to receive a response from an old request that may no longer be relevant to the user. This is also the reason why we have only one active data task at any one time. There is no advantage in sending multiple requests to the API.
    }
    
    self.dataTask = [self.session dataTaskWithURL:[self urlForQuery:query]
                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                    if (error) {
                                        if (error.code != -999) { //==QJ== If we do get an error object, we check whether its error code is equal to -999. This error code indicates the data task was canceled.
                                            NSLog(@"%@", error);
                                        }
                                        
                                    } else {
                                        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                        NSArray *results = [result objectForKey:@"results"];
                                        
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            if (results) {
                                                [self processResults:results];
                                            }
                                        });
                                    }
                                }];
    
    if (self.dataTask) {
        [self.dataTask resume];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (!searchText) return;
    
    if (searchText.length <= 3) {
        [self resetSearch];
        
    } else {
        [self performSearch];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
