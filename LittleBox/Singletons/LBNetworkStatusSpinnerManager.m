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

#import "LBNetworkStatusSpinnerManager.h"

@implementation LBNetworkStatusSpinnerManager

LB_DECLARE_SHARED_INSTANCE_M(LBNetworkStatusSpinnerManager)

- (void)initialInit {
    [super initialInit];
    self.resetOrder = LBResetOrderGroup5;
}

- (void)reusableInit {
    [super reusableInit];
    self.connectionsActive = [[NSMutableDictionary alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
}

- (void)reusableTeardown {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.connectionsActive = nil;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [super reusableTeardown];
}

+ (void)registerConnection:(NSString *)connectionIdentifier {
    [[self sharedInstance] registerConnection:connectionIdentifier];
}

+ (void)unregisterConnection:(NSString *)connectionIdentifier {
    [[self sharedInstance] unregisterConnection:connectionIdentifier];
}

- (void)registerConnection:(NSString *)connectionIdentifier {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.connectionsActive setObject:@"holder" forKey:connectionIdentifier];
}

- (void)unregisterConnection:(NSString *)connectionIdentifier {
    [self.connectionsActive removeObjectForKey:connectionIdentifier];
    if([self.connectionsActive count] == 0) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
}

- (void)willResignActive:(NSNotification*)notification {
    // as a safety valve against permanent spinning, clear spinner state on
    // entering background
    [self.connectionsActive removeAllObjects];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

@end
