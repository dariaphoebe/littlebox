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

#import "LBBaseEventLogger.h"
#import "LBUtils.h"

@implementation LBBaseEventLogger {}

LB_DECLARE_SHARED_INSTANCE_M(LBBaseEventLogger)

#pragma mark lifecycle handlers

- (void)initialInit {
    [super initialInit];
    // Setup defaults for properties which are not affected by reset()
    self.syncBufferOnBackgrounding = YES;
    self.logLevel = LBEventLevelNormal;
    self.useAlternateLogLevelForConsole = YES;
    self.consoleLogLevel = LBEventLevelDebug;
    self.consoleLogPrefix = @"[[LBBaseEventLogger]] ";
    self.startSessionEventName = nil;
    self.endSessionEventName = nil;
    self.bufferedEventParameterKeyForEventName = @"event";
    self.bufferedEventParameterKeyForUnixTimestamp = @"timestamp";
    self.bufferedEventParameterKeyForCounter = @"inc";
    self.maxBufferSize = 500;
    self.syncBufferSizeThreshold = 50;
    self.syncBufferAfterSeconds = 30;
    self.lastSync = [NSDate date];
}

- (void)reusableInit {
    // See comments in LBBaseSingleton to fully understand reusableInit and reusableTeardown
    [super reusableInit];
    // Register for all relevant application lifecycle notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willTerminate)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    // Setup more defaults
    self.timedEventDates = [NSMutableDictionary dictionary];
    self.timedEventParameters = [NSMutableDictionary dictionary];
    self.timedEventLevels = [NSMutableDictionary dictionary];
    self.timedEventKeyLIFO = [NSMutableArray array];
    self.timedEventNames = [NSMutableDictionary dictionary];
    self.sessionActive = NO;
    self.full = NO;
    self.loggerJustBecameFull = NO;
}

- (void)reusableTeardown {
    // Unregister for notifications and nillify most internal properties. See
    // comments in LBBaseSingleton to fully understand reusableInit and
    // reusableTeardown. note that not all properties are cleared here, because
    // some of them are configuration settings that should persist through an
    // app reset.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self endSession];
    self.userId = nil;
    self.timedEventDates = nil;
    self.timedEventParameters = nil;
    self.timedEventKeyLIFO = nil;
    self.timedEventLevels = nil;
    self.timedEventNames = nil;
    self.sessionId = nil;
    self.sessionActive = NO;
    self.bufferUploadInProgress = NO;
    [self endBgTask];
    self.logData = nil;
    self.counter = 0;
    self.full = NO;
    self.loggerJustBecameFull = NO;
    self.bufferUploadInProgress = NO;
    self.syncingLogData = nil;
    self.lastSync = nil;
    [self.syncTimer invalidate];
    self.syncTimer = nil;
    self.bgTask = UIBackgroundTaskInvalid;
    [super reusableTeardown];
}

- (void)reset {
    [self logVerbose:@"reset message received, initiating teardown and reinitialization"];
    [super reset];
}

- (void)appDidFinishLaunching {
    // call this from your app delegate to give the eventlogger a chance to
    // initialize. augment this in the base class with initialization to your
    // respective sdk(s).
    [self logVerbose:@"appDidFinishLaunching"];
    self.backgrounded = NO;
    [self startTimer];
}

- (void)willEnterForeground {
    [self logVerbose:@"willEnterForeground"];
    self.backgrounded = NO;
    [self startTimer];
}

- (void)didBecomeActive {
    self.backgrounded = NO;
    [self startTimer];
}

- (void)willResignActive {
}

- (void)willTerminate {
    if (self.customBufferedEventUploadsEnabled) {
        [self logVerbose:@"willTerminate, attempting final upload of buffered events"];
    } else {
        [self logVerbose:@"willTerminate"];
    }
    // syncing here may or may not succeed, but we might as well try. buffered
    // events are not yet persisted across app termination, so there is
    // potential for lost events.
    [self sync];
}

