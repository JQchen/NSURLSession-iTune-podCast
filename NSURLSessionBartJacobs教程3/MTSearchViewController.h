//
//  MTSearchViewController.h
//  NSURLSessionBartJacobs教程3
//
//  Created by James Qiu on 7/11/15.
//  Copyright (c) 2015 sucex. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTSearchViewController : UIViewController  <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)cancel:(id)sender;

@end
