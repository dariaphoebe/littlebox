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
 
 ----------------------------------------------------------------------------
 LBBaseEventLogger overview
 ----------------------------------------------------------------------------

 A singleton class which collects log events for use in app metrics and
 debugging.
 
 This class by itself does no actual communication without the outside world. It
 should be subclassed in order to communicate with your specific logging/metrics
 SDKs and/or API endpoints.
 
 The class does track "sessions", which are defined more or less as continuous
 periods of time in which the app is foregrounded. If a session ends (the app is
 backgrounded, or endSession is called explicitly), any timed events that are
 still running will be ended and logged. Note that changing the value of the
 userId property will cause a session rotation. It is up to your subclass
 implementation to use the value of sessionId if desired. Some analytics SDKs
 will handle session tracking for you and others won't.
 
 This class can also locally buffer events and upload them in batches to a
 custom remote endpoint. If you can host your own basic event collector, using
 it in addition to a third party analytics SDK is a great way to triangulate on
 your data. See customBufferedEventUploadsEnabled and the uploadRawEvents:
 method.
 
 Please read all the comments in this header file describing the properties and
 methods to get oriented.
 
 */

#import <Foundation/Foundation.h>
#import "LBBaseSingleton.h"
#import "LBTimer.h"

// ----------------------------------------------------------------------------
// Log level enum definitions
// ----------------------------------------------------------------------------

// LBEventLevel and LBEventLogLevel are setup such that a given LBEventLogLevel
// can be said to include a LBEventLevel if the LBEventLevel integer value >=
// LBEventLogLevel integer value.

typedef enum {
    LBEventLevelDebug = 1,           // verbose internal state reports
    LBEventLevelNormal,              // regular events
    LBEventLevelError,               // something went wrong
    LBEventLevelAlarm,               // something went really wrong
} LBEventLevel;

typedef enum {
    LBEventLogLevelDebug = 1,        // all events
    LBEventLogLevelNormal,           // everything except debug events
    LBEventLogLevelError,            // alarm and error events only
    LBEventLogLevelAlarm,            // alarm events only
    LBEventLogLevelNone,             // no events. having this value is the
                                     // only reason to declare LBEventLogLevel
                                     // in addition to LBEventLevel
} LBEventLogLevel;

@interface LBBaseEventLogger : LBBaseSingleton

LB_DECLARE_SHARED_INSTANCE_H(LBBaseEventLogger)

// ----------------------------------------------------------------------------
// Functional basics as well as optional configuration details
// ----------------------------------------------------------------------------

// events below this threshold will be thrown away.
@property (nonatomic, assign) LBEventLogLevel logLevel;

// consoleLogLevel is used for console logging when
// useAlternateLogLevelForConsole == YES, this allows verbose console logging
// but less verbose writes to real analytics collectors.
@property (nonatomic, assign) BOOL useAlternateLogLevelForConsole;
@property (nonatomic, assign) LBEventLogLevel consoleLogLevel;

// what to print in the console at the beginning of each event output line.
// defaults to @"[[LBBaseEventLogger]] ".
@property (nonatomic, strong) NSString *consoleLogPrefix;

// almost any logging or metrics collector is going to want to know a unique id
// for the user. assign it to this property, then subclasses can use this
// property to pass the id along to SDKs/APIs as needed.
// NOTE: the setter for this method is implemented explicitly, because changing
// the property to a new value *triggers a new session.* if you re-implement
// setUserId in your subclass, call the super first in order to preserve that
// behavior.
@property (nonatomic, strong) NSString *userId;

// set this to the name of the events you'd like to track for the start and end
// of client sessions, if any. note that session ids themselves are not
// automatically inserted as event parameters to any events, because almost
// every metrics system deals with session tracking differently. if you want to
// pass a session id on every event, add it to the event dictionaries you pass
// to your collector(s) in your subclass. one way to do this nicely is to
// override setSessionId and add the new value to whatever super-parameter
// system your SDK implements, or bufferedEventSuperParameters if you are using
// customBufferedEventUploadsEnabled.
@property (nonatomic, strong) NSString *startSessionEventName;
@property (nonatomic, strong) NSString *endSessionEventName;

// if you'd like to register any specific parameters on the session start and
// end events, set them here.
@property (nonatomic, strong) NSDictionary *sessionEventSuperParameters;

// call this from your app delegate to give the logger a chance to initialize.
// your subclass using various SDKs will want to implement this method to call
// their respective initialization routines.
- (void)appDidFinishLaunching;

// set this true if you want to see tracers of LBBaseEventLogger logic on the
// console.
@property (nonatomic, assign) BOOL verboseConsoleLogging;