- (void)didEnterBackground {
    [self logVerbose:@"didEnterBackground, ending current session"];
    [self endSession];
    self.backgrounded = YES;
    [self.syncTimer invalidate];
    self.syncTimer = nil;
    // trigger upload for buffered events if configured to do so
    if (self.syncBufferOnBackgrounding && self.customBufferedEventUploadsEnabled) {
        if ([self.logData count] > 0) {
            // if there is log data to sync, or we are in mid-sync, ask for more time from OS to run in the background.
            if (self.bgTask != UIBackgroundTaskInvalid) [self endBgTask];
            [self logVerbose:@"registering background task to upload pending events"];
            self.bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    if (self.bgTask != UIBackgroundTaskInvalid) {
                        [self logVerbose:@"background task expired before it could finish, events will be resubmitted later"];
                        [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
                        self.bgTask = UIBackgroundTaskInvalid;
                        [self uploadDidFail];
                    }
                });
            }];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self sync];
            });
        }
    }
}

#pragma mark console output

- (void)logVerbose:(NSString*)textFormat, ... {
    if (!self.verboseConsoleLogging) return;
    NSString *text = nil;
    if (textFormat) {
        va_list argumentList;
        va_start(argumentList, textFormat);
        text = [[NSString alloc] initWithFormat:textFormat arguments:argumentList];
    }
    if (text) {
        LBLogRaw(@"%@<internal>: %@", self.consoleLogPrefix, text);
    }
}

- (void)consoleLogEvent:(NSString*)name
             parameters:(NSDictionary *)parameters
          timerStarting:(BOOL)timerStarting
          timerStopping:(BOOL)timerStopping
                  level:(LBEventLevel)level {
    // dumps the event to the console if applicable
    if (level >= (self.useAlternateLogLevelForConsole ? self.consoleLogLevel : self.logLevel)) {
        NSString *timerStateString = @"";
        NSString *levelString = @"";
        switch (level) {
            case LBEventLevelNormal:
                levelString = @"<normal>";
                break;
            case LBEventLevelDebug:
                levelString = @"<debug>";
                break;
            case LBEventLevelAlarm:
                levelString = @"<<<<<<<<<< ALARM >>>>>>>>>>";
                break;
            case LBEventLevelError:
                levelString = @"<ERROR>";
                break;
        }
        if (timerStarting) timerStateString = @" <timer start>";
        if (timerStopping) timerStateString = @" <timer stop>";
        if (parameters && ([parameters count] > 0)) {
            // TODO: find a prettier way to log parameter dictionaries.
            LBLogRaw(@"%@%@%@: %@ params=%@", self.consoleLogPrefix, levelString, timerStateString, name, parameters);
        } else {
            LBLogRaw(@"%@%@%@: %@", self.consoleLogPrefix, levelString, timerStateString, name);
        }
    }
}

#pragma mark core logging methods

- (void)handleRawEvent:(NSString*)name
            parameters:(NSDictionary *)parameters
                 level:(LBEventLevel)level
              wasTimed:(BOOL)wasTimed {
    // this is the "workhorse" that should communicate event data to real event
    // logging systems/sdks. in the base class we make sure the session is
    // active and setup correctly, increment the event counter, and also put the
    // event in the local buffer when customBufferedEventUploadsEnabled == YES.
    // therefore, subclasses must first call super in their implementations.
    [self ensureSessionIsActive];
    self.counter = self.counter + 1;
    if (self.customBufferedEventUploadsEnabled) [self enqueueEvent:name parameters:parameters];
}

- (void)logEvent:(NSString*)name
      parameters:(NSDictionary *)parameters
           level:(LBEventLevel)level {

    // see header for comments
    [self consoleLogEvent:name parameters:parameters timerStarting:NO timerStopping:NO level:level];
    
    // skip processing at this point for events below the normal logLevel threshold
    if (level < self.logLevel) return;
    
    [self handleRawEvent:name parameters:parameters level:level wasTimed:NO];
}

