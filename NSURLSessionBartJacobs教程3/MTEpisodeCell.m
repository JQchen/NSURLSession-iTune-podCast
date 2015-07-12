//
//  MTEpisodeCell.m
//  
//
//  Created by James Qiu on 7/12/15.
//
//

#import "MTEpisodeCell.h"

@interface MTEpisodeCell ()
@property (strong, nonatomic) UIView *progressView;

@end

@implementation MTEpisodeCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setProgress:(CGFloat)progress {
    if (_progress != progress) {
        _progress = progress;
        
        // Update View
        [self updateView];
    }
}

- (void)updateView {
    // Helpers
    CGSize size = self.contentView.bounds.size;
    
    // Update Frame Progress View
    CGRect frame = self.progressView.frame;
    frame.size.width = size.width * self.progress;
    self.progressView.frame = frame;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    
    if (self) {
        // Helpers
        CGSize size = self.contentView.bounds.size;
        
        // Configure Labels
        [self.textLabel setBackgroundColor:[UIColor clearColor]];
        [self.detailTextLabel setBackgroundColor:[UIColor clearColor]];
        
        // Initialize Progress View
        self.progressView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, size.width, size.height)];
        
        // Configure Progress View
        [self.progressView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
        [self.progressView setBackgroundColor:[UIColor colorWithRed:0.678 green:0.886 blue:0.557 alpha:1.0]];
        [self.contentView insertSubview:self.progressView atIndex:0];
        
        // Update View
        [self updateView];
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
