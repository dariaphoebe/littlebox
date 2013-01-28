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

// see header for explanation of DEFINE_LBCLLOCATIONMANAGERPROXY flag
#ifdef DEFINE_LBCLLOCATIONMANAGERPROXY

// supress deprecation warnings. this class is just being a faithful proxy to
// the available methods on CLLocationManager. TODO: use message forwarding so
// we don't have to explicitly declare and call these deprecated methods.
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

#import "LBCLLocationManagerProxy.h"

@implementation LBCLLocationManagerProxy

- (id)init {
    if ((self = [super init])) {
        self.realManager = [[CLLocationManager alloc] init];
        self.realManager.delegate = self;
    }
    return self;
}

#pragma mark mock behavior

- (void)setMockLocation:(CLLocation *)mockLocation {
    CLLocation *oldMockLocation = _mockLocation;
    CLLocation *effectiveOldLocation = oldMockLocation;
    CLLocation *effectiveNewLocation = mockLocation;
    if (_mockLocation != mockLocation) {
        _mockLocation = mockLocation;
    }
    if (!oldMockLocation && _mockLocation) {
        // switch to mock mode
        self.mockMonitoredRegions = [NSMutableArray array];
        for (CLRegion* region in self.realManager.monitoredRegions) {
            [self.mockMonitoredRegions addObject:region];
        }
        self.mockTimer = [LBTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(mockTimerPing) userInfo:nil repeats:YES];
        self.mockLastSentLocation = nil;
        effectiveOldLocation = self.realManager.location; // trigger region crossings / updates on a shift from real to mock loc
    }
    NSArray *checkRegions = self.mockMonitoredRegions;
    if (oldMockLocation && !_mockLocation) {
        // return to real mode
        [self.mockTimer invalidate];
        self.mockTimer = nil;
        self.mockMonitoredRegions = nil;
        self.mockLastSentLocation = nil;
        if (self.realManager.location) {
            // trigger region crossings / updates on a shift from mock back to real loc. these will be the last "fake" signals the delegate gets, and are sent just to maintain an apparently consistent behavior during the real/mock mode switch. it's not perfect: if the real location has moved outside of really monitored regions that the mock location is also outside of, those real region crossings will not be fired.
            effectiveNewLocation = [[CLLocation alloc] initWithCoordinate:self.realManager.location.coordinate altitude:0.0f horizontalAccuracy:10.0f verticalAccuracy:10.0f timestamp:[NSDate date]]; // give it a fresh timestamp and high accuracy
        }
    }
    if (effectiveOldLocation && effectiveNewLocation && ([effectiveOldLocation distanceFromLocation:effectiveNewLocation] > 0.0)) {
        int64_t delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        // emit loc update if one or more svcs is active
        if (self.anyLocationUpdatesActive || self.anySignificantLocationChangeUpdatesActive) {
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                if ([self.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
                    [self.delegate locationManager:self didUpdateLocations:[NSArray arrayWithObject:effectiveNewLocation]];
                } else if ([self.delegate respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)]) {
                    [self.delegate locationManager:self didUpdateToLocation:effectiveNewLocation fromLocation:effectiveOldLocation];
                }
            });
        }
        // emit any necessary region crossings
        for (CLRegion* region in checkRegions) {
            if (![region containsCoordinate:effectiveOldLocation.coordinate] && [region containsCoordinate:effectiveNewLocation.coordinate]) {
                // enter
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    if ([self.delegate respondsToSelector:@selector(locationManager:didEnterRegion:)]) {
                        [self.delegate locationManager:self didEnterRegion:region];
                    }
                });
            } else if ([region containsCoordinate:effectiveOldLocation.coordinate] && ![region containsCoordinate:effectiveNewLocation.coordinate]) {
                // exit
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    if ([self.delegate respondsToSelector:@selector(locationManager:didExitRegion:)]) {
                        [self.delegate locationManager:self didExitRegion:region];
                    }
                });
            }
        }
    }
}

- (void)mockTimerPing {
    if (self.anyLocationUpdatesActive || self.anySignificantLocationChangeUpdatesActive) {
        if (!self.mockLastSentLocation || (self.mockLastSentLocation != self.mockLocation)) {
            self.mockLastSentLocation = self.mockLocation;
            [self.delegate locationManager:self didUpdateLocations:[NSArray arrayWithObject:[[CLLocation alloc] initWithCoordinate:self.mockLocation.coordinate altitude:0.0f horizontalAccuracy:10.0f verticalAccuracy:10.0f timestamp:[NSDate date]]]];
        }
    }
}