- (void)startTimedEvent:(NSString*)name
                   date:(NSDate*)startDate
             parameters:(NSDictionary *)parameters
              timerGUID:(NSString*)timerGUID
                  level:(LBEventLevel)level {
    
    // see header for comments
    [self consoleLogEvent:name parameters:parameters timerStarting:YES timerStopping:NO level:level];

    if (level < self.logLevel) return;

    // for new timed events, just do bookkeeping, don't log anything until the timer is ended
    NSString *timerKey = timerGUID;
    if (!timerKey) timerKey = name;
    [self.timedEventNames setObject:name forKey:timerKey];
    [self.timedEventDates setObject:(startDate ? startDate : [NSDate date]) forKey:timerKey];
    [self.timedEventKeyLIFO removeObject:timerKey];
    [self.timedEventLevels setObject:[NSNumber numberWithInt:level] forKey:timerKey];
    [self.timedEventKeyLIFO addObject:timerKey];
    if (parameters) { // don't insert nil into a dictionary
        [self.timedEventParameters setObject:parameters forKey:timerKey];
    }
}

- (void)endTimedEvent:(NSString*)name
                 date:(NSDate*)endDate
           parameters:(NSDictionary *)parameters
                merge:(BOOL)merge
            timerGUID:(NSString*)timerGUID {
    
    // see header for comments
    NSString *timerKey = timerGUID;
    if (!timerKey) timerKey = name;

    NSDate *startTime = [self.timedEventDates objectForKey:timerKey];
    if (!startTime) return; // abort if no record of this event exists

    NSDictionary *originalParams = [self.timedEventParameters objectForKey:timerKey];
    LBEventLevel level = (LBEventLevel)[[self.timedEventLevels objectForKey:timerKey] intValue];
    
    double duration = (-1.0f * [startTime timeIntervalSinceDate:(endDate ? endDate : [NSDate date])]);
    [self.timedEventDates removeObjectForKey:timerKey];
    [self.timedEventParameters removeObjectForKey:timerKey];
    [self.timedEventKeyLIFO removeObject:timerKey];
    [self.timedEventNames removeObjectForKey:timerKey];
    
    NSMutableDictionary *newParams;
    if (merge) {
        // use originally stored event params, merging in whatever is in the parameters argument
        newParams = [NSMutableDictionary dictionaryWithDictionary:originalParams];
        if (parameters) [newParams addEntriesFromDictionary:parameters];
    } else {
        // replace originally stored event params with parameters argument
        newParams = [NSMutableDictionary dictionaryWithDictionary:parameters];
    }
    
    // add a "duration" meta-parameter
    [newParams setObject:[NSString stringWithFormat:@"%.2f", duration] forKey:@"duration"];

    // log and process the event
    [self consoleLogEvent:name parameters:newParams timerStarting:NO timerStopping:YES level:level];

    // skip processing at this point for events below the normal logLevel threshold
    if (level < self.logLevel) return;

    [self handleRawEvent:name parameters:newParams level:level wasTimed:YES];
}

- (void)endAllTimedEvents {
    // this is called when the app enters background or is reset.
    // uses the event LIFO to end each event them as if they naturally enclosed
    // each other based on when they were started: timed event 1 starts, timed
    // event 2 starts, timed event 2 ends, timed event 1 ends.
    NSDate *endDate = [NSDate date];
    NSMutableArray *reverseTimedEventKeyLIFO = [NSMutableArray arrayWithCapacity:[self.timedEventKeyLIFO count]];
    NSEnumerator *enumerator = [self.timedEventKeyLIFO reverseObjectEnumerator];
    for (id element in enumerator) {
        [reverseTimedEventKeyLIFO addObject:element];
    }
    int eventsWereEnded = 0;
    for (id key in reverseTimedEventKeyLIFO) {
        NSDictionary *params = [self.timedEventParameters objectForKey:key];
        NSString *name = [self.timedEventNames objectForKey:key];
        [self endTimedEvent:name date:endDate parameters:params merge:NO timerGUID:key];
        eventsWereEnded ++;
    }
    if (eventsWereEnded > 0) [self logVerbose:@"automatically ended %d timed events", eventsWereEnded];
}

