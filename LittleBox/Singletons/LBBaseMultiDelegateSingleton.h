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
#import "LBLog.h"
#import "LBZeroingWeakContainer.h"

/*
 
 LBBaseMultiDelegateSingleton implements a singleton base class that can be used
 for singletons that require more than one delegate. And example use case is
 LBSingletonResetManager.
 
 Basic usage:
 
 * have delegates register with your singleton subclass using the addObserver:
 or addObserver:withOrder methods, e.g.:
 [MySingletonSubclass addObserver:self withOrder:42];
 
 * in your singleton subclass, use the LB_SEND_MESSAGE_TO_DELEGATES macro
 to send messages to your delegates, e.g:
 LB_SEND_MESSAGE_TO_DELEGATES(doSomethingWithObject:anObject)
 
 * for robustness, you should define a protocol that your singleton's delegates
 have to implement, and specify this protocol using the
 DECLARE_DELEGATE_PROTOCOL_H and DECLARE_DELEGATE_PROTOCOL_M macros in your
 interface and implemenation, respectively. e.g.:
 
 @protocol MySingletonSubclassDelegateProtocol
 - (void)doSomethingWithObject:(id)anObject;
 @end
 
 @interface MySingletonSubclass
 LB_DECLARE_SHARED_INSTANCE_H(MySingletonSubclass)
 LB_DECLARE_DELEGATE_PROTOCOL_H(MySingletonSubclassDelegateProtocol)
 @end
 
 @implementation MySingletonSubclass
 LB_DECLARE_SHARED_INSTANCE_M(MySingletonSubclass)
 LB_DECLARE_DELEGATE_PROTOCOL_M(MySingletonSubclassDelegateProtocol)
 @end
 
 * for correctness and performance, delegates should ideally unregister
 themselves when they are deallocated, but since this class employs zeroing weak
 references for the delegates, it is not strictly necessary.
 
 Some may ask why this class exists when a simpler delegate design pattern,
 KVO, and NSNotificationCenter already exist as standard approaches. Because:
 
 * a standard delegate implemention only allows for a single delegate, not
 broadcast messaging.
 
 * NSNotificationCenter is not synchronous. Messages arrive at least a runloop
 or two later, as decided by the notification center black box.
 
 * KVO is synchronous but often requires some subtely to use correctly. It also
 can't leverage protocols, or the complex event method signatures you generally
 see in delegate implemenations. Furthermore, change messages are sent only on
 observed property changes via the use of their setter methods, but sometimes
 you need to send signals at specific points in a complex business logic flow in
 which the precise timing of individual property changes are difficult to manage
 with respect to all the other properties that are also changing.
 
 * neither KVO nor NSNotifications allow a guaranteed or preferential
 order of observers.

 With this approach you get the power of delegates & protocols, plus the ability
 to broadcast to multiple delegates in preferential order, without making the
 tradeoffs inherent to notifications or KVO.

 Note: It is your responsibility to make sure your singletons only send messages
 that your delegates can perform. If you want to get compiler warnings when this
 may not be the case, you can use protocols as discussed above: in your
 interface invoke the LB_DECLARE_DELEGATE_PROTOCOL_H(protocolName) macro, and
 use LB_DECLARE_DELEGATE_PROTOCOL_M(protocolName) in your implementation, giving
 them protocol your singleton's delegates should implement. This redefines the
 addObserver:... methods for your subclass, adding your protocol to the method
 argument signatures.
 
 */

// The LB_SEND_MESSAGE_TO_DELEGATES macro is the way for singleton
// subclass implementations to send a broadcast message to all registered
// observers. Because it's just a macro that loops through the delegate array
// and constructs a message send for each one, you write the message just like
// you were writing it inside the braces after the object name, e.g:
//   LB_SEND_MESSAGE_TO_OBSERVERS(doSomething:myObject secondArgument:anotherObject)
// However, the macro does not check to see if the observer responds to the
// selector you've specified, so you can cause a crash by broadcasting a message
// that not all observers can respond to. To mitigate for this, use protocols and
// the DECLARE_METHODS_USING_DELEGATE_PROTOCOL macro (see the .m file).
#define LB_SEND_MESSAGE_TO_DELEGATES(message) \
NSArray* immutableCopy = [NSArray arrayWithArray:self.sortedDelegates]; \
for (LBZeroingWeakContainer *c in immutableCopy) { \
  id delegate = [c weakValue]; \
  [delegate message]; \
}

// See above for discussion
#define LB_DECLARE_DELEGATE_PROTOCOL_H(protocolName) \
+ (void)addDelegate:(id<protocolName>)delegate withOrder:(int)order; \
+ (void)addDelegate:(id<protocolName>)delegate; \
- (void)addDelegate:(id<protocolName>)delegate withOrder:(int)order; \
- (void)addDelegate:(id<protocolName>)delegate; \
\

#define LB_DECLARE_DELEGATE_PROTOCOL_M(protocolName) \
+ (void)addDelegate:(id<protocolName>)delegate withOrder:(int)order { \
    if (NO) LBLog(@"%@ addDelegate:%@ order:%d", NSStringFromClass([self class]), NSStringFromClass([delegate class]), order); \
    BOOL found = NO; \
    for (LBZeroingWeakContainer *c in [self sharedInstance].delegates) { \
        id checkDelegate = [c weakValue]; \
        if (delegate == checkDelegate) found = YES; \
    } \
    if (!found) { \
        [[self sharedInstance].delegates setObject:[NSNumber numberWithInt:order] forKey:[LBZeroingWeakContainer containerWithValue:delegate]]; \
        [[self sharedInstance] updateSortedDelegates]; \
    } \
} \
\
+ (void)addDelegate:(id<protocolName>)delegate { \
    [self addDelegate:delegate withOrder:100]; \
} \
- (void)addDelegate:(id<protocolName>)delegate withOrder:(int)order { \
    [[self class] addDelegate:delegate withOrder:order]; \
} \
- (void)addDelegate:(id<protocolName>)delegate { \
    [[self class] addDelegate:delegate]; \
} \
\

@interface LBBaseMultiDelegateSingleton : LBBaseSingleton

LB_DECLARE_SHARED_INSTANCE_H(LBBaseMultiDelegateSingleton)

// an dictionary of LBZeroingWeakContainer objects to NSNumber order values. the
// keys (LBZeroingWeakContainer objects) holding references to the registered
// delegates.
@property (nonatomic, strong) NSMutableDictionary *delegates;
@property (nonatomic, strong) NSArray *sortedDelegates; // a performance optimization

// add a delegate to the list, with an integral order, or with a default order
// to 100. delegates with lower order values are messaged first. if two
// delegates have the same value, then their order is undefined. note these are
// sometimes redefined in subclasses using the DECLARE_DELEGATE_PROTOCOL_[H/M]
// macros to add protocols to the signature.
+ (void)addDelegate:(id)delegate withOrder:(int)order;
+ (void)addDelegate:(id)delegate;
- (void)addDelegate:(id)delegate withOrder:(int)order;
- (void)addDelegate:(id)delegate;

// remove a registered delegate, if any
- (void)removeDelegate:(id)delegate;
+ (void)removeDelegate:(id)delegate;

// internal, just used by addDelegate methods
- (void)updateSortedDelegates;

@end
