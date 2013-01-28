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

/*

 LBStyledActivityIndicator presents a UIActivityIndicatorView in a few different
 styles:
 
 - LBStyledActivityIndicatorStyleFull: a full screen semi-transparent black
 rectangle with a centered white spinner
 - LBStyledActivityIndicatorStyleRoundedRect: a smaller, centered,
 rounded-corner semi-transparent black rectangle with a centered white spinner
 - LBStyledActivityIndicatorStyleSmallGray: a centered, small, gray spinner by
 itself

 Using this object helps normalize the presentation of spinners in the app and
 makes the job a bit easier by providing some consistent styling and optional
 fade in/out functionality.
 
 */

typedef enum {
    LBStyledActivityIndicatorStyleFull = 0,
    LBStyledActivityIndicatorStyleRoundedRect,
    LBStyledActivityIndicatorStyleSmallGray
} LBStyledActivityIndicatorStyle;

@interface LBStyledActivityIndicator : NSObject

@property (nonatomic, assign) LBStyledActivityIndicatorStyle style;
@property (nonatomic, strong) NSNumber *alpha;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) BOOL isSpinning;
@property (nonatomic, strong) UIView *dimmedView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

- (void)startSpinningInView:(UIView*)view;
- (void)startSpinningInView:(UIView *)view withFadeIn:(BOOL)doFadeIn;
- (void)stop;
- (void)stopWithFade:(BOOL)fade;
- (void)bringToFront;

@end
