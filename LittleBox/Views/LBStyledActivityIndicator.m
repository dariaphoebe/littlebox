/*
 
 Copyright 2013 Klout
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

#import "LBStyledActivityIndicator.h"
#import <QuartzCore/QuartzCore.h>

@implementation LBStyledActivityIndicator

- (id)init {
    if ((self = [super init])) {
        self.color = [UIColor blackColor];
        self.style = LBStyledActivityIndicatorStyleRoundedRect;
    }
    return self;
}

- (BOOL)isSpinning {
    return ([self.spinner isAnimating] ? YES : NO);
}

- (void)setIsSpinning:(BOOL)x {
    return;
}

- (void)startSpinningInView:(UIView *)view {
    [self startSpinningInView:view withFadeIn:NO];
}

- (void)startSpinningInView:(UIView *)view withFadeIn:(BOOL)doFadeIn {
    [self stop];
    self.dimmedView = [[UIView alloc] init];
    UIActivityIndicatorViewStyle spinnerStyle = UIActivityIndicatorViewStyleWhiteLarge;
    if (self.style == LBStyledActivityIndicatorStyleFull) {
        self.dimmedView.frame = view.bounds;
        self.dimmedView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.dimmedView.alpha = 0.7;
    } else if (self.style == LBStyledActivityIndicatorStyleSmallGray) {
        spinnerStyle = UIActivityIndicatorViewStyleGray;
        self.dimmedView.alpha = 0.0;
    } else {
        self.dimmedView.frame = CGRectMake((int)(view.bounds.size.width / 2.0f) - 60,
                                      (int)(view.bounds.size.height / 2.0f) - 60,
                                      120, 120);
        self.dimmedView.layer.cornerRadius = 10;
        self.dimmedView.autoresizingMask =
            (UIViewAutoresizingFlexibleTopMargin |
            UIViewAutoresizingFlexibleLeftMargin |
            UIViewAutoresizingFlexibleBottomMargin |
            UIViewAutoresizingFlexibleRightMargin);
        self.dimmedView.alpha = 0.2;
    }
    self.dimmedView.backgroundColor = self.color;
    if (self.alpha) {
        // if alpha is specified, use it instead of the defaults set above
        self.dimmedView.alpha = [self.alpha floatValue];
    }
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:spinnerStyle];
    self.spinner.hidesWhenStopped = YES;
    self.spinner.center = CGPointMake((int)(view.bounds.size.width / 2.0f) + 0.5, // +0.5 b/c the spinner is 37pt wide
                                 (int)(view.bounds.size.height / 2.0f) + 0.5);
    self.spinner.autoresizingMask =
        (UIViewAutoresizingFlexibleTopMargin |
         UIViewAutoresizingFlexibleLeftMargin |
         UIViewAutoresizingFlexibleBottomMargin |
         UIViewAutoresizingFlexibleRightMargin);
    [self.spinner startAnimating];
    
    // add to view and do fade in if requested
    float targetAlpha = self.dimmedView.alpha;
    if (doFadeIn) {
        self.dimmedView.alpha = 0.0;
        self.spinner.alpha = 0.0;
    }
    [view addSubview:self.dimmedView];
    [view addSubview:self.spinner];
    if (doFadeIn) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.25];
        self.dimmedView.alpha = targetAlpha;
        self.spinner.alpha = 1.0;
        [UIView commitAnimations];
    }
}

- (void)stop {
    [self stopWithFade:NO];
}

- (void)stopWithFade:(BOOL)fade {
    if (fade) {
        [UIView animateWithDuration:0.25 animations:^{
            [self.spinner setAlpha:0.0];
            [self.dimmedView setAlpha:0.0];
        } completion:^(BOOL finished){
            [self.spinner removeFromSuperview];
            self.spinner = nil;
            [self.dimmedView removeFromSuperview];
            self.dimmedView = nil;
        }];
    } else {
        [self.spinner removeFromSuperview];
        self.spinner = nil;
        [self.dimmedView removeFromSuperview];
        self.dimmedView = nil;
    }
}

- (void)bringToFront {
    [[self.dimmedView superview] bringSubviewToFront:self.dimmedView];
    [[self.spinner superview] bringSubviewToFront:self.spinner];
}

- (void)dealloc {
    [self stop];
}

@end