#pragma mark session management

- (void)setUserId:(NSString*)userId {
    if (![_userId isEqualToString:userId]) {
        // we've chosen to define a change of identity (log in or out) as a new
        // session. this is not exactly ideal, but it's worse to have sessions
        // in which the user id is not present (or missing) in all events
        // consistently. otherwise it is very difficult on the analytics
        // processing side to correlate sessions to identity. so, close the
        // session and start a new one.
        [self logVerbose:@"user identity is about to change, ending the session first (if any)"];
        [self endSession];
    }
    _userId = userId;
    // note: if we ended a session, a new one will be started automatically on
    // the next logged event. no need explicitly start one here.
}

- (void)startNewSession {
    self.sessionId = [LBUtils generateGUID];
    [self logVerbose:@"generated new session id (%@)", self.sessionId];
    self.sessionActive = YES;
    self.counter = 0;
    NSMutableDictionary *newParams = [NSMutableDictionary dictionaryWithDictionary:self.sessionEventSuperParameters];
    if (self.startSessionEventName)
        [self logEvent:self.startSessionEventName parameters:newParams level:LBEventLevelNormal];
    if (self.endSessionEventName)
        [self startTimedEvent:self.endSessionEventName date:nil parameters:newParams timerGUID:nil level:LBEventLevelNormal];
}

- (void)ensureSessionExists {
    if (!self.sessionId) {
        [self startNewSession];
    }
}

- (void)ensureSessionIsActive {
    [self ensureSessionExists];
    if (self.backgrounded && !self.sessionActive) {
        // note it's not entirely clear what this singleton should do with
        // events fired when backgrounded, since we've already ended the session
        // on backgrounding and don't want to start a new one while
        // backgrounded. as such the event will still use the old (ended)
        // session id, which is not great, but i'm not sure what else to do.
    } else if (!self.sessionActive) {
        [self startNewSession];
    }
}

- (void)endSession {
    [self logVerbose:@"ending any active session"];
    [self endAllTimedEvents];
    self.sessionActive = NO;
}

#pragma mark local/remote log buffer management

- (NSDictionary *)completeRawEventDictionaryForEvent:(NSString *)name parameters:(NSDictionary *)parameters {
    // given a dictionary of regular event parameters, augment it with the
    // contents of bufferedEventSuperParameters and also the "event" param that
    // maps to the name.
    NSMutableDictionary *completeParams = [NSMutableDictionary dictionaryWithDictionary:self.bufferedEventSuperParameters];
    [completeParams addEntriesFromDictionary:parameters];
    if (name && self.bufferedEventParameterKeyForEventName) {
        [completeParams setObject:name forKey:self.bufferedEventParameterKeyForEventName];
    }
    if (self.bufferedEventParameterKeyForUnixTimestamp) {
        [completeParams setObject:[NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]] forKey:self.bufferedEventParameterKeyForUnixTimestamp];
    }
    if (self.bufferedEventParameterKeyForCounter) {
        [completeParams setObject:[NSNumber numberWithLong:self.counter] forKey:self.bufferedEventParameterKeyForCounter];
    }
    return [NSDictionary dictionaryWithDictionary:completeParams];
}

- (void)setMaxBufferSize:(int)maxBufferSize {
    _maxBufferSize = maxBufferSize;
    self.loggerJustBecameFull = NO;
}