// ----------------------------------------------------------------------------
// Primary logging methods. Note that it's often better to use one of the
// convenience methods declared later on, but it's up to you.
// ----------------------------------------------------------------------------

// Use this to immediately log a non-timed event. Logs to the console and calls
// handleRawEvent
- (void)logEvent:(NSString*)name
      parameters:(NSDictionary *)parameters
           level:(LBEventLevel)level;

// Use this to start a timed event. Logs to the console and sets up timer
// bookkeeping. Does NOT call handleRawEvent (that happens after endTimedEvent)
- (void)startTimedEvent:(NSString*)name
                   date:(NSDate*)startDate
             parameters:(NSDictionary *)parameters
              timerGUID:(NSString*)timerGUID
                  level:(LBEventLevel)level;

// Stop the timer and complete the event, logging to console and calling
// handleRawEvent (setting wasTimed = YES). If "merge" is YES, the new
// parameters dictionary is merged into the original dictionary specified when
// the event was first created and a nil parameters object just keeps the
// original parameters. If NO, the new parameters dictionary replaces the
// original one and a nil parameters object will remove any parameters that were
// set before.
- (void)endTimedEvent:(NSString*)name
                 date:(NSDate*)endDate
           parameters:(NSDictionary *)parameters
                merge:(BOOL)merge
            timerGUID:(NSString*)timerGUID;

// Called by logEvent:... and endTimedEvent:..., this is the actual workhorse
// that subclasses should extend to write to the specific collection
// endpoints/SDKs. This method does not do any console logging. You should
// always call the super method in your subclass implementation.
- (void)handleRawEvent:(NSString*)name
            parameters:(NSDictionary *)parameters
                 level:(LBEventLevel)level
              wasTimed:(BOOL)wasTimed;

// ----------------------------------------------------------------------------
// Convenience methods with argument variations which boil down to calls to the
// already declared methods above.
// ----------------------------------------------------------------------------

- (void)logEvent:(NSString*)name;
+ (void)logEvent:(NSString*)name;
+ (void)logEvent:(NSString*)name parameters:(NSDictionary *)parameters;
+ (void)startTimedEvent:(NSString*)name parameters:(NSDictionary *)parameters;
+ (void)endTimedEvent:(NSString*)name parameters:(NSDictionary *)parameters;
+ (void)endTimedEvent:(NSString*)name parameters:(NSDictionary *)parameters merge:(BOOL)merge;
+ (void)logEvent:(NSString*)name textParam:(NSString*)textFormat, ...;
+ (void)logEvent:(NSString*)name parameters:(NSDictionary *)parameters textParam:(NSString*)textFormat, ...;
+ (void)setUserId:(NSString*)userId;
+ (NSString*)userId;

// ----------------------------------------------------------------------------
// Properties that only apply when customBufferedEventUploadsEnabled == YES
// ----------------------------------------------------------------------------

// if you have a custom event collector endpoint of your own, set
// customBufferedEventUploadsEnabled to YES. events will be buffered up and
// periodically, the uploadRawEvents: method will be called. your subclass
// must implement that method and upload them to your custom collector.
// everything else such as background tasks, timing of the uploads, etc, is
// handled, you only have to deal with the actual data upload and then call a
// success/failure callback. see the method definition in the implementation for
// more details.
@property (nonatomic, assign) BOOL customBufferedEventUploadsEnabled;

// if you would like to add parameters to every event that is buffered and
// uploaded, set them here.
@property (nonatomic, strong) NSDictionary *bufferedEventSuperParameters;

// events being managed through the local buffer/upload system are really just
// dictionaries, so the event name itself needs to be injected into the
// dictionary. this defines the key in the dictionary whose value will be set to
// the event name string. it defaults to @"event"
@property (nonatomic, strong) NSString *bufferedEventParameterKeyForEventName;

// like bufferedEventParameterKeyForEventName, but will be set to the unix
// timestamp of the event. set to nil if you don't want the timestamp set.
// defaults to @"timestamp"
@property (nonatomic, strong) NSString *bufferedEventParameterKeyForUnixTimestamp;

// like bufferedEventParameterKeyForEventName, but will be set to the value of
// an integer counter that is set to 1 at the start of the session and
// incremented for every event, and can be used on the backend/analytics side to
// ensure ordering and consistency. set to nil if you don't want the counter.
// defaults to @"inc"
@property (nonatomic, strong) NSString *bufferedEventParameterKeyForCounter;

