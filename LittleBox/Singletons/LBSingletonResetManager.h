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

 This class is a singleton that all subclasses of LBBaseSingleton will
 automatically register themselves with by default. Calling resetAllSingletons
 on this class in turn calls the reset() method on each registered singleton,
 which in turn triggers their reusableTeardown() and reusableInit() methods to
 trigger in series. It's a very simple use case for the
 LBBaseMultiDelegateSingleton. Klout uses it when a user logs out in order to
 completely reset state on the app, as if it were terminated and restarted.

 The order in which the singletons are sent the message is defined by the order
 passed in on it's addObserver:withOrder: method, which is invoked by each
 registered singleton in the LBBaseSingleton initialInit() method, using the
 resetOrder property of those singletons (see LBBaseSingleton).
 
 In other words, when you subclass LBBaseSingleton, you might want to extend the
 initialInit() method to either (a) turn off registration with this class, or
 (b) adjust the resetOrder to one of the values of the LBResetOrderGroup enum.
 
 */

#import "LBBaseMultiDelegateSingleton.h"

@interface LBSingletonResetManager : LBBaseMultiDelegateSingleton

LB_DECLARE_SHARED_INSTANCE_H(LBSingletonResetManager)
LB_DECLARE_DELEGATE_PROTOCOL_H(LBResettable)

- (void)resetAllSingletons;
+ (void)resetAllSingletons;

@end