#pragma mark property proxies

- (void)setActivityType:(CLActivityType)activityType {
    // ios 6+
    [self.realManager setActivityType:activityType];
}

- (CLActivityType)activityType {
    // ios 6+
    return [self.realManager activityType];
}

- (void)setDesiredAccuracy:(CLLocationAccuracy)desiredAccuracy {
    [self.realManager setDesiredAccuracy:desiredAccuracy];
}

- (CLLocationAccuracy)desiredAccuracy {
    return [self.realManager desiredAccuracy];
}

- (void)setDistanceFilter:(CLLocationDistance)distanceFilter {
    [self.realManager setDistanceFilter:distanceFilter];
}

- (CLLocationDistance)distanceFilter {
    return [self.realManager distanceFilter];
}

- (CLHeading*)heading {
    return [self.realManager heading];
}

- (void)setHeadingFilter:(CLLocationDegrees)headingFilter {
    [self.realManager setHeadingFilter:headingFilter];
}

- (CLLocationDegrees)headingFilter {
    return [self.realManager headingFilter];
}

- (void)setHeadingOrientation:(CLDeviceOrientation)headingOrientation {
    [self.realManager setHeadingOrientation:headingOrientation];
}

- (CLDeviceOrientation)headingOrientation {
    return [self.realManager headingOrientation];
}

- (CLLocation *)location {
    if (self.mockLocation) {
        return [[CLLocation alloc] initWithCoordinate:self.mockLocation.coordinate altitude:0.0f horizontalAccuracy:10.0f verticalAccuracy:10.0f timestamp:[NSDate date]];
    } else {
        return [self.realManager location];
    }
}

- (CLLocationDistance)maximumRegionMonitoringDistance {
    return [self.realManager maximumRegionMonitoringDistance];
}

- (NSSet*)monitoredRegions {
    if (self.mockLocation) {
        if (self.mockMonitoredRegions) {
            return [NSSet setWithArray:self.mockMonitoredRegions];
        } else {
            return [NSSet set];
        }
    } else {
        return [self.realManager monitoredRegions];
    }
}

- (void)setPausesLocationUpdatesAutomatically:(BOOL)pausesLocationUpdatesAutomatically {
    // ios 6+
    [self.realManager setPausesLocationUpdatesAutomatically:pausesLocationUpdatesAutomatically];
}

- (BOOL)pausesLocationUpdatesAutomatically {
    // ios 6+
    return [self.realManager pausesLocationUpdatesAutomatically];
}

- (BOOL)headingAvailable {
    return [self.realManager headingAvailable];
}

- (BOOL)locationServicesEnabled {
    return [self.realManager locationServicesEnabled];
}

- (void)setPurpose:(NSString *)purpose {
    [self.realManager setPurpose:purpose];
}

- (NSString*)purpose {
    return [self.realManager purpose];    
}

#pragma mark class method proxies

+ (CLAuthorizationStatus)authorizationStatus {
    return [CLLocationManager authorizationStatus];
}

+ (BOOL)deferredLocationUpdatesAvailable {
    // ios 6+
    return [CLLocationManager deferredLocationUpdatesAvailable];
}

+ (BOOL)headingAvailable {
    return [CLLocationManager headingAvailable];
}

+ (BOOL)locationServicesEnabled {
    return [CLLocationManager locationServicesEnabled];
}

+ (BOOL)regionMonitoringAvailable {
    return [CLLocationManager regionMonitoringAvailable];
}

+ (BOOL)regionMonitoringEnabled {
    return [CLLocationManager regionMonitoringEnabled];
}

+ (BOOL)significantLocationChangeMonitoringAvailable {
    return [CLLocationManager significantLocationChangeMonitoringAvailable];
}

#pragma mark instance method proxies

- (void)allowDeferredLocationUpdatesUntilTraveled:(CLLocationDistance)distance timeout:(NSTimeInterval)timeout {
    // ios 6+
    [self.realManager allowDeferredLocationUpdatesUntilTraveled:distance timeout:timeout];
}

- (void)disallowDeferredLocationUpdates {
    // ios 6+
    [self.realManager disallowDeferredLocationUpdates];
}

- (void)dismissHeadingCalibrationDisplay {
    [self.realManager dismissHeadingCalibrationDisplay];
}

- (void)startMonitoringForRegion:(CLRegion *)region {
    if (self.mockLocation) {
        if (![self.mockMonitoredRegions containsObject:region]) {
            [self.mockMonitoredRegions addObject:region];
        }
    }
    [self.realManager startMonitoringForRegion:region];
}

