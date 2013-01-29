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

#import "LBBaseMultiDelegateSingleton.h"

@implementation LBBaseMultiDelegateSingleton

LB_DECLARE_SHARED_INSTANCE_M(LBBaseMultiDelegateSingleton)
LB_DECLARE_DELEGATE_PROTOCOL_M(NSObject)

- (void)reusableInit {
    [super reusableInit];
    self.delegates = [NSMutableDictionary dictionary];
    self.sortedDelegates = [NSArray array];
}

- (void)reusableTeardown {
    // note that by default, a reset() will NOT clear the delegates. this is
    // because delegates won't know they need to (or when to) re-register
    // themselves, and typically they shouldn't need to know in the first place.
    // if you do want the behavior, add the following line to your subclass
    // implementation of reusableTeardown:
    //
    // self.delegates = nil;
    //
    // or you may prefer to send a specific message to delegates in the event
    // the singleton resets.
    [super reusableTeardown];
}

- (void)updateSortedDelegates {
    self.sortedDelegates = [self.delegates keysSortedByValueUsingComparator: ^(id obj1, id obj2) {
        if ([obj1 intValue] > [obj2 intValue]) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        if ([obj1 intValue] < [obj2 intValue]) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        return (NSComparisonResult)NSOrderedSame;
    }];
}

+ (void)removeDelegate:(id)delegate {
    // LBLog(@"%@ removeDelegate:%@", NSStringFromClass([self class]), NSStringFromClass([delegate class]));
    LBZeroingWeakContainer *foundContainer = nil;
    for (LBZeroingWeakContainer *c in [self sharedInstance].delegates) {
        id checkDelegate = [c weakValue];
        if (delegate == checkDelegate) foundContainer = c;
    }
    if (foundContainer) {
        [[self sharedInstance].delegates removeObjectForKey:foundContainer];
        [[self sharedInstance] updateSortedDelegates];
    }
}

- (void)removeDelegate:(id)delegate {
    [[self class] removeDelegate:delegate];
}

@end
