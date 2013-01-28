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
 
 LBAnnotatedUIButton is a simple UIButton with an extra NSDictionary property
 called userInfo. It's very useful for attaching identifying information to a
 button so that when a button tap handler is called, the handler can grab
 userInfo off of the sender object and therefore know which button it is,
 extract actionable information from userInfo, etc.
 
 This is particularly useful for situations where you are creating multiple
 buttons programmatically, all of which target the same tap handler method.
 Imagine for instance a grid of avatars generated in a nested for loop. All
 those avatars are UIImageViews that you want to overlay a transparent button
 on, and those buttons would all likely have the same handler, and the handler
 needs to know which avatar was tapped.
 
 The class also implements some utility methods (for adjusting the frame and
 creating a semi-transparent selected rectangle image) that make it useful for
 creating tap targets on top of UILabels or other objects (such as the avatars
 in the example above).
 
 */

#import <Foundation/Foundation.h>

@interface LBAnnotatedUIButton : UIButton

@property (nonatomic, strong) NSDictionary *userInfo;

// adds a background image to the button when selected that is semi-transparent
// black with rounded corners. this looks good when you want to make a UILabel
// act as if it's tappable - add a LBAnnotatedUIButton on top of the UILabel,
// using setFrameAroundLabellishView to position it correctly and
// setBasicTapTargetSelectedBackground to make tapping a visible gesture.
- (void)setBasicTapTargetSelectedBackground;

// like setBasicTapTargetSelectedBackground but the semi-transparent background
// is square in the corners, good for overlaying on UIImageViews.
- (void)setSquaredTapTargetSelectedBackground;

// remove any background set with the above methods
- (void)unsetBackgrounds;

// set the frame of the LBAnnotatedUIButton to nicely frame a UILabel or
// similar-ish UIView
- (void)setFrameAroundLabellishView:(UIView*)aView;

// set the frame of the LBAnnotatedUIButton to nicely overlay ann arbitrary set
// of UIViews, making sure its min/max boundaries include all of them. note that
// all the views you pass in really should have the same autoresizing mask, or
// this LBAnnotatedUIButton can't correctly set its own autoresizing mask.
- (void)setFrameAroundViews:(NSArray *)viewArray padding:(int)padding;

@end
