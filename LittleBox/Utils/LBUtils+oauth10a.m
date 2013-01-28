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
 
 These utility methods handle the hardest part of the basics involved in
 interfacing with Oauth 1.0a webservices using standard NSMutaleURLRequest
 objects, namely: generating oauth headers and signatures.
 
 They do not magically manage the end-to-end Oauth1.0a request flow for you,
 unlike some oauth libraries/frameworks. Many folks will prefer to use a more
 comprehensive library, but those libraries come at a high cost of opacity and
 code complexity, learning curves, and unexpected behaviors, as well as frequent
 difficulty integrating to your specific use cases and network connection
 approach.
 
 Generating the headers and signatures correctly really is the hardest part of
 OAuth 1.0a, so hopefully these methods can provide some value to those who
 prefer to stay closer to the metal, and who don't mind using NSURLConnection /
 NSMutableURLRequest for the network layer.
 
 */

#import "LBUtils.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation LBUtils(oauth10a)

+ (NSDictionary*)queryParamsFromURL:(NSURL*)url {
    NSArray *parts = [[url absoluteString] componentsSeparatedByString:@"?"];
    NSDictionary *params = [NSDictionary dictionary];
    if ([parts count] > 1) {
        params = [LBUtils dictFromQueryString:[parts objectAtIndex:1]];
    }
    return params;
}

+ (NSDictionary*)getParamDictFromResponseData:(NSData *)responseData {
    NSDictionary *params = nil;
    if (responseData && [responseData length] > 0) {
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        // assumes this is an x-www-form-urlencoded response, which is parsed just like a querystring
        params = [LBUtils dictFromQueryString:responseString];
    }
    return params;
}

+ (void)addPostBodyParams:(NSDictionary*)postBodyParams toRequest:(NSMutableURLRequest*)request {
    NSData *postData = [[LBUtils urlEncodedParamStringForDict:postBodyParams] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];        
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
}

