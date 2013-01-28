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

#import "LBLog.h"

/*

 A base class to inherit from for all your application singletons. Provides
 macros to define tedious singleton boilerplate code, and coordinates with
 LBSingletonResetManager in order to provide singletons that are easily
 "resettable." Resetting singletons is useful in cases like user logout
 scenarios, where all application state should be forgotten.
 
 Subclassing notes:
 
 * Call the LB_DECLARE_SHARED_INSTANCE_M macro in the subclass @implementation in
 order to make it an actual singleton. This is done with a macro because, by the
 definition of a singleton, the static instance object is fundamentally tied to
 the class, and so cannot be inherited by a subclass.
 
 * Call the LB_DECLARE_SHARED_INSTANCE_H macro in your subclass @interface
 declaration. This lets the compiler know the actual class of your singleton as
 returned by sharedInstance(). Without this macro, sharedInstance is declared of
 type (id).
 
 * Optionally extend initialInit() and adjust self.resettable and/or
 self.resetOrder to tweak if and how the singleton is registered with
 LBSingletonResetManager.
 
 * Optionally extend the following methods, which are really worth understanding:
 
 - (void)reset;
 - (void)initialInit;
 - (void)reusableInit;
 - (void)reusableTeardown;
 - (void)finalTeardown;
 
 Their purpose is to allow singletons, which are otherwise persistent objects,
 to have the ability to fully reset state as if the shared instance object was
 deallocated and then recreated. That's useful for instance in implementing a
 user logout feature that you want to result in totally forgetting the current
 application state across the board.
 
 So why not just provide a method that deallocates and recreates the static
 shared instance? Because unknown and varied application code could be holding
 onto references to the older instance, and it's essentially impossible to
 enforce that such calling code will behave responsibly with those references
 when a singleton may need to be deallocated and reinitialized. How would
 calling code know precisely when to update its pointer to the singleton? And
 yet if it does not do so, any attempt to call the singleton would crash after
 the reset. You might argue that calling code should not store references to the
 shared instance directly, and I'd agree with you, but that is also impossible
 to enforce.
 
 Instead, I've chosen a more complex but hopefully more reliable approach that
 keeps the shared instance objects truly and perpetually persistent, so that
 nobody has to worry about dangling pointers and the resulting crashes. The
 tradeoff is in sticking to some additional conventions: when defining
 subclasses, all the work that typically goes into init() and dealloc() methods
 should instead go into initialInit(), reusableInit(), reusableTeardown(), and
 finalTeardown() methods. In more detail:
 
 - (void)reset;
 call this when you want to reset the singleton. it basically just calls
 reusableTeardown() and reusableInit() in series.
 
 - (void)initialInit;
 use this to set defaults for config-level attributes of the singleton that
 should not be affected by reset(). the key difference between this and
 reusableInit() is that it is really only ever called once - the very first
 time the singleton is created, just like the regular objective-c init().
 you should also make any changes to self.resettable and self.resetOrder here.
 
 - (void)reusableInit;
 use this to setup runtime state that should be rebuilt after initialInit() or a
 reusableTeardown(). for instance, to register for notification center
 notifications, setup bookkeeping properties, etc.
 
 - (void)reusableTeardown;
 the opposite of reusableInit. nillify or otherwise clear all the properties
 that should be cleared for a reset() event, removing all delegate
 relationships, unregistering for notifications, etc.
 
 - (void)finalTeardown;
 given that we're in an ARC environment, this is unlikely to be necessary, but
 it's included for completeness. it's like dealloc in that sense and in fact is
 simply called from dealloc.
 
 Lifecycle graph:
 
   first access to singleton sharedInstance
      |
   init()
      |
   initialInit()
      |
   reusableInit() <------------- reusableTeardown()
      |                                       |
   time passes                                |
      |      \_____________                   |
      |                    \                  |
   app terminates   OR   something triggers reset()
      |
   dealloc()
      |
   finalTeardown()
 
 */

#define LB_DECLARE_SHARED_INSTANCE_M(CLASSNAME)             \
static CLASSNAME *_sharedInstance = nil;                    \
                                                            \
+ (CLASSNAME *)sharedInstance {                             \
    @synchronized([CLASSNAME class]) {                      \
        if (_sharedInstance == nil) {                       \
            _sharedInstance = [[CLASSNAME alloc] init];     \
        }                                                   \
    }                                                       \
    return _sharedInstance;                                 \
}                                                           \
                                                            \
- (id)init {                                                \
    @synchronized([CLASSNAME class]) {                      \
        if((self = [super init])) {                         \
            if (self.initialized == NO) {                   \
                [self initialInit];                         \
                [self reusableInit];                        \
                self.initialized = YES;                     \
            }                                               \
        }                                                   \
        return self;                                        \
    }                                                       \
}                                                           \

#define LB_DECLARE_SHARED_INSTANCE_H(CLASSNAME)             \
+ (CLASSNAME *)sharedInstance;                              \

// instead of assigning plain integers to resetOrder, using values from an enum
// allows you to search your project and find all singletons that will share the
// same reset order. it's otherwise very hard to search for that.
typedef enum {
    LBResetOrderGroupNone = 0,
    LBResetOrderGroup1,
    LBResetOrderGroup2,
    LBResetOrderGroup3,
    LBResetOrderGroup4,
    LBResetOrderGroup5,
    LBResetOrderGroup6,
    LBResetOrderGroup7,
    LBResetOrderGroup8,
    LBResetOrderGroup9,
    LBResetOrderGroup10
} LBResetOrderGroup;

@protocol LBResettable <NSObject>

// calling this simply calls reusableTeardown and reusableInit in sequence.
- (void)reset;

// methods in which subclasses should do the work you'd typically expect to see
// in init and dealloc methods. this makes reset() work.
- (void)initialInit;
- (void)reusableInit;
- (void)reusableTeardown;
- (void)finalTeardown;

@end

@interface LBBaseSingleton : NSObject <LBResettable>

// the sharedInstance() method is redefined to instantiate the specific subclass
// in each subclass implementation using the LB_DECLARE_SHARED_INSTANCE_M macro.
// subclasses also redefine it's return value in their interfaces using
// LB_DECLARE_SHARED_INSTANCE_H.
// for the generic base class, we don't use the LB_DECLARE_SHARED_INSTANCE_H
// macro because the macro declares the return value as a pointer to a class
// name, whereas "id" is a special type that requires its own syntax.
+ (id)sharedInstance;

// if true (default), the singleton automatically registers itself with
// LBSingletonResetManager. resetOrder is used if non-zero
// (LBResetOrderGroupNone), and defaults to LBResetOrderGroup5. see
// LBSingletonResetManager.h for an understanding of how it works. be sure to
// set these as desired in initialInit(), since the actual registration with
// LBSingletonResetManager occurs in resuableInit().
@property (nonatomic, assign) BOOL resettable;
@property (nonatomic, assign) LBResetOrderGroup resetOrder;

// for internal use, prevent multiple calls to initialInit and reusableInit when
// a subclass is instantiated
@property (nonatomic, assign) BOOL initialized;

@end
