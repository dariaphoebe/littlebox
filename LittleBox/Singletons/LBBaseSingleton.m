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

#import "LBBaseSingleton.h"
#import "LBSingletonResetManager.h"

@implementation LBBaseSingleton

+ (id)sharedInstance {
    // this method is actually redefined in each subclass using the
    // LB_DECLARE_SHARED_INSTANCE_M macro, so does nothing in this base
    // implementation. this declaration is here only to prevent a compiler
    // warning about an incomplete implementation. in subclasses, it will
    // auto-vivify the the instance if it has not yet been created.
    LBLog(@"WARNING! LBBaseSingleton sharedInstance called... did you forget to use LB_DECLARE_SHARED_INSTANCE_M in your singleton sublcass?");
    return nil;
}

- (void)initialInit {
    LBLog(@"%@ initialInit (LBBaseSingleton super method)", NSStringFromClass([self class]));
    self.resettable = YES; // register with LBSingletonResetManager by default
    self.resetOrder = LBResetOrderGroup5; // with the middle order (5 out of 10) by default
}

- (void)reusableInit {
    LBLog(@"%@ reusableInit (LBBaseSingleton super method)", NSStringFromClass([self class]));
    if (self.resettable) {
        if (self.resetOrder > 0) {
            [LBSingletonResetManager addDelegate:self withOrder:self.resetOrder];
        } else {
            [LBSingletonResetManager addDelegate:self];
        }
    }
}

- (void)reusableTeardown {
    LBLog(@"%@ reusableTeardown (LBBaseSingleton super method)", NSStringFromClass([self class]));
}

- (void)finalTeardown {
    LBLog(@"%@ finalTeardown (LBBaseSingleton super method)", NSStringFromClass([self class]));
}

- (void)reset {
    LBLog(@"%@ reset (LBBaseSingleton super method)", NSStringFromClass([self class]));
    [self reusableTeardown];
    [self reusableInit];
}

- (void)dealloc {
    LBLog(@"%@ dealloc (LBBaseSingleton super method)", NSStringFromClass([self class]));
    [self reusableTeardown];
    [self finalTeardown];
}

@end
