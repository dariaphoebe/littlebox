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
#import "LBUtils.h"

@implementation LBUtils(date)

+ (NSString *)compactTimeOnlyStringForDate:(NSDate*)date {
    // optimized for compact display to maximize real estate
    // this should return strings like:
    // 6pm              (if :00 minutes)
    // 6:30pm           (if not :00 minutes)
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setCalendar:[NSCalendar currentCalendar]];
    [outputFormatter setTimeZone:[NSTimeZone localTimeZone]];
    [outputFormatter setDateFormat:@"h"];
    NSString *hour = [outputFormatter stringFromDate:date];
    [outputFormatter setDateFormat:@"mm"];
    NSString *minute = [outputFormatter stringFromDate:date];
    if ([minute isEqual:@"00"]) {
        minute = @"";
    } else {
        minute = [@":" stringByAppendingString:minute];
    }
    [outputFormatter setDateFormat:@"a"];
    NSString *ampm = [[outputFormatter stringFromDate:date] lowercaseString];
    return [NSString stringWithFormat:@"%@%@ %@", hour, minute, ampm];
}

+ (NSString *)compactDateOnlyStringForDate:(NSDate*)date {
    return [self compactDateOnlyStringForDate:date tiny:NO];
}

+ (NSString *)compactDateOnlyStringForDate:(NSDate*)date tiny:(BOOL)tiny {
    // optimized for compact display to maximize real estate
    // this should return strings like:
    // Sat Jan 21st
    // Sat Jan 20th
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setCalendar:[NSCalendar currentCalendar]];
    [outputFormatter setTimeZone:[NSTimeZone localTimeZone]];
    [outputFormatter setDateFormat:@"eee"];
    NSString *dayName = [outputFormatter stringFromDate:date];
    [outputFormatter setDateFormat:@"MMM"];
    NSString *month = [outputFormatter stringFromDate:date];
    [outputFormatter setDateFormat:@"M"];
    NSString *monthNum = [outputFormatter stringFromDate:date];
    [outputFormatter setDateFormat:@"dd"]; // day of the month, but strip leading zeros by doing an int conversion and back
    NSString *dayNum = [NSString stringWithFormat:@"%d",[[outputFormatter stringFromDate:date] intValue]];
    NSString *daySuffix = @"th";
    if ([dayNum isEqual:@"10"] || [dayNum isEqual:@"11"] || [dayNum isEqual:@"12"] || [dayNum isEqual:@"13"]) {
        daySuffix = @"th";
    } else if ([dayNum rangeOfString:@"1"].location == ([dayNum length]-1)) {
        daySuffix = @"st";
    } else if ([dayNum rangeOfString:@"2"].location == ([dayNum length]-1)) {
        daySuffix = @"nd";
    } else if ([dayNum rangeOfString:@"3"].location == ([dayNum length]-1)) {
        daySuffix = @"rd";
    }
    // note: omit year because it takes up a lot of real estate and in practice
    // it will be clear enough from the month if the date is for a different
    // year.
    if (tiny) {
        return [NSString stringWithFormat:@"%@/%@", monthNum, dayNum];
    } else {
        return [NSString stringWithFormat:@"%@ %@ %@%@", dayName, month, dayNum, daySuffix];
    }
}

+ (NSString *)compactDateStringForDate:(NSDate*)date {
    // compact date comma compact time
    return [NSString stringWithFormat:@"%@, %@",
            [self compactDateOnlyStringForDate:date],
            [self compactTimeOnlyStringForDate:date]];
}

+ (NSString *)relativeTimeStringSinceNowForDate:(NSDate*)date {
    return [self relativeTimeStringSinceNowForDate:date tiny:NO];
}

+ (NSString *)relativeTimeStringSinceNowForDate:(NSDate*)date tiny:(BOOL)tiny {
    // returns strings like:
    // just now
    // 1 min ago
    // 4 hrs ago
    // 3 days ago
    // and if tiny==YES:
    // now
    // 1 min
    // 4 hrs
    // 3 days
    // ...
    // switches to compactDateOnlyStringForDate if over a month ago
    double delta = [date timeIntervalSinceNow] * -1;
    if (delta < 60) {
        if (tiny) {
            return @"now";
        } else {
            return @"just now";
        }
    }
    if (delta < 60*60) {
        int minutes = (int)(delta / 60.0);
        if (minutes > 1) {
            if (tiny) {
                return [NSString stringWithFormat:@"%d mins",minutes];
            } else {
                return [NSString stringWithFormat:@"%d mins ago",minutes];
            }
        } else {
            if (tiny) {
                return @"1 min";
            } else {
                return @"1 min ago";
            }
        }
    }
    if (delta < 60*60*24) {
        int hours = (int)(delta / (60.0*60.0));
        if (hours > 1) {
            if (tiny) {
                return [NSString stringWithFormat:@"%d hrs",hours];
            } else {
                return [NSString stringWithFormat:@"%d hrs ago",hours];
            }
        } else {
            if (tiny) {
                return @"1hr";
            } else {
                return @"1 hr ago";
            }
        }
    }
    if (delta < 60*60*24*7) {
        int days = (int)(delta / (60.0*60.0*24));
        if (days > 1) {
            if (tiny) {
                return [NSString stringWithFormat:@"%d days",days];
            } else {
                return [NSString stringWithFormat:@"%d days ago",days];
            }
        } else {
            if (tiny) {
                return @"1 day";
            } else {
                return @"1 day ago";
            }
        }
    }
    if (delta < 60*60*24*7*4) {
        int weeks = (int)(delta / (60.0*60.0*24*7));
        if (weeks > 1) {
            if (tiny) {
                return [NSString stringWithFormat:@"%d wks",weeks];
            } else {
                return [NSString stringWithFormat:@"%d wks ago",weeks];
            }
        } else {
            if (tiny) {
                return @"1 wk";
            } else {
                return @"1 wk ago";
            }
        }
    }
    // if over a month ago, return the compact date (but without time of day)
    return [self compactDateOnlyStringForDate:date tiny:tiny];
}

+ (NSDate *)dateFromEpochMillisecondsNSNumber:(NSNumber*)epoch_ms {
    // yikes. isn't there a better way? problem is that dividing by 1000 with
    // normal (objective-)c numbers produces rounding inaccuracies that result
    // in dates like 5:59PM when it should be 6:00PM. for instance:
    // 1297994400000 / 1000.0 -> 1297994350.592
    return [NSDate dateWithTimeIntervalSince1970:
            [[[NSDecimalNumber decimalNumberWithDecimal:[epoch_ms decimalValue]]
              decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithInt:1000]] doubleValue]];
}

+ (NSNumber *)epochMillisFromDate:(NSDate *)date {
    NSNumber *epochMillis = [NSNumber numberWithDouble:([date timeIntervalSince1970] * 1000)];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setRoundingMode:NSNumberFormatterRoundHalfUp];
    [formatter setMaximumFractionDigits:0];
    NSNumber *rounded = [formatter numberFromString:[formatter stringFromNumber:epochMillis]];
    return rounded;
}

@end
