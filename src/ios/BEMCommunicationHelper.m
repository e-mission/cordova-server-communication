//
//  CommunicationHelper.m
//  CFC_Tracker
//
//  As we incorporate authentication, authorization, and background invocations, communication with the server is likely to get more complex.
//  Let us put it all into another file to hide the complexity
//
//  Created by Kalyanaraman Shankari on 3/24/14.
//  Copyright (c) 2014 Kalyanaraman Shankari. All rights reserved.
//

#import "BEMCommunicationHelper.h"
#import "AuthCompletionHandler.h"
#import "BEMConnectionSettings.h"

#import <GoogleOpenSource/GoogleOpenSource.h>

// This is the base URL
// We need to append the username to it, and then we need to authenticate the user as well
// TODO: but first, let's get the basic version working with the test user "Fate"
/*
*/

static NSString* kUncommittedSectionsPath = @"/tripManager/getUnclassifiedSections";
static NSString* kUsercachePutPath = @"/usercache/put";
static NSString* kSaveSectionsPath = @"/tripManager/setSectionClassification";
static NSString* kMovesCallbackPath = @"/movesCallback";
static NSString* kSetStatsPath = @"/stats/set";
static NSString* kCustomSettingsPath = @"/profile/settings";
static NSString* kRegisterPath = @"/profile/create";

@interface CommunicationHelper() <AuthCompletionDelegate> {
}
@end

@implementation CommunicationHelper

+(void)getCustomSettings:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSLog(@"CommunicationHelper.getCustomSettings called!");
    NSMutableDictionary *blankDict = [[NSMutableDictionary alloc] init];
    NSURL *kBaseURL = [[ConnectionSettings sharedInstance] getConnectUrl];
    NSURL *kCustomSettingsURL = [NSURL URLWithString:kCustomSettingsPath relativeToURL:kBaseURL];
    
    CommunicationHelper *executor = [[CommunicationHelper alloc] initPost:kCustomSettingsURL data:blankDict completionHandler:completionHandler];
    [executor execute];
}

+(void)createUserProfile:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSLog(@"CommunicationHelper.getCustomSettings called!");
    NSMutableDictionary *blankDict = [[NSMutableDictionary alloc] init];
    NSURL *kBaseURL = [[ConnectionSettings sharedInstance] getConnectUrl];
    NSURL *kRegisterPathURL = [NSURL URLWithString:kRegisterPath relativeToURL:kBaseURL];
    
    CommunicationHelper *executor = [[CommunicationHelper alloc] initPost:kRegisterPathURL data:blankDict completionHandler:completionHandler];
    [executor execute];
}

+(void)getUnclassifiedSections:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSLog(@"CommunicationHelper.getUnclassifiedSections called!");
    NSMutableDictionary *blankDict = [[NSMutableDictionary alloc] init];
    NSURL* kBaseURL = [[ConnectionSettings sharedInstance] getConnectUrl];
    NSURL* kUncommittedSectionsURL = [NSURL URLWithString:kUncommittedSectionsPath
                                            relativeToURL:kBaseURL];
    CommunicationHelper *executor = [[CommunicationHelper alloc] initPost:kUncommittedSectionsURL data:blankDict completionHandler:completionHandler];
    [executor execute];
}

+(void)setClassifiedSections:(NSArray*)sectionDicts completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSMutableDictionary *toPush = [[NSMutableDictionary alloc] init];
    [toPush setObject:sectionDicts forKey:@"updates"];
    NSURL* kBaseURL = [[ConnectionSettings sharedInstance] getConnectUrl];
    NSURL* kSaveSectionsURL = [NSURL URLWithString:kSaveSectionsPath
                                            relativeToURL:kBaseURL];
    CommunicationHelper *executor = [[CommunicationHelper alloc] initPost:kSaveSectionsURL data:toPush completionHandler:completionHandler];
    [executor execute];
}

+(void)movesCallback:(NSMutableDictionary*)movesParams completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSURL* kBaseURL = [[ConnectionSettings sharedInstance] getConnectUrl];
    NSURL* kMovesCallbackURL = [NSURL URLWithString:kMovesCallbackPath
                                     relativeToURL:kBaseURL];

    CommunicationHelper *executor = [[CommunicationHelper alloc] initPost:kMovesCallbackURL data:movesParams completionHandler:completionHandler];
    [executor execute];
}

+(void)setClientStats:(NSMutableDictionary*)statsToSend completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSMutableDictionary *toPush = [[NSMutableDictionary alloc] init];
    [toPush setObject:statsToSend forKey:@"stats"];
    
    NSURL* kBaseURL = [[ConnectionSettings sharedInstance] getConnectUrl];
    NSURL* kSetStatsURL = [NSURL URLWithString:kSetStatsPath
                                      relativeToURL:kBaseURL];
    
    CommunicationHelper *executor = [[CommunicationHelper alloc] initPost:kSetStatsURL data:toPush completionHandler:completionHandler];
    [executor execute];
}

