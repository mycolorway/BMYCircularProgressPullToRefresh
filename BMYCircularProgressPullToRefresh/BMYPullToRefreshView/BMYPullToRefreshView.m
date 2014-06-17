//
//  BMYPullToRefreshView.m
//  BMYPullToRefreshDemo
//
//  Created by Alberto De Bortoli on 15/05/2014.
//  Copyright (c) 2014 Beamly. All rights reserved.
//

#import "BMYPullToRefreshView.h"

#import "UIScrollView+BMYPullToRefresh.h"

static CGFloat const kPullToRefreshResetContentInsetAnimationTime = 0.3;
static CGFloat const kPullToRefreshDragToTrigger = 80;

#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)
#define fequalzero(a) (fabs(a) < FLT_EPSILON)

@interface BMYPullToRefreshView ()

@property (nonatomic, strong) UIView<BMYProgressViewProtocol> *progressView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation BMYPullToRefreshView

- (instancetype)initWithFrame:(CGRect)frame scrollView:(UIScrollView *)scrollView {
    if (self = [super initWithFrame:frame]) {
        _scrollView = scrollView;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _state = BMYPullToRefreshStateStopped;
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityIndicatorView.hidesWhenStopped = NO;
        [self setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
        [self setActivityIndicatorViewColor:[UIColor lightGrayColor]];
        [self addSubview:_activityIndicatorView];
    }
    
    return self;
}

- (void)layoutSubviews {
    CGRect viewBounds = [_progressView bounds];
    CGPoint origin = CGPointMake(roundf((CGRectGetWidth(self.bounds) - CGRectGetWidth(viewBounds))/2), roundf(( CGRectGetHeight(self.bounds) - CGRectGetHeight(viewBounds))/2));
    [_progressView setFrame:CGRectMake(origin.x, origin.y, CGRectGetWidth(viewBounds), CGRectGetHeight(viewBounds))];
    [_activityIndicatorView setFrame:CGRectMake(origin.x, origin.y, CGRectGetWidth(viewBounds), CGRectGetHeight(viewBounds))];
}

#pragma mark - Public Methods

- (void)startAnimating {
    self.state = BMYPullToRefreshStateTriggered;
    
    if (fequalzero(_scrollView.contentOffset.y)) {
        [_scrollView setContentOffset:CGPointMake(_scrollView.contentOffset.x, -CGRectGetHeight(self.frame)) animated:YES];
    }
    
    self.state = BMYPullToRefreshStateLoading;
}

- (void)stopAnimating {
    if (_state != BMYPullToRefreshStateStopped) {
        self.state = BMYPullToRefreshStateStopped;
    }
}

- (void)setState:(BMYPullToRefreshState)newState {
    
    if (_state == newState)
        return;
    
    BMYPullToRefreshState previousState = _state;
    _state = newState;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    switch (newState) {
        case BMYPullToRefreshStateAll:
        case BMYPullToRefreshStateTriggered:
        case BMYPullToRefreshStateStopped: {
            [self _resetScrollViewContentInset];
            break;
        }
            
        case BMYPullToRefreshStateLoading: {
            [self _setScrollViewContentInsetForLoading];
            
            if (previousState == BMYPullToRefreshStateTriggered && _pullToRefreshActionHandler) {
                [UIView animateWithDuration:kPullToRefreshResetContentInsetAnimationTime
                                 animations:^{
                                     _progressView.alpha = 0.0f;
                                     _activityIndicatorView.alpha = 1.0f;
                                     [_activityIndicatorView startAnimating];
                                     _pullToRefreshActionHandler(self);
                                 }];
            }
            break;
        }
    }
}

- (void)setProgressView:(UIView<BMYProgressViewProtocol> *)view {
    _activityIndicatorView.hidesWhenStopped = view != nil;
    
    if (_progressView) {
        [_progressView removeFromSuperview];
    }
    
    _progressView = view;
    [self addSubview:_progressView];
    [self setNeedsLayout];
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    }
    else if ([keyPath isEqualToString:@"contentSize"]) {
        [self layoutSubviews];
        self.frame = CGRectMake(0, -CGRectGetHeight(self.bounds), CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    }
    else if ([keyPath isEqualToString:@"frame"]) {
        [self layoutSubviews];
    }
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    if (_state == BMYPullToRefreshStateLoading) {
        CGFloat offset;
        UIEdgeInsets contentInset;
        offset = MAX(-_scrollView.contentOffset.y, 0);
        offset = MIN(offset, CGRectGetHeight(self.bounds));
        contentInset = self.scrollView.contentInset;
        self.scrollView.contentInset = UIEdgeInsetsMake(offset, contentInset.left, contentInset.bottom, contentInset.right);
    } else {
        CGFloat dragging = -contentOffset.y;
        if (!self.scrollView.isDragging && _state == BMYPullToRefreshStateTriggered) {
            self.state = BMYPullToRefreshStateLoading;
        }
        else if (dragging >= kPullToRefreshDragToTrigger && self.scrollView.isDragging && self.state == BMYPullToRefreshStateStopped) {
            self.state = BMYPullToRefreshStateTriggered;
        }
        else if (dragging < kPullToRefreshDragToTrigger && self.state != BMYPullToRefreshStateStopped) {
            self.state = BMYPullToRefreshStateStopped;
        }
        
        if (dragging > 0 && _state != BMYPullToRefreshStateLoading) {
            [_progressView setProgress:(dragging * 1/kPullToRefreshDragToTrigger)];
        }
    }
}

#pragma mark - Accessors Pass Through

- (UIColor *)activityIndicatorViewColor {
    return self.activityIndicatorView.color;
}

- (void)setActivityIndicatorViewColor:(UIColor *)color {
    self.activityIndicatorView.color = color;
}

- (UIActivityIndicatorViewStyle)activityIndicatorViewStyle {
    return self.activityIndicatorView.activityIndicatorViewStyle;
}

- (void)setActivityIndicatorViewStyle:(UIActivityIndicatorViewStyle)viewStyle {
    self.activityIndicatorView.activityIndicatorViewStyle = viewStyle;
}

#pragma mark - Scroll View

- (void)_resetScrollViewContentInset {
    UIEdgeInsets currentInsets = _scrollView.contentInset;
    currentInsets.top = 0;
    [UIView animateWithDuration:kPullToRefreshResetContentInsetAnimationTime
                          delay:0
                        options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         self.scrollView.contentInset = currentInsets;
                     }
                     completion:^(BOOL finished) {
                         if (_progressView) {
                             _progressView.alpha = 1.0f;
                             _activityIndicatorView.alpha = 0.0f;
                         }
                         [_activityIndicatorView stopAnimating];
                     }];
}

- (void)_setScrollViewContentInsetForLoading {
    CGFloat offset = MAX(-_scrollView.contentOffset.y, 0);
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = MIN(offset, CGRectGetHeight(self.bounds));
    [UIView animateWithDuration:kPullToRefreshResetContentInsetAnimationTime
                          delay:0
                        options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         self.scrollView.contentInset = currentInsets;
                     }
                     completion:nil];
}

@end
