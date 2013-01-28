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

#import "LBAnnotatedUIButton.h"
#import <QuartzCore/QuartzCore.h>

@implementation LBAnnotatedUIButton

@synthesize userInfo;

- (void)setBasicTapTargetSelectedBackground {
    UIImage *s = [[UIImage imageNamed:@"tapTargetBackground.png"] stretchableImageWithLeftCapWidth:9 topCapHeight:9];
    [self setBackgroundImage:s forState:UIControlStateSelected];
    [self setBackgroundImage:s forState:UIControlStateHighlighted];
}

- (void)setSquaredTapTargetSelectedBackground {
    UIImage *s = [[UIImage imageNamed:@"tapTargetBackgroundSquareEdge.png"] stretchableImageWithLeftCapWidth:9 topCapHeight:9];
    [self setBackgroundImage:s forState:UIControlStateSelected];
    [self setBackgroundImage:s forState:UIControlStateHighlighted];
}

- (void)unsetBackgrounds {
    [self setBackgroundImage:nil forState:UIControlStateSelected];
    [self setBackgroundImage:nil forState:UIControlStateHighlighted];
}

- (void)setFrameAroundLabellishView:(UIView*)aView {
    self.frame = CGRectMake(aView.frame.origin.x - 4,
                            aView.frame.origin.y,
                            aView.frame.size.width + 4 + 4,
                            aView.frame.size.height);
    self.autoresizingMask = aView.autoresizingMask;
}

- (void)setFrameAroundViews:(NSArray *)viewArray padding:(int)padding {
    if (!viewArray) return;
    if ([viewArray count] == 0) return;
    CGPoint tl = CGPointMake(99999,99999);
    CGPoint br = CGPointMake(-99999,-99999);
    for (UIView *v in viewArray) {
        if ([v isKindOfClass:[UIView class]]) {
            if (tl.x > v.frame.origin.x)
                tl.x = v.frame.origin.x;
            if (tl.y > v.frame.origin.y)
                tl.y = v.frame.origin.y;
            if (br.x < (v.frame.origin.x + v.frame.size.width))
                br.x = (v.frame.origin.x + v.frame.size.width);
            if (br.y < (v.frame.origin.y + v.frame.size.height))
                br.y = (v.frame.origin.y + v.frame.size.height);
            // TODO: this isn't the best way to assign the autoresizingMask
            // mask, but i'm hard pressed to come up with something that could
            // properly deal with all the members of viewArray (they don't
            // necessarily all have the same autoresizingMask)
            self.autoresizingMask = [[viewArray objectAtIndex:0] autoresizingMask];
        }
    }
    self.frame = CGRectMake(tl.x - padding,
                            tl.y - padding,
                            (br.x - tl.x) + padding * 2,
                            (br.y - tl.y) + padding * 2);
}


@end
    
