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

#import "LBUtils.h"

@implementation LBUtils(cgrect)

+(NSString*) stringForRect:(CGRect)rect {
    return [NSString stringWithFormat:@"x=%f y=%f width=%f height=%f",rect.origin.x, rect.origin.y, rect.size.width, rect.size.height];
}

+(NSString*) stringForSize:(CGSize)size {
    return [NSString stringWithFormat:@"width=%f height=%f", size.width, size.height];
}

+(CGRect) rectFromRect:(CGRect)rect newOriginX:(float)xOffset {
    return CGRectMake(xOffset, rect.origin.y, rect.size.width, rect.size.height);
}

+(CGRect) rectFromRect:(CGRect)rect newOriginY:(float)yOffset {
    return CGRectMake(rect.origin.x, yOffset, rect.size.width, rect.size.height);
}

+(CGRect) rectFromRect:(CGRect)rect newWidth:(float)width {
    return CGRectMake(rect.origin.x, rect.origin.y, width, rect.size.height);
}

+(CGRect) rectFromRect:(CGRect)rect newHeight:(float)height {
    return CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, height);
}

+(CGRect) rectForUITextViewWithMarginOffsetsAndSizedHeight:(UITextView*)textView {
    // before calling this method, set the UITextView's frame to the maximum
    // bounds you want the actual text (ignoring margins) to be contained in as
    // if it were a UILabel.
    return CGRectMake(textView.frame.origin.x - 8, // slide up+right to offset the 8px margins
                      textView.frame.origin.y - 8,
                      textView.frame.size.width + 16, // expand 2x margin for proper inner width
                      [textView sizeThatFits:CGSizeMake(textView.frame.size.width + 16, textView.frame.size.height)].height); // set height to fit
}

+(void) autoAdjustHeightForUnlimitedLinesUILabel:(UILabel*)label {
    // this only works if the label numberOfLines == 0
    // otherwise, the height can end up larger than desired and the label text gets vertically centered with unsightly top/bottom spacing.
    // note that this does not mean it can't be constrained in size, it will never be resized to exceed the label frame.
    // width is maintained.
    if ([label.text isKindOfClass:[NSString class]]) {
        label.frame = [self rectFromRect:label.frame newHeight:[label.text sizeWithFont:label.font constrainedToSize:label.frame.size lineBreakMode:label.lineBreakMode].height];
    }
}

+(void) autoAdjustHeightForUnlimitedLinesUILabelUnlimitedHeight:(UILabel*)label {
    // this only works if the label numberOfLines == 0
    // otherwise, the height can end up larger than desired and the label text gets vertically centered with unsightly top/bottom spacing.
    // the resizing may exceed the original label frame (vertically).
    // width is maintained.
    if ([label.text isKindOfClass:[NSString class]]) {
        CGSize frameSizeVeryTall = label.frame.size;
        frameSizeVeryTall.height = 9999;
        label.frame = [self rectFromRect:label.frame newHeight:[label.text sizeWithFont:label.font constrainedToSize:frameSizeVeryTall lineBreakMode:label.lineBreakMode].height];
    }
}

+(void) setCorrectContentSizeOnScrollView:(UIScrollView*)scrollView ensureScrollable:(BOOL)ensureScrollable {
    if (!scrollView) return;
    CGRect contentRect = CGRectZero;
    if (ensureScrollable) {
        contentRect = CGRectMake(0, 0, scrollView.frame.size.width, scrollView.frame.size.height);
    }
    for (UIView* view in scrollView.subviews) {
        contentRect = CGRectUnion(contentRect, view.frame);
    }
    if (ensureScrollable && contentRect.size.height <= (scrollView.frame.size.height + 0.1)) {
        contentRect = CGRectMake(contentRect.origin.x,
                                 contentRect.origin.y,
                                 contentRect.size.width,
                                 contentRect.size.height + 10.0f); // with 1.0 instead of 10.0 as the extra padding, the scroll indicators don't show when you scroll/bounce the scrollview.
    }
    scrollView.contentSize = contentRect.size;
}

@end