// if more than this number of events are buffered before successful upload
// synchronization, events will stop being buffered. prevents excess memory
// usage when the app has no network access or the remote collector is failing,
// etc. defaults to 500.
@property (nonatomic, assign) int maxBufferSize;

// set this to the name of the event that will be logged when the local
// buffer is full, if any. (this could happen due to prolonged failure of the
// uploadRawEvents method, leading to a build up in the local buffer.)
@property (nonatomic, strong) NSString *bufferFullErrorEventName;

// there are three conditions in which local events will be potentially uploaded:
// - app backgrounding
// - buffer size exceeds a threshold number of events
// - we haven't successfully uploaded buffer data in some number of seconds
// use the config properties below to tweak behavior as desired.

// set this to false if you don't want to upload events on app backgrounding.
// the only reason not to use this would be if are you already trying to do work
// or network calls on backgrounding and don't want this functionality to take
// up network resources that might cause your other more important operations to
// fail.
@property (nonatomic, assign) BOOL syncBufferOnBackgrounding;

// especially if you have set syncBufferOnBackgrounding to NO, this will
// additionally trigger event upload if the local buffer exceeds this size.
// defaults to 50. must be less than maxBufferSize. use 0 to turn off threshold
// uploads.
@property (nonatomic, assign) int syncBufferSizeThreshold;

// unbuffered events are uploaded if the last successful upload was longer than
// this number of seconds ago. defaults to 30, use 0 to turn off this function.
@property (nonatomic, assign) int syncBufferAfterSeconds;

// ----------------------------------------------------------------------------
// Class internal properties, which are only declared in the public header file
// in order to make them accessible to subclass implementations without compiler
// warnings. unfortunately there's no good way to make them invisible to calling
// contexts but still visible to subclass implementations...
// ----------------------------------------------------------------------------

// timed event bookkeeping
@property (nonatomic, strong) NSMutableDictionary *timedEventDates;
@property (nonatomic, strong) NSMutableDictionary *timedEventParameters;
@property (nonatomic, strong) NSMutableDictionary *timedEventNames;
@property (nonatomic, strong) NSMutableDictionary *timedEventLevels;
@property (nonatomic, strong) NSMutableArray *timedEventKeyLIFO;

// session bookkeeping and management.
@property (nonatomic, strong) NSString *sessionId;
@property (nonatomic, assign) BOOL sessionActive;
@property (nonatomic, assign) BOOL backgrounded;
- (void)startNewSession;
- (void)ensureSessionExists;
- (void)ensureSessionIsActive;
- (void)endSession;

// event buffer bookkeeping and management
@property (nonatomic, strong) NSMutableArray *logData;
@property (nonatomic, assign) unsigned int counter;
@property (nonatomic, strong) NSMutableArray *syncingLogData;
@property (nonatomic, strong) NSDate *lastSync;
@property (nonatomic, strong) LBTimer *syncTimer;
@property (nonatomic, assign) UIBackgroundTaskIdentifier bgTask;
@property (nonatomic, assign) BOOL full;
@property (nonatomic, assign) BOOL loggerJustBecameFull;
@property (nonatomic, assign) BOOL bufferUploadInProgress;
- (void)startTimer;
- (void)timerTick;
- (void)enqueueEvent:(NSString *)name parameters:(NSDictionary *)parameters;
- (void)sync;
- (void)uploadRawEvents:(NSArray*)events;
- (void)uploadDidSucceed;
- (void)uploadDidFail;
- (void)endBgTask;

@end

/*
 
 ----------------------------------------------------------------------------
 TODO
 ----------------------------------------------------------------------------

 - use doxygen or appledoc
 
 - implement functionality to limit the number of buffered events that will be
 given to uploadRawEvents on any single call. only important for people who
 want to buffer large numbers of events locally and are setting maxBufferSize
 to something higher than the upload endpoint could handle all at once.
 
 - buffered events that have not yet been succesfully uploaded will not survive
 app termination and relaunch. it would be good to persist them somewhere and
 load them up again on relaunch so they can be uploaded eventually instead of
 being lost.
 
 - since the active session is ended when the userId property changes, all timed
 events are ended with it. the problem is that these events might still be
 logically in progress. they didn't necessarily stop just because the userId
 was set or unset (for instance, a timed event tracking the display of a login
 view controller shouldn't necessarily stop when the user logs in because that
 view might continue to do more after the user id is known and set.) this is a
 tricky situation: different people will want different behavior with respect
 to session tracking when the active user id is unknown or changing. nothing is
 going to please everyone. in any case, perhaps it would be a good idea to, in
 the event of a change to the user id, end all active timed events but also
 restart all of them in the new session. i'm not sure.
 
*/
