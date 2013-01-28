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

#import "LBTimer.h"

@implementation LBTimer

+ (LBTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)repeats forMode:(NSString *)runLoopMode {
    // this variant exists becomes sometimes it is useful to schedule a timer
    // using NSCommonRunLoopModes instead of NSDefaultRunLoopMode, such as
    // when you need the timer to fire even when the UI thread is tracking
    // finger motion.
    return [[LBTimer alloc] initWithScheduledTimerWithTimeInterval:seconds target:target selector:aSelector userInfo:userInfo repeats:repeats forMode:runLoopMode];
}

+ (LBTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)repeats {
    return [[LBTimer alloc] initWithScheduledTimerWithTimeInterval:seconds target:target selector:aSelector userInfo:userInfo repeats:repeats forMode:NSDefaultRunLoopMode];
}

- (id)initWithScheduledTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)repeats forMode:(NSString *)runLoopMode {
    if ((self = [super init])) {
        // create an retain a timer that targets self and fires self's fire
        // method. this creates a retain cycle between self and self.timer, but
        // the cycle will be broken appropriately.
        self.timer = [NSTimer timerWithTimeInterval:seconds target:self selector:@selector(fire) userInfo:userInfo repeats:repeats];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:runLoopMode];
        // the real target and selector
        self.selector = aSelector;
        self.target= target;
    }
    return self;
}

- (void)fire {
    if (!self.target) {
        // target has been deallocated and we now have a nil reference thanks to
        // zeroing weak references. invalidate timer automatically, thus ending
        // the retain cycle between this class and the timer. most likely now
        // both the timer and this object will drop to a zero retain count and
        // be deallocated. (unless some other object is also retaining this
        // LBTimer, which would be odd.)
        [self.timer invalidate];
        return;
    }
    // suppress the "performSelector may cause a leak because its selector is
    // unknown" warning from ARC.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    // call the real selector on the real target.
    [self.target performSelector:self.selector];
#pragma clang diagnostic pop
}

// a few convient proxy methods

- (id)userInfo {
    return self.timer.userInfo;
}

- (BOOL)isValid {
    return [self.timer isValid];
}

- (void)invalidate {
    [self.timer invalidate];
}

@end
