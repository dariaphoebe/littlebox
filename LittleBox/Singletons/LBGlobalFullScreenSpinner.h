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

 This singleton presents a full-screen LBStyledActivityIndicator on top of
 the main window of the application when any active "use case" is registered.
 A use case is a string identifier that your application defines for a condition
 under which the spinner should be shown. For instance @"logging in" might be a
 use case. When log in starts, you call registerActiveUseCase:@"logging in" and
 it will cover the screen, then when log in is finished, you call
 unregisterInactiveUseCase:@"logging in" and the spinner goes away. We recommend
 declaring all your use cases as string constants in a header file somewhere, so
 you can easily find and audit them, as opposed to using inline strings.
 
 The spinner blocks interaction on the screen and will present on top of
 everything else.
 
 In the Klout app, we use this in multiple cases. For instance, we have logic
 that allows users to pair their Klout account with third party networks
 (Twitter, Facebook, etc) and those pairing flows can be triggered from multiple
 places within the app (initial sign in, profile tab, viral sharing buttons,
 etc), but these flows require network communication that the user must wait
 for. In order to block UI interactivity reliably using shared pairing code that
 can execute from anywhere in the app, we toss up this global spinner from the
 pairing code as needed. This way, not every view controller that invokes
 pairing flows needs to understand precisely when and how to present the
 UI-blocking spinner.

 For extra credit, this class also implements "suppression" use cases, which
 if any are registered, *prevent* the spinner from otherwise showing. Why?
 Imagine you're in a complex pairing flow that has the spinner showing while
 we wait for the Twitter or Facebook API/SDK to return some critical user
 or auth information, but then there's a network timeout. We want to pop
 a UIAlertView to the user asking them if they want to retry the call or cancel
 -- but there's a full screen spinner blocking any such UI. We can register a
 suppression use case for the alertview, which is then unregistered when the
 alert is dismissed.
 
 Last but not least, in some cases we want to use this globally managed spinner
 logic, but have the spinner present in a different visual style than a full
 screen LBStyledActivityIndicator, so there is a
 AlternateGlobalSpinnerDelegateProtocol which allows any arbitrary application
 object to manage presentation of the spinner if desired. We use this in the
 initial application sign in sequence controller, for which we have a dedicated
 spinner overlayed on a splash screen graphic.
 
 */

#import <Foundation/Foundation.h>
#import "LBBaseSingleton.h"
#import "LBStyledActivityIndicator.h"

@protocol AlternateGlobalSpinnerDelegateProtocol <NSObject>
- (void)alternateGlobalSpinnerShouldShow:(BOOL)shouldShow;
@end

@interface LBGlobalFullScreenSpinner : LBBaseSingleton

LB_DECLARE_SHARED_INSTANCE_H(LBGlobalFullScreenSpinner)

@property (nonatomic, strong) NSMutableDictionary *activeUseCases;
@property (nonatomic, strong) NSMutableDictionary *activeSuppressionUseCases;
@property (nonatomic, assign) BOOL spinnerIsActive;
@property (nonatomic, assign) BOOL lastSentBool;
@property (nonatomic, strong) LBStyledActivityIndicator *spinner;
@property (nonatomic, weak) id<AlternateGlobalSpinnerDelegateProtocol> alternateGlobalSpinnerDelegate;
@property (nonatomic, assign) BOOL useDelayToMitigateForFlashing;

+ (void)registerActiveUseCase:(NSString*)useCase;
+ (void)unregisterInactiveUseCase:(NSString*)useCase;
- (void)registerActiveUseCase:(NSString*)useCase;
- (void)unregisterInactiveUseCase:(NSString*)useCase;
+ (void)registerActiveSuppressionUseCase:(NSString*)useCase;
+ (void)unregisterInactiveSuppressionUseCase:(NSString*)useCase;
- (void)registerActiveSuppressionUseCase:(NSString*)useCase;
- (void)unregisterInactiveSuppressionUseCase:(NSString*)useCase;

+ (void)setAlternateGlobalSpinnerDelegate:(id<AlternateGlobalSpinnerDelegateProtocol>)delegate;

@end
