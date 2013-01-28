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

#import "LBGlobalFullScreenSpinner.h"

@implementation LBGlobalFullScreenSpinner

LB_DECLARE_SHARED_INSTANCE_M(LBGlobalFullScreenSpinner)

- (void)initialInit {
    [super initialInit];
    self.resetOrder = LBResetOrderGroup5;
}

- (void)reusableInit {
    [super reusableInit];
    self.alternateGlobalSpinnerDelegate = nil;
    self.activeUseCases = [NSMutableDictionary dictionary];
    self.activeSuppressionUseCases = [NSMutableDictionary dictionary];
    self.spinner = [[LBStyledActivityIndicator alloc] init];
    self.spinner.style = LBStyledActivityIndicatorStyleFull;
    self.spinnerIsActive = NO;
    self.lastSentBool = NO;
    self.useDelayToMitigateForFlashing = YES;
}

- (void)reusableTeardown {
    self.alternateGlobalSpinnerDelegate = nil;
    self.activeUseCases = nil;
    self.activeSuppressionUseCases = nil;
    self.spinnerIsActive = NO;
    [self.spinner stop];
    self.spinner = nil;
    [super reusableTeardown];
}

- (void)registerActiveUseCase:(NSString*)useCase {
    if (!useCase) return;
    if ([NSThread isMainThread]) {
        [self.activeUseCases setObject:@"holder" forKey:useCase];
        [self updateSpinnerIsActive];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activeUseCases setObject:@"holder" forKey:useCase];
            [self updateSpinnerIsActive];
        });
    }
}

- (void)unregisterInactiveUseCase:(NSString*)useCase {
    if (!useCase) return;
    if ([NSThread isMainThread]) {
        [self.activeUseCases removeObjectForKey:useCase];
        [self updateSpinnerIsActive];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activeUseCases removeObjectForKey:useCase];
            [self updateSpinnerIsActive];
        });
    }
}

- (void)registerActiveSuppressionUseCase:(NSString*)useCase {
    if ([NSThread isMainThread]) {
        [self.activeSuppressionUseCases setObject:@"holder" forKey:useCase];
        [self updateSpinnerIsActive];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activeSuppressionUseCases setObject:@"holder" forKey:useCase];
            [self updateSpinnerIsActive];
        });
    }
}

- (void)unregisterInactiveSuppressionUseCase:(NSString*)useCase {
    if ([NSThread isMainThread]) {
        [self.activeSuppressionUseCases removeObjectForKey:useCase];
        [self updateSpinnerIsActive];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activeSuppressionUseCases removeObjectForKey:useCase];
            [self updateSpinnerIsActive];
        });
    }
}

+ (void)registerActiveUseCase:(NSString*)useCase {
    [[self sharedInstance] registerActiveUseCase:useCase];
}

+ (void)unregisterInactiveUseCase:(NSString*)useCase {
    [[self sharedInstance] unregisterInactiveUseCase:useCase];
}

+ (void)registerActiveSuppressionUseCase:(NSString*)useCase {
    [[self sharedInstance] registerActiveSuppressionUseCase:useCase];
}

+ (void)unregisterInactiveSuppressionUseCase:(NSString*)useCase {
    [[self sharedInstance] unregisterInactiveSuppressionUseCase:useCase];
}

- (void)updateSpinnerIsActive {
    self.spinnerIsActive = (([self.activeUseCases count] > 0) && ([self.activeSuppressionUseCases count] == 0));
}

- (void)setSpinnerIsActive:(BOOL)spinnerIsActive {
    BOOL wasActive = _spinnerIsActive;
    _spinnerIsActive = spinnerIsActive;
    if (_spinnerIsActive != wasActive) {
        // we just want this to run in the next run loop to give time for code
        // remaining to be executed in this runloop to register new spinner use
        // cases. also this prevents unexpected scenarios where a callback to
        // the delegate is done synchronously as a result of spinner state
        // twiddling. note that this deferred method is just the view update
        // signal, the actual boolean (_spinnerIsActive) has already been set as
        // to whether the spinner should be visible.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateSpinnerViewState];
        });
    }
}

- (void)updateSpinnerViewState {
    if (self.spinnerIsActive != self.lastSentBool) {
        self.lastSentBool = self.spinnerIsActive;
        if (self.alternateGlobalSpinnerDelegate) {
            [self.alternateGlobalSpinnerDelegate alternateGlobalSpinnerShouldShow:self.spinnerIsActive];
        }
        if (!self.alternateGlobalSpinnerDelegate && self.spinnerIsActive) {
            [self.spinner startSpinningInView:[[UIApplication sharedApplication] keyWindow] withFadeIn:YES];
        } else {
            [self.spinner stopWithFade:YES];
        }
    }
}

+ (void)setAlternateGlobalSpinnerDelegate:(id<AlternateGlobalSpinnerDelegateProtocol>)delegate {
    [[self sharedInstance] setAlternateGlobalSpinnerDelegate:delegate];
}

@end
