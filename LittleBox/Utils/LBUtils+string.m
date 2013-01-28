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

#import "LBUtils.h"

@implementation LBUtils(string)

+ (NSString *)generateGUID {
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuid));
    CFRelease(uuid);
    return uuidString;
}

+ (NSString*)URLDecodedStringFromString:(NSString*)string {
    if (!string) return nil;
    NSMutableString *newString = [NSMutableString stringWithString:string];
    [newString replaceOccurrencesOfString:@"+" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
    return [newString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)URLEncodedStringFromString:(NSString *)string
{
    if (!string) return nil;
    NSString *result = (NSString *) CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, CFSTR("\":/?#[]@!$&’()*+,;="), kCFStringEncodingUTF8));
    return result;
}

// From: http://www.cocoadev.com/index.pl?BaseSixtyFour
+ (NSString *)base64forData:(NSData*)theData {
    if (!theData) return nil;
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

+ (NSString *)urlEncodedParamStringForDict:(NSDictionary*)dict {
    if (!dict) return nil;
    NSMutableString *paramString = [NSMutableString string];
    NSString *amp = @"";
    for (id key in [dict allKeys]) {
        if ([key isKindOfClass:[NSString class]]) {
            id value = [dict objectForKey:key];
            if ([value isKindOfClass:[NSString class]]) {
                [paramString appendString:amp];
                amp = @"&";
                [paramString appendString:[self URLEncodedStringFromString:(NSString*)key]];
                [paramString appendString:@"="];
                [paramString appendString:[self URLEncodedStringFromString:(NSString*)value]];
            }
        }
    }
    return (NSString*)paramString;
}

+ (NSMutableDictionary *)dictFromQueryString:(NSString *)queryString {
    // Parse a set of url-encoded query string parameters into a dictionary
    if (!queryString) return nil;
    NSArray *pairs = [queryString componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:[pairs count]];
    for (int i = 0; i < [pairs count]; i++) {
        NSArray *kvPair = [[pairs objectAtIndex:i] componentsSeparatedByString:@"="];
        if ([kvPair count] > 0) {
            NSString *strKey = [kvPair objectAtIndex:0];
            NSString *strVal = @"";
            if ([kvPair count] > 1) {
                strVal = [self URLDecodedStringFromString:(NSString *)[kvPair objectAtIndex:1]];
            }
            if ([params objectForKey:strKey]) {
                if (strKey.length > 0)
                    [params setObject:strVal forKey:strKey];
            } else {
                // ignore dupe keys
            }
        }
    }
    return params;
}

@end