- (void)startMonitoringForRegion:(CLRegion *)region desiredAccuracy:(CLLocationAccuracy)accuracy {
    if (self.mockLocation) {
        [self startMonitoringForRegion:region];
    }
    [self.realManager startMonitoringForRegion:region desiredAccuracy:accuracy];
}


- (void)startMonitoringSignificantLocationChanges {
    self.anySignificantLocationChangeUpdatesActive = YES;
    if (self.mockLocation) {
        self.mockLastSentLocation = nil;
    }
    [self.realManager startMonitoringSignificantLocationChanges];
}

- (void)startUpdatingHeading {
    [self.realManager startUpdatingHeading];
}

- (void)startUpdatingLocation {
    self.anyLocationUpdatesActive = YES;
    if (self.mockLocation) {
        self.mockLastSentLocation = nil;
    }
    [self.realManager startUpdatingLocation];
}

- (void)stopMonitoringForRegion:(CLRegion *)region {
    if (self.mockLocation) {
        [self.mockMonitoredRegions removeObject:region];
    }
    [self.realManager stopMonitoringForRegion:region];
}

- (void)stopMonitoringSignificantLocationChanges {
    self.anySignificantLocationChangeUpdatesActive = NO;
    [self.realManager stopMonitoringSignificantLocationChanges];
}

- (void)stopUpdatingHeading {
    [self.realManager stopUpdatingHeading];
}

- (void)stopUpdatingLocation {
    self.anyLocationUpdatesActive = NO;
    [self.realManager stopUpdatingLocation];
}

#pragma mark delegate methods proxy

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if ([self.delegate respondsToSelector:@selector(locationManager:didChangeAuthorizationStatus:)]) {
        [self.delegate locationManager:self didChangeAuthorizationStatus:status];
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    if (self.mockLocation) return;
    if ([self.delegate respondsToSelector:@selector(locationManager:didEnterRegion:)]) {
        [self.delegate locationManager:self didEnterRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if (self.mockLocation) return;
    if ([self.delegate respondsToSelector:@selector(locationManager:didExitRegion:)]) {
        [self.delegate locationManager:self didExitRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if (self.mockLocation) return;
    if ([self.delegate respondsToSelector:@selector(locationManager:didFailWithError:)]) {
        [self.delegate locationManager:self didFailWithError:error];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error {
    // ios 6+
    if (self.mockLocation) return;
    if ([self.delegate respondsToSelector:@selector(locationManager:didFinishDeferredUpdatesWithError:)]) {
        [self.delegate locationManager:self didFinishDeferredUpdatesWithError:error];
    }
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    if (self.mockLocation) return;
    if ([self.delegate respondsToSelector:@selector(locationManager:didStartMonitoringForRegion:)]) {
        [self.delegate locationManager:self didStartMonitoringForRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    if ([self.delegate respondsToSelector:@selector(locationManager:didUpdateHeading:)]) {
        [self.delegate locationManager:self didUpdateHeading:newHeading];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (self.mockLocation) return;
    if ([self.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
        [self.delegate locationManager:self didUpdateLocations:locations];
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    if (self.mockLocation) return;
    if ([self.delegate respondsToSelector:@selector(locationManager:monitoringDidFailForRegion:withError:)]) {
        [self.delegate locationManager:self monitoringDidFailForRegion:region withError:error];
    }
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
    if (self.mockLocation) return;
    if ([self.delegate respondsToSelector:@selector(locationManagerDidPauseLocationUpdates:)]) {
        [self.delegate locationManagerDidPauseLocationUpdates:self];
    }
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
    if (self.mockLocation) return;
    if ([self.delegate respondsToSelector:@selector(locationManagerDidResumeLocationUpdates:)]) {
        [self.delegate locationManagerDidResumeLocationUpdates:self];
    }
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
    if ([self.delegate respondsToSelector:@selector(locationManagerShouldDisplayHeadingCalibration:)]) {
        return [self.delegate locationManagerShouldDisplayHeadingCalibration:self];
    } else {
        return NO;
    }
}

#pragma mark dealloc

- (void)dealloc {
    // just need to stop any active timer
    [self.mockTimer invalidate];
}

// restore deprecation warnings
#pragma GCC diagnostic warning "-Wdeprecated-declarations"

@end

#endif // end ifdef USE_LBCLLOCATIONMANAGERPROXY
