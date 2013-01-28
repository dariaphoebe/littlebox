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

#import "LBSingletonResetManager.h"

@implementation LBSingletonResetManager

LB_DECLARE_SHARED_INSTANCE_M(LBSingletonResetManager)
LB_DECLARE_DELEGATE_PROTOCOL_M(LBResettable)

- (void)initialInit {
    [super initialInit];
    self.resettable = NO; // don't self-register
}

- (void)resetAllSingletons {
    LBLog(@"resetting all singletons!");
    LB_SEND_MESSAGE_TO_DELEGATES(reset); // BOOM!
    LBLog(@"all singletons have been reset!");
}

+ (void)resetAllSingletons {
    [[self sharedInstance] resetAllSingletons];
}

@end
