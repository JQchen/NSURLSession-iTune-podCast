//
//  ViewController.m
//  NSURLSessionBartJacobs教程3
//
//  Created by James Qiu on 7/11/15.
//  Copyright (c) 2015 sucex. All rights reserved.
//

#import "ViewController.h"
#import "MWFeedParser.h"
#import "SVProgressHUD.h"

@interface ViewController () < MWFeedParserDelegate >

@property (strong, nonatomic) NSDictionary *podcast;
@property (strong, nonatomic) NSMutableArray *episodes;
@property (strong, nonatomic) MWFeedParser *feedParser;

@end

static NSString *EpisodeCell = @"EpisodeCell";

@implementation ViewController

- (void)updateView {
    // Update View
    self.title = [self.podcast objectForKey:@"collectionName"];
}

- (void)fetchAndParseFeed {
    if (!self.podcast) return;
    
    NSURL *url = [NSURL URLWithString:[self.podcast objectForKey:@"feedUrl"]];
    if (!url) return;
    
    if (self.feedParser) { //==QJ== 若有旧的，先清除掉
        [self.feedParser stopParsing];
        [self.feedParser setDelegate:nil];
        [self setFeedParser:nil];
    }
    
    // Clear Episodes
    if (self.episodes) {
        [self setEpisodes:nil];
    }
    
    // Initialize Feed Parser
    self.feedParser = [[MWFeedParser alloc] initWithFeedURL:url];
    
    // Configure Feed Parser
    [self.feedParser setFeedParseType:ParseTypeFull];
    [self.feedParser setDelegate:self];
    
    // Show Progress HUD
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    
    // Start Parsing
    [self.feedParser parse];
}

- (void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item {
    if (!self.episodes) {
        self.episodes = [NSMutableArray array];
    }
    
    [self.episodes addObject:item];
}

- (void)feedParserDidFinish:(MWFeedParser *)parser {
    // Dismiss Progress HUD
    [SVProgressHUD dismiss];
    
    // Update View
    [self.tableView reloadData];
}

- (void)setPodcast:(NSDictionary *)podcast {
    if (_podcast != podcast) {
        _podcast = podcast;
        
        // Update View
        [self updateView];
        
        // Fetch and Parse Feed
        [self fetchAndParseFeed];

    }
}

- (void)loadPodcast {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    self.podcast = [ud objectForKey:@"MTPodcast"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"MTPodcast"]) {
        self.podcast = [object objectForKey:@"MTPodcast"];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Load Podcast
    [self loadPodcast];
    
    // Add Observer
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"MTPodcast" options:NSKeyValueObservingOptionNew context:NULL];
    

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.episodes ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.episodes ? self.episodes.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:EpisodeCell forIndexPath:indexPath];
    
    // Fetch Feed Item
    MWFeedItem *feedItem = [self.episodes objectAtIndex:indexPath.row];
    
    // Configure Table View Cell
    [cell.textLabel setText:feedItem.title];
    [cell.detailTextLabel setText:[NSString stringWithFormat:@"%@", feedItem.date]];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"MTPodcast"];
}

@end
