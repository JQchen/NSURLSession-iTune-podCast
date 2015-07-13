//
//  ViewController.m
//  NSURLSessionBartJacobs教程3
//
//  Created by James Qiu on 7/11/15.
//  Copyright (c) 2015 sucex. All rights reserved.
//

#import "ViewController.h"
#import "MWFeedParser.h"
//#import "SVProgressHUD.h" //== remove buggy spinner
#import "MTEpisodeCell.h"
#import "AppDelegate.h"


@interface ViewController () <NSURLSessionDelegate, NSURLSessionDownloadDelegate, MWFeedParserDelegate>

@property (strong, nonatomic) NSDictionary *podcast;
@property (strong, nonatomic) NSMutableArray *episodes;
@property (strong, nonatomic) MWFeedParser *feedParser;

@property (strong, nonatomic) NSURLSession *session;
@property (strong, nonatomic) NSMutableDictionary *progressBuffer;


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
//   [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient]; //== remove buggy spinner
    
    // Start Parsing
    [self.feedParser parse];
}

#pragma mark MWFeedParserDelegate

- (void)feedParserDidFinish:(MWFeedParser *)parser {
    // Dismiss Progress HUD
//    [SVProgressHUD dismiss]; //== remove buggy spinner
    
    // Update View
    [self.tableView reloadData];
}

- (void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item {
    if (!self.episodes) {
        self.episodes = [NSMutableArray array];
    }
    
    [self.episodes addObject:item];
    
    // Update Progress Buffer
    NSURL *URL = [self urlForFeedItem:item];
    NSURL *localURL = [self localURLForEpisodeWithName:[URL lastPathComponent]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[localURL path]]) {
        [self.progressBuffer setObject:@(1.0) forKey:[URL absoluteString]];
    }
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

- (void)setupTableView {
    // Register Class for Cell Reuse
    [self.tableView registerClass:[MTEpisodeCell class] forCellReuseIdentifier:EpisodeCell];
}

- (void)setupView {
    // Setup Table View
    [self setupTableView];
}

- (NSURLSession *)backgroundSession {
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Session Configuration
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:@"com.mobiletuts.Singlecast.BackgroundSession"];
        
        // Initialize Session
        session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
        //A queue for scheduling the delegate calls and completion handlers. If nil, the session creates a serial operation queue for performing all delegate method calls and completion handler calls.
    });
    
    return session;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Setup View
    [self setupView];
    
    // Initialize Session
    [self setSession:[self backgroundSession]];
    
    // Initialize Progress Buffer
    [self setProgressBuffer:[NSMutableDictionary dictionary]];
    
    // Load Podcast
    [self loadPodcast];
    
    // Add Observer
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"MTPodcast" options:NSKeyValueObservingOptionNew context:NULL];
    
}


#pragma mark - TableView Data source & Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.episodes ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.episodes ? self.episodes.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MTEpisodeCell *cell = (MTEpisodeCell *)[tableView dequeueReusableCellWithIdentifier:EpisodeCell forIndexPath:indexPath];
    
    // Fetch Feed Item
    MWFeedItem *feedItem = [self.episodes objectAtIndex:indexPath.row];
    NSURL *URL = [self urlForFeedItem:feedItem];

    
    // Configure Table View Cell
    [cell.textLabel setText:feedItem.title];
    [cell.detailTextLabel setText:[NSString stringWithFormat:@"%@", feedItem.date]];
    
    NSNumber *progress = [self.progressBuffer objectForKey:[URL absoluteString]];
    if (!progress) progress = @(0.0);
    
    [cell setProgress:[progress floatValue]];
    return cell;
    
}

- (NSURL *)urlForFeedItem:(MWFeedItem *)feedItem {
    NSURL *result = nil;
    
    // Extract Enclosures
    NSArray *enclosures = [feedItem enclosures];
    if (!enclosures || !enclosures.count) return result;
    
    NSDictionary *enclosure = [enclosures objectAtIndex:0];
    NSString *urlString = [enclosure objectForKey:@"url"];
    result = [NSURL URLWithString:urlString];
    
    return result;
}

