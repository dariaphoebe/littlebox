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

// In order to avoid introducing unwarratend dependencies on CoreLocation for
// people who want to easily import the whole LB* library into their project but
// don't otherwise have a need for CoreLocation, this entire class is omitted
// by default unless the USE_LBCLLOCATIONMANAGERPROXY preprocessor macro is set
// to a true value in your compiler options. Go to your project build settings
// and add "DEFINE_LBCLLOCATIONMANAGERPROXY=1" (without quotes) to the
// "Preprocessor Macros Not Used In Precompiled Headers" section.
#ifdef DEFINE_LBCLLOCATIONMANAGERPROXY

/*

 This is an *experimental* mock object which can be used to simulate location
 changes on a device that can also act as a proxy to a real instance of
 CLLocationManager if desired. We wrote it to help us test some prototyped
 region monitoring (geofencing) code which was a bit obtuse to test otherwise.
 As such it will send location updates and also monitor for region crossings if
 you write a progression of mockLocation values. It's provided here as a
 starting point, and not advised to be considered production quality code. Also,
 not all behaviors of CLLocationManager are fully or correctly mocked, such as
 heading updates. Please inspect the implementation to ensure it is going to
 mock/proxy what you need, and absolutely test your location code using real
 CLLocationManager behaviors whenever possible.
 
 Set the location using the mockLocation property, and note it is only the
 coordinate that matters (accuracy, timestamp, etc, are ignored). In mocked
 mode, callbacks to the CLLocationManagerDelegate location update methods are
 sent on a 2 second timer.
 
 To turn off mock behavior and have this be a straight proxy to the real
 location manager, set mockLocation to nil.
 
 Suggestion: in whatever application code you'd normally use CLLocationManager,
 declare a macro (call it LOC_MGR_CLASS or similar) which resolves to either
 "LBCLLocationManagerProxy" or "CLLocationManager", and toggle the macro to the
 proxy class only in testing and QA cases when you want to mock/debug location
 changes, leaving it pointing to the production class in normal cases. You
 should also declare your CLLocationManagerDelegate to also implement
 LBCLLocationManagerProxyDelegate, which is the same protocol for all intents and
 purposes with only the class of the location manager parameter modified from
 (CLLocationManager*) to (id). E.g.:

 #if DEBUGGING_LOCATION_ENABLED
 #define LOC_MGR_CLASS LBCLLocationManagerProxy
 #else
 #define LOC_MGR_CLASS CLLocationManager
 #end
 
 @interface MyLocationController : UIViewController <CLLocationManagerDelegate,LBCLLocationManagerProxyDelegate>
 @property(nonatomic,strong) LOC_MGR_CLASS* myLocationManager; // will be either a CLLocationManager or a LBCLLocationManagerProxy depending on preprocessor macro
 - (void)locationManager:(id)manager didUpdateLocations:(NSArray *)locations; // serves both CLLocationManagerDelegate and LBCLLocationManagerProxyDelegate
 ...
 @end
 
 TODO:
 - fully mock/proxy all behaviors of CLLocationManager!
 - strive to make this class safe to use all the time, in release code, as a
 pass-through proxy to CLLocationManager when mockLocation is nil.
 
 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "LBTimer.h"

@class LBCLLocationManagerProxy;

@protocol LBCLLocationManagerProxyDelegate <NSObject> // exactly like CLLocationManagerDelegate except the manager param is id vs CLLocationManager so that this clas can pass itself instead of a real CLLocationManager
@optional - (void)locationManager:(id)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status;
@optional - (void)locationManager:(id)manager didEnterRegion:(CLRegion *)region;
@optional - (void)locationManager:(id)manager didExitRegion:(CLRegion *)region;
@optional - (void)locationManager:(id)manager didFailWithError:(NSError *)error;
@optional - (void)locationManager:(id)manager didFinishDeferredUpdatesWithError:(NSError *)error;
@optional - (void)locationManager:(id)manager didStartMonitoringForRegion:(CLRegion *)region;
@optional - (void)locationManager:(id)manager didUpdateHeading:(CLHeading *)newHeading;
@optional - (void)locationManager:(id)manager didUpdateLocations:(NSArray *)locations;
@optional - (void)locationManager:(id)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;
@optional - (void)locationManager:(id)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error;
@optional - (void)locationManagerDidPauseLocationUpdates:(id)manager;
@optional - (void)locationManagerDidResumeLocationUpdates:(id)manager;
@optional - (BOOL)locationManagerShouldDisplayHeadingCalibration:(id)manager;
@end


@interface LBCLLocationManagerProxy : NSObject <CLLocationManagerDelegate>

// pertaining to mock behavior:
@property (nonatomic, strong) CLLocationManager *realManager;
@property (nonatomic, strong) LBTimer *mockTimer;
@property (nonatomic, strong) CLLocation *mockLocation; // if set, the mgr uses this instead of actual device loc
@property (nonatomic, strong) CLLocation *mockLastSentLocation;
@property (nonatomic, assign) BOOL anyLocationUpdatesActive;
@property (nonatomic, assign) BOOL anySignificantLocationChangeUpdatesActive;
@property (weak, nonatomic) id<LBCLLocationManagerProxyDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *mockMonitoredRegions;

// pertaining to the real CLLocationManager. includes deprecated methods/properties:
@property(assign, nonatomic) CLActivityType activityType;
@property(assign, nonatomic) CLLocationAccuracy desiredAccuracy;
@property(assign, nonatomic) CLLocationDistance distanceFilter;
@property(weak, readonly, nonatomic) CLHeading *heading;
@property(assign, nonatomic) CLLocationDegrees headingFilter;
@property(assign, nonatomic) CLDeviceOrientation headingOrientation;
@property(weak, readonly, nonatomic) CLLocation *location;
@property(readonly, nonatomic) CLLocationDistance maximumRegionMonitoringDistance;
@property(weak, readonly, nonatomic) NSSet *monitoredRegions;
@property(assign, nonatomic) BOOL pausesLocationUpdatesAutomatically;
@property(readonly, nonatomic) BOOL headingAvailable;
@property(readonly, nonatomic) BOOL locationServicesEnabled;
@property(copy, nonatomic) NSString *purpose;
+ (CLAuthorizationStatus)authorizationStatus;
+ (BOOL)deferredLocationUpdatesAvailable;
+ (BOOL)headingAvailable;
+ (BOOL)locationServicesEnabled;
+ (BOOL)regionMonitoringAvailable;
+ (BOOL)regionMonitoringEnabled;
+ (BOOL)significantLocationChangeMonitoringAvailable;
- (void)allowDeferredLocationUpdatesUntilTraveled:(CLLocationDistance)distance timeout:(NSTimeInterval)timeout;
- (void)disallowDeferredLocationUpdates;
- (void)dismissHeadingCalibrationDisplay;
- (void)startMonitoringForRegion:(CLRegion *)region;
- (void)startMonitoringSignificantLocationChanges;
- (void)startUpdatingHeading;
- (void)startUpdatingLocation;
- (void)stopMonitoringForRegion:(CLRegion *)region;
- (void)stopMonitoringSignificantLocationChanges;
- (void)stopUpdatingHeading;
- (void)stopUpdatingLocation;
- (void)startMonitoringForRegion:(CLRegion *)region desiredAccuracy:(CLLocationAccuracy)accuracy;

@end

#endif // end ifdef DEFINE_LBCLLOCATIONMANAGERPROXY
