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
 
 LBNetworkStatusSpinnerManager provides a simple, global singleton interface for
 managing the on/off state of the status bar network activity indicator.
 
 To turn on the indicator, register a connection identifier string via
 registerConnection, and then unregister it via unregisterConnection when the
 operation is complete.
 
 Multiple connections can be simultaneously registered, and the spinner will
 only disappear once all of them are unregistered.
 
 Note that using this singleton is an all-or-nothing proposition. Don't mix this
 with other code that twiddles the state of the networkActivityIndicatorVisible
 property of the UIApplication.
 
 */

#import "LBBaseSingleton.h"

@interface LBNetworkStatusSpinnerManager : LBBaseSingleton

LB_DECLARE_SHARED_INSTANCE_H(LBNetworkStatusSpinnerManager)

@property (nonatomic, strong) NSMutableDictionary *connectionsActive;

+ (void)registerConnection:(NSString *)connectionIdentifier;
+ (void)unregisterConnection:(NSString *)connectionIdentifier;
- (void)registerConnection:(NSString *)connectionIdentifier;
- (void)unregisterConnection:(NSString *)connectionIdentifier;

@end