- (void)enqueueEvent:(NSString *)name parameters:(NSDictionary *)parameters {
    if (!self.logData) self.logData = [NSMutableArray array];
    if (self.full) {
        [self logVerbose:@"buffer full, discarding this event! (%@)", name];
        return;
    } else if (([self.logData count] >= self.maxBufferSize) && !self.loggerJustBecameFull) {
        // hit the max. log the "we are full event" if self.bufferFullErrorEventName is declared, and stop.
        [self logVerbose:@"buffer full, discarding this event! (%@)", name];
        if (self.bufferFullErrorEventName) {
            self.loggerJustBecameFull = YES;
            [self logEvent:self.bufferFullErrorEventName parameters:nil level:LBEventLevelError];
            self.loggerJustBecameFull = NO;
        }
        self.full = YES;
        return;
    } else {
        // buffer the event for the next sync (could be at max buffer size if loggerJustBecameFull == YES)
        self.loggerJustBecameFull = NO;
        NSDictionary *completeParams = [self completeRawEventDictionaryForEvent:name parameters:parameters];
        [self.logData addObject:completeParams];
        if ([self.logData count] >= self.syncBufferSizeThreshold) {
            [self logVerbose:@"buffered events exceed sync threshold (%d)", self.syncBufferSizeThreshold];
            // sync after a delay so as to allow this event to be fully processed first (with any subclass behaviors)
            int64_t delayInSeconds = 0.1;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self sync];
            });
        }
    }
}

- (void)startTimer {
    if ([self.syncTimer isValid]) return;
    [self.syncTimer invalidate];
    self.syncTimer = [LBTimer scheduledTimerWithTimeInterval:5.0f
                                                      target:self
                                                    selector:@selector(timerTick)
                                                    userInfo:nil
                                                     repeats:YES];
    // tick right now, too.
    [self timerTick];
}

- (void)timerTick {
    if (!self.customBufferedEventUploadsEnabled) return;
    if (self.bufferUploadInProgress) return;
    if (!self.lastSync) self.lastSync = [NSDate date];
    BOOL haveData = ([self.logData count] > 0);
    BOOL isStale = ((self.syncBufferAfterSeconds > 0) && ([self.lastSync timeIntervalSinceNow] < (-1 * self.syncBufferAfterSeconds)));
    BOOL thresholdMet = (self.syncBufferSizeThreshold > 0) && ([self.logData count] >= self.syncBufferSizeThreshold);
    if (haveData && isStale) {
        [self logVerbose:@"buffered events exists and last successful upload was over %d sec ago", self.syncBufferAfterSeconds];
        [self sync];
    } else if (thresholdMet) {
        [self logVerbose:@"buffered events exceed sync threshold (%d)", self.syncBufferSizeThreshold];
        [self sync];
    }
}

- (void)sync {
    if (!self.customBufferedEventUploadsEnabled) return;
    if (!self.logData || ([self.logData count] == 0)) return;
    if (self.bufferUploadInProgress) return; // can't flush right now, an api call is in progress.
    // if we have items to log, move the log data to a silo (syncingLogData)
    // and upload it as transactionally as we can. if the upload fails, we'll
    // prepend the silo buffer back onto the regular active buffer (logData)
    self.syncingLogData = self.logData;
    self.logData = [NSMutableArray array];
    self.bufferUploadInProgress = YES;
    // subclass does the uploading work from here, and either calls either
    // uploadDidSucceed or uploadDidFail.
    [self logVerbose:@"beginning buffered events upload"];
    [self uploadRawEvents:self.syncingLogData];
}

- (void)uploadRawEvents:(NSArray*)events {
    // Subclasses should reimplement this method if they are setting
    // customBufferedEventUploadsEnabled to YES. It's job is to take an array of
    // dictionaries (one dictionary per event) and upload them to a custom
    // collector endpoint such as a REST API. It MUST then call either
    // [self uploadDidSucceed] or [self uploadDidFail]. If it fails to call one
    // of these completion callbacks, this base class assumes the upload is
    // still in progress and no further events will be uploaded.
    LBLog(@"WARNING! LBBaseEventLogger uploadRawEvents: was called. If you've set customBufferedEventUploadsEnabled to YES, you must subclass LBBaseEventLogger and re-implement uploadRawEvents:.");
}