+(void)phone_to_server:(NSArray *)entriesToPush completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSMutableDictionary *toPush = [[NSMutableDictionary alloc] init];
    [toPush setObject:entriesToPush forKey:@"phone_to_server"];
    
    NSURL* kBaseURL = [[ConnectionSettings sharedInstance] getConnectUrl];
    NSURL* kUsercachePutURL = [NSURL URLWithString:kUsercachePutPath
                                 relativeToURL:kBaseURL];
    
    CommunicationHelper *executor = [[CommunicationHelper alloc] initPost:kUsercachePutURL data:toPush completionHandler:completionHandler];
    [executor execute];
}

+(void)getData:(NSURL*)url completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSURLSession *sharedSession = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [sharedSession dataTaskWithURL:url completionHandler:completionHandler];
    [task resume];
}

-(id)initPost:(NSURL*)url data:(NSMutableDictionary*)jsonDict completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    self.mUrl = url;
    self.mJsonDict = jsonDict;
    self.mCompletionHandler = completionHandler;
    
    return [super init];
}

-(void)execute {
    NSLog(@"CommunicationHelper.execute called!");
    // First, we parse the dictionary because we need the data to call the completion function anyway
    // Note that this data does not contain the user token, and should not be sent to the server
    NSError *parseError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.mJsonDict
                                                       options:kNilOptions
                                                         error:&parseError];
    if (parseError != NULL) {
        NSLog(@"parseError = %@, calling completion handler", parseError);
        self.mCompletionHandler(jsonData, NULL, parseError);
        return;
    }

    [[AuthCompletionHandler sharedInstance] getValidAuth:^(GTMOAuth2Authentication *auth,NSError* error) {
        if (error != NULL) {
            self.mCompletionHandler(jsonData, NULL, error);
        } else {
            // TODO: have postToHost take the auth token as input instead of re-reading it
            [self postToHost];
        }
    }];
}

- (void)postToHost {
    NSLog(@"postToHost called with url = %@", self.mUrl);
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:self.mUrl
                                    cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:500];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json"
        forHTTPHeaderField:@"Content-Type"];
    
    NSString *userToken = [AuthCompletionHandler sharedInstance].getIdToken;
    // At this point, we assume that all the authentication is done correctly
    // Should I try to verify making a remote call or add that to a debug screen?
    [self.mJsonDict setObject:userToken forKey:@"user"];
    
    NSError *parseError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.mJsonDict
                                                       options:kNilOptions
                                                         error:&parseError];
    if (parseError) {
        self.mCompletionHandler(jsonData, nil, parseError);
    } else {
        /* Theoretically, this is a memory leak. From the documentation:
         * The session object keeps a strong reference to the delegate until your app explicitly invalidates the session. If you do not invalidate the session by calling the invalidateAndCancel or resetWithCompletionHandler: method, your app leaks memory.
         
         We don't actually invalidate the session anywhere.
         
         However, we don't actually pass in a delegate, preferring to rely on the completionHandler instead. So we don't actually store a reference to anything.
         
         I have run this through xcode and refreshed multiple times, and the memory consumption does not appear to increase.
         */
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                              delegate:nil
                                                         delegateQueue:[NSOperationQueue mainQueue]];
        NSLog(@"session queue = %@, mainQueue = %@", session.delegateQueue, [NSOperationQueue mainQueue]);
        NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromData:jsonData completionHandler:self.mCompletionHandler];
        [task resume];
    }
}

/*

- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error {
    NSLog(@"CommunicationHelper.finishedWithAuth called with auth = %@ and error = %@", auth, error);
    if (error != NULL) {
        NSLog(@"Got error %@ while authenticating", error);
        self.mCompletionHandler(NULL, NULL, error);
        // modify some kind of error count and notify that user needs to sign in again
    } else {
        [[AuthCompletionHandler sharedInstance] unregisterFinishDelegate:self];
        [self postToHost];
    }
}

- (void)finishRefreshSelector:(GTMOAuth2Authentication *)auth
                      request:(NSMutableURLRequest *)request
            finishedWithError:(NSError *)error {
    NSLog(@"CommunicationHelper.finishRefreshSelector called with auth = %@, request = %@, error = %@",
          auth, request, error);
    if (error != NULL) {
        self.mCompletionHandler(NULL, NULL, error);
    } else {
        BOOL stillExpired = ([auth.expirationDate compare:[NSDate date]] == NSOrderedAscending);
        if (stillExpired) {
            NSLog(@"No more methods to try, I GIVE UP!");
        } else {
            // Check to see whether the sharedInstance auth token has been updated
            NSLog(@"Auth token in the shared instance is %@", [AuthCompletionHandler sharedInstance].currAuth);
            [self postToHost];
        }
    }
    
}

*/

@end
