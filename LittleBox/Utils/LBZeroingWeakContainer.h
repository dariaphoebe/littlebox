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
 
 This is a simple class to contain a zeroing weak reference to an nsobject. It's
 used by LBBaseMultiDelegateSingleton to store an array of delegates that also
 takes advantage of zeroing weak references for additional runtime safety
 against dangling pointers and resulting crashes, especially when delegates fail
 to unregister themselves from a LBBaseMultiDelegateSingleton instance.
 
 */

#import <Foundation/Foundation.h>

@interface LBZeroingWeakContainer : NSObject <NSCopying>

- (id)initWithValue:(id)value;
+ (LBZeroingWeakContainer *)containerWithValue:(id)value;

@property (nonatomic, weak) id weakValue;

@end
