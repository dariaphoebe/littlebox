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
 
 A wrapper for NSTimer that does not create a retain cycle when you retain it
 and set self for the timer target. Uses a zeroing weak reference for the
 target to accomplish this.
 
 The timer is automatically invalidated and released if the target is nil when
 the timer fires. This means you don't have to explicitly invalidate the timer,
 although it's still good practice to do so.
 
 Warning: do not return values from your target selector method. ARC will not
 know the retain/release status of the return value and a memory leak may ensue.
 
 TODO: implement (or proxy) the full NSTimer interface and constructors
 
 */

#import <Foundation/Foundation.h>

@interface LBTimer : NSObject

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, weak) id target;

+ (LBTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)repeats;
+ (LBTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)repeats forMode:(NSString*)runLoopMode;
- (id)initWithScheduledTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)repeats forMode:(NSString*)runLoopMode;

- (void)fire;
- (void)invalidate;
- (BOOL)isValid;
- (id)userInfo;

@end