+ (void)addOauth1HeaderToRequest:(NSMutableURLRequest*)request
              withPostBodyParams:(NSDictionary*)postBodyParams
                oauthConsumerKey:(NSString*)oauthConsumerKey
             oauthConsumerSecret:(NSString*)oauthConsumerSecret
                   oauthCallback:(NSString*)oauthCallback
                   oauthVerifier:(NSString*)oauthVerifier
           accesstOrRequestToken:(NSString*)accesstOrRequestToken
     accesssOrRequestTokenSecret:(NSString*)accesssOrRequestTokenSecret
{
    // modifies an NSMutableURLRequest to add the oauth 1.0 authorization header
    
    // build the basic set of oauth params, without the signature
    NSMutableDictionary *oauthParams = [NSMutableDictionary dictionary];
    [oauthParams setObject:oauthConsumerKey forKey:@"oauth_consumer_key"];
    [oauthParams setObject:@"HMAC-SHA1" forKey:@"oauth_signature_method"];
    [oauthParams setObject:[NSString stringWithFormat:@"%0.0f",[[NSDate date] timeIntervalSince1970]] forKey:@"oauth_timestamp"];
    [oauthParams setObject:[LBUtils generateGUID] forKey:@"oauth_nonce"];
    [oauthParams setObject:@"1.0" forKey:@"oauth_version"];
    if (oauthCallback) {
        [oauthParams setObject:oauthCallback forKey:@"oauth_callback"];
    }
    if (oauthVerifier) {
        [oauthParams setObject:oauthVerifier forKey:@"oauth_verifier"];
    }
    if (accesstOrRequestToken) {
        [oauthParams setObject:accesstOrRequestToken forKey:@"oauth_token"];
    }
    
    // parse and merge in any querystring or post body params
    NSMutableDictionary *mergedParams = [NSMutableDictionary dictionaryWithDictionary:oauthParams];
    NSDictionary *queryParams = [self queryParamsFromURL:[[request URL] absoluteURL]];
    if (queryParams) [mergedParams addEntriesFromDictionary:queryParams];
    if (postBodyParams) [mergedParams addEntriesFromDictionary:postBodyParams];
    
    // generate signature
    NSString *baseString = [self signatureBaseStringWithRequest:request params:mergedParams];
    NSString *signature = [self signClearText:baseString withSecret:[NSString stringWithFormat:@"%@&%@",
                                                                     [LBUtils URLEncodedStringFromString:oauthConsumerSecret],
                                                                     [LBUtils URLEncodedStringFromString:(accesssOrRequestTokenSecret ? accesssOrRequestTokenSecret : @"")]]];
    [oauthParams setObject:signature forKey:@"oauth_signature"];
    
    // generate oauth header
    NSString *tokenPair = @"";
    NSString *callbackPair = @"";
    NSString *verifierPair = @"";
    if ([oauthParams objectForKey:@"oauth_token"] && ![[oauthParams objectForKey:@"oauth_token"] isEqual:@""]) {
        tokenPair = [NSString stringWithFormat:@"oauth_token=\"%@\", ",[LBUtils URLEncodedStringFromString:[oauthParams objectForKey:@"oauth_token"]]];
    }
    if ([oauthParams objectForKey:@"oauth_callback"] && ![[oauthParams objectForKey:@"oauth_callback"] isEqual:@""]) {
        callbackPair = [NSString stringWithFormat:@"oauth_callback=\"%@\", ",[LBUtils URLEncodedStringFromString:[oauthParams objectForKey:@"oauth_callback"]]];
    }
    if ([oauthParams objectForKey:@"oauth_verifier"] && ![[oauthParams objectForKey:@"oauth_verifier"] isEqual:@""]) {
        verifierPair = [NSString stringWithFormat:@"oauth_verifier=\"%@\", ",[LBUtils URLEncodedStringFromString:[oauthParams objectForKey:@"oauth_verifier"]]];
    }
    NSString *oauthHeader = [NSString stringWithFormat:@"OAuth realm=\"\", %@oauth_consumer_key=\"%@\", %@%@oauth_signature_method=\"HMAC-SHA1\", oauth_signature=\"%@\", oauth_timestamp=\"%@\", oauth_nonce=\"%@\", oauth_version=\"%@\"",
                             callbackPair,
                             [LBUtils URLEncodedStringFromString:[oauthParams objectForKey:@"oauth_consumer_key"]],
                             tokenPair,
                             verifierPair,
                             [LBUtils URLEncodedStringFromString:[oauthParams objectForKey:@"oauth_signature"]],
                             [LBUtils URLEncodedStringFromString:[oauthParams objectForKey:@"oauth_timestamp"]],
                             [LBUtils URLEncodedStringFromString:[oauthParams objectForKey:@"oauth_nonce"]],
                             [LBUtils URLEncodedStringFromString:[oauthParams objectForKey:@"oauth_version"]]];
    [request setValue:oauthHeader forHTTPHeaderField:@"Authorization"];
}

+ (NSString*)signatureBaseStringWithRequest:(NSURLRequest*)request params:(NSDictionary*)params {
    NSArray *parts = [[[request URL] absoluteString] componentsSeparatedByString:@"?"];
    NSString *baseURL = [parts objectAtIndex:0];
    NSMutableArray *parameterPairs = [NSMutableArray array];
    NSEnumerator *e = [params keyEnumerator];
    NSString *key = nil;
    while (key = [e nextObject]) {
        [parameterPairs addObject:[NSString stringWithFormat:@"%@=%@",
                                   [LBUtils URLEncodedStringFromString:key],
                                   [LBUtils URLEncodedStringFromString:[params objectForKey:key]]]];
    }    
    NSArray *sortedPairs = [parameterPairs sortedArrayUsingSelector:@selector(compare:)];
    NSString *normalizedRequestParameters = [sortedPairs componentsJoinedByString:@"&"];
    NSString *ret = [NSString stringWithFormat:@"%@&%@&%@",
					 [request HTTPMethod],
					 [LBUtils URLEncodedStringFromString:baseURL],
                     [LBUtils URLEncodedStringFromString:normalizedRequestParameters]
					 ];
	return ret;
}

+ (NSString *)signClearText:(NSString *)text withSecret:(NSString *)secret 
{
    NSData *secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
    NSData *clearTextData = [text dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[20];
	CCHmac(kCCHmacAlgSHA1, [secretData bytes], [secretData length], [clearTextData bytes], [clearTextData length], result);    
    return [LBUtils base64forData:[NSData dataWithBytes:result length:20]];
}

@end