- (void)uploadDidSucceed {
    // subclass implementations of uploadRawEvents: call this when the upload
    // endpoint successfully received the events.
    [self logVerbose:@"buffered events upload succeeded"];
    self.bufferUploadInProgress = NO;
    self.syncingLogData = nil;
    self.full = NO;
    self.lastSync = [NSDate date];
    [self endBgTask];
}

- (void)uploadDidFail {
    // subclass implementations of uploadRawEvents call this when the upload
    // endpoint failed to receive the events.
    [self logVerbose:@"buffered events upload failed, will try again later"];
    self.bufferUploadInProgress = NO;
    if ([self.syncingLogData count] > 0) {
        // move the data we wanted to sync (which failed to upload) back into
        // the regular buffer
        [self.syncingLogData addObjectsFromArray:self.logData];
        self.logData = self.syncingLogData;
        self.syncingLogData = nil;
    }
    [self endBgTask];
}

- (void)endBgTask {
    if (self.bgTask != UIBackgroundTaskInvalid) {
        [self logVerbose:@"ending background task"];
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }
}

#pragma mark convenience methods

- (void)logEvent:(NSString*)name {
    [self logEvent:name parameters:nil level:LBEventLevelNormal];
}

+ (void)logEvent:(NSString*)name {
    [[self sharedInstance] logEvent:name parameters:nil level:LBEventLevelNormal];
}

+ (void)logEvent:(NSString*)name parameters:(NSDictionary *)parameters {
    [[self sharedInstance] logEvent:name parameters:parameters level:LBEventLevelNormal];
}

+ (void)startTimedEvent:(NSString*)name parameters:(NSDictionary *)parameters {
    [[self sharedInstance] startTimedEvent:name date:nil parameters:parameters timerGUID:nil level:LBEventLevelNormal];
}

+ (void)endTimedEvent:(NSString*)name parameters:(NSDictionary *)parameters merge:(BOOL)merge {
    [[self sharedInstance] endTimedEvent:name date:nil parameters:parameters merge:merge timerGUID:nil];
}

+ (void)endTimedEvent:(NSString*)name parameters:(NSDictionary *)parameters {
    if (parameters) {
        // use new params
        [self endTimedEvent:name parameters:parameters merge:NO];
    } else {
        // use old params
        [self endTimedEvent:name parameters:parameters merge:YES];
    }
}

+ (void)logEvent:(NSString*)name textParam:(NSString*)textFormat, ... {
    NSString *text = nil;
    if (textFormat) {
        va_list argumentList;
        va_start(argumentList, textFormat);
        text = [[NSString alloc] initWithFormat:textFormat arguments:argumentList];
    }
    if (text) {
        [[self sharedInstance] logEvent:name parameters:@{@"text":text} level:LBEventLevelNormal];
    } else {
        [[self sharedInstance] logEvent:name parameters:nil level:LBEventLevelNormal];
    }
}

+ (void)logEvent:(NSString*)name parameters:(NSDictionary *)parameters textParam:(NSString*)textFormat, ... {
    NSString *text = nil;
    if (textFormat) {
        va_list argumentList;
        va_start(argumentList, textFormat);
        text = [[NSString alloc] initWithFormat:textFormat arguments:argumentList];
    }
    if (text) {
        NSMutableDictionary *newParams = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [newParams setObject:text forKey:@"text"];
        [[self sharedInstance] logEvent:name parameters:newParams level:LBEventLevelNormal];
    } else {
        [[self sharedInstance] logEvent:name parameters:parameters level:LBEventLevelNormal];
    }
}

+ (void)setUserId:(NSString*)userId {
    [[self sharedInstance] setUserId:userId];
}

+ (NSString*)userId {
    return [[self sharedInstance] userId];
}

@end