- (void)downloadEpisodeWithFeedItem:(MWFeedItem *)feedItem {
    // Extract URL for Feed Item
    NSURL *URL = [self urlForFeedItem:feedItem];
    
    if (URL) {
        // Schedule Download Task
        [[self.session downloadTaskWithURL:URL] resume];
        
        // Update Progress Buffer
        [self.progressBuffer setObject:@(0.0) forKey:[URL absoluteString]];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Fetch Feed Item
    MWFeedItem *feedItem = [self.episodes objectAtIndex:indexPath.row];
    
    // URL for Feed Item
    NSURL *URL = [self urlForFeedItem:feedItem];
    
    if (![self.progressBuffer objectForKey:[URL absoluteString]]) {
        // Download Episode with Feed Item
        [self downloadEpisodeWithFeedItem:feedItem];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - NSURLSessionDelegate, NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (MTEpisodeCell *)cellForDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    // Helpers
    MTEpisodeCell *cell = nil;
    NSURL *URL = [[downloadTask originalRequest] URL];
    
    for (MWFeedItem *feedItem in self.episodes) {
        NSURL *feedItemURL = [self urlForFeedItem:feedItem];
        
        if ([URL isEqual:feedItemURL]) {
            NSUInteger index = [self.episodes indexOfObject:feedItem];
            cell = (MTEpisodeCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
            break;
        }
    }
    
    return cell;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    // Calculate Progress
    double progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
    
    // Update Progress Buffer
    NSURL *URL = [[downloadTask originalRequest] URL];
    [self.progressBuffer setObject:@(progress) forKey:[URL absoluteString]];
    
    // Update Table View Cell
    MTEpisodeCell *cell = [self cellForDownloadTask:downloadTask];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [cell setProgress:progress];
    });
}

- (NSURL *)episodesDirectory {
    
    NSURL *documents = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *episodes = [documents URLByAppendingPathComponent:@"Episodes"];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (![fm fileExistsAtPath:[episodes path]]) {
        NSError *error = nil;
        [fm createDirectoryAtURL:episodes withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (error) {
            NSLog(@"Unable to create episodes directory. %@, %@", error, error.userInfo);
        }
    }
    
    return episodes;
}

- (NSURL *)localURLForEpisodeWithName:(NSString *)name {
    if (!name) return nil;
    return [self.episodesDirectory URLByAppendingPathComponent:name];
}

- (void)moveFileWithURL:(NSURL *)URL downloadTask:(NSURLSessionDownloadTask *)downloadTask {
    // Filename
    NSString *fileName = [[[downloadTask originalRequest] URL] lastPathComponent];
    
    // Local URL
    NSURL *localURL = [self localURLForEpisodeWithName:fileName];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if ([fm fileExistsAtPath:[URL path]]) {
        NSError *error = nil;
        [fm moveItemAtURL:URL toURL:localURL error:&error];
        
        if (error) {
            NSLog(@"Unable to move temporary file to destination. %@, %@", error, error.userInfo);
        }
    }
}

- (void)invokeBackgroundSessionCompletionHandler {
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        NSUInteger count = [dataTasks count] + [uploadTasks count] + [downloadTasks count];
        
        if (!count) {
            AppDelegate *applicationDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            void (^backgroundSessionCompletionHandler)() = [applicationDelegate backgroundSessionCompletionHandler];
            
            if (backgroundSessionCompletionHandler) {
                [applicationDelegate setBackgroundSessionCompletionHandler:nil];
                backgroundSessionCompletionHandler();
            }
        }
    }];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    // Write File to Disk
    [self moveFileWithURL:location downloadTask:downloadTask];
    
    // Update Progress Buffer
    NSURL *URL = [[downloadTask originalRequest] URL];
    [self.progressBuffer setObject:@(1.0) forKey:[URL absoluteString]];
    
    // update cell appearance
    MTEpisodeCell *cell = [self cellForDownloadTask:downloadTask];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    // Invoke Background Completion Handler
    [self invokeBackgroundSessionCompletionHandler];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"MTPodcast"];
}

@end
