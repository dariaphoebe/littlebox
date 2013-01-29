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

 LBUtils is a grab bag of one-off utility functions. Some of these methods are
 needed so ubiquitiously and are so basic that I'm surprised their
 functionalities are not captured by existing cocoa SDK libraries (such as
 URLDecodedStringFromString). Others are just useful wheels that should not need
 to be reinvented (such as squareCroppedImageFromImage, or
 addOauth1HeaderToRequest), while still others are surprisingly useful shortcuts
 for programmatic manipulation of UIView hierarchies (such as
 setCorrectContentSizeOnScrollView).
 
 All the methods are class methods. There's no need to ever instantiate a
 LBUtils instance.
 
 All methods are defined in category-specific files, see LBUtils+*.m
 
 */

#import <Foundation/Foundation.h>

@interface LBUtils : NSObject
@end

@interface LBUtils(string)
+ (NSString *)generateGUID;
+ (NSString *)URLDecodedStringFromString:(NSString*)string;
+ (NSString *)URLEncodedStringFromString:(NSString *)string;
+ (NSString *)base64forData:(NSData*)theData;
+ (NSString *)urlEncodedParamStringForDict:(NSDictionary*)dict;
+ (NSMutableDictionary *)dictFromQueryString:(NSString *)queryString;
+ (BOOL)string:(NSString *)string contains:(NSString *)substring;
+ (BOOL)stringIsEmpty:(NSString*)str;
+ (NSString*)trimmedString:(NSString*)str;
@end

@interface LBUtils(date)
+ (NSString *)compactTimeOnlyStringForDate:(NSDate*)date;
+ (NSString *)compactDateOnlyStringForDate:(NSDate*)date;
+ (NSString *)compactDateOnlyStringForDate:(NSDate*)date tiny:(BOOL)tiny;
+ (NSString *)compactDateStringForDate:(NSDate*)date;
+ (NSString *)relativeTimeStringSinceNowForDate:(NSDate*)date;
+ (NSString *)relativeTimeStringSinceNowForDate:(NSDate*)date tiny:(BOOL)tiny;
+ (NSDate *)dateFromEpochMillisecondsNSNumber:(NSNumber*)epoch_ms;
+ (NSNumber *)epochMillisFromDate:(NSDate *)date;
@end

@interface LBUtils(image)
+ (UIImage*)squareCroppedImageFromImage:(UIImage*)originalImage withSize:(int)dimension;
@end

@interface LBUtils(oauth10a)
+ (NSDictionary*)queryParamsFromURL:(NSURL*)url;
+ (NSDictionary*)getParamDictFromResponseData:(NSData *)responseData;
+ (void)addPostBodyParams:(NSDictionary*)postBodyParams toRequest:(NSMutableURLRequest*)request;
+ (void)addOauth1HeaderToRequest:(NSMutableURLRequest*)request
              withPostBodyParams:(NSDictionary*)postBodyParams
                oauthConsumerKey:(NSString*)oauthConsumerKey
             oauthConsumerSecret:(NSString*)oauthConsumerSecret
                   oauthCallback:(NSString*)oauthCallback
                   oauthVerifier:(NSString*)oauthVerifier
           accesstOrRequestToken:(NSString*)accesstOrRequestToken
     accesssOrRequestTokenSecret:(NSString*)accesssOrRequestTokenSecret;
@end

@interface LBUtils(cgrect)
+ (NSString*)stringForRect:(CGRect)rect;
+ (NSString*)stringForSize:(CGSize)size;
+ (CGRect)rectFromRect:(CGRect)rect newOriginX:(float)xOffset;
+ (CGRect)rectFromRect:(CGRect)rect newOriginY:(float)yOffset;
+ (CGRect)rectFromRect:(CGRect)rect newWidth:(float)width;
+ (CGRect)rectFromRect:(CGRect)rect newHeight:(float)height;
+ (CGRect)rectForUITextViewWithMarginOffsetsAndSizedHeight:(UITextView*)textView;
+ (void)autoAdjustHeightForUnlimitedLinesUILabel:(UILabel*)label;
+ (void)autoAdjustHeightForUnlimitedLinesUILabelUnlimitedHeight:(UILabel*)label;
+ (void)setCorrectContentSizeOnScrollView:(UIScrollView*)scrollView ensureScrollable:(BOOL)ensureScrollable;
@end
