#import "BEMCommunicationHelperPlugin.h"
#import "BEMCommunicationHelper.h"
#import <GTMSessionFetcher/GTMSessionFetcher.h>

@implementation BEMCommunicationHelperPlugin

- (void)pushGetJSON:(CDVInvokedUrlCommand *)command
{
    NSString* callbackId = [command callbackId];
    
    @try {
        NSString* relativeURL = [[command arguments] objectAtIndex:0];
        NSDictionary* filledMessage = [[command arguments] objectAtIndex:1];

        [CommunicationHelper pushGetJSON:filledMessage toURL:relativeURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error != NULL) {
                NSLog(@"Got error for command with URL %@", [[command arguments] objectAtIndex:0]);
                NSMutableDictionary *errDict = [NSMutableDictionary dictionary];
                errDict[@"message"] = [NSString stringWithFormat:@"During server call, error %@",
                                        [error localizedDescription]];
                if ([error.domain isEqualToString:kGTMSessionFetcherStatusDomain]) {
                    errDict[@"status"] = @(error.code);
                    // GTMSessionFetcher puts the body of non-2xx responses in userInfo, not in `data`
                    NSData *errData = error.userInfo[kGTMSessionFetcherStatusDataKey];
                    NSString *errBody = errData != nil
                        ? [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding]
                        : nil;
                    if (errBody != nil) {
                        errDict[@"body"] = errBody;
                    }
                }
                [self sendErrorDict:errDict callBackID:callbackId];
            } else {
            NSError *parseError;
            NSDictionary *parsedResult = [NSJSONSerialization JSONObjectWithData:data
                                                                options:kNilOptions
                                                                  error: &parseError];
            if (parseError != NULL) {
                NSString *msg = [NSString stringWithFormat: @"Response was not JSON: %@ Error: %@",
                                [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding],
                                parseError];
                [self sendError:msg callBackID:callbackId];
                return;
            }
            CDVPluginResult* result = [CDVPluginResult
                                       resultWithStatus:CDVCommandStatus_OK
                                       messageAsDictionary:parsedResult];
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
            }
        }];
    }
    @catch (NSException *exception) {
        [self sendError:exception callBackID:callbackId];
    }
}

- (void) sendError:(id) error callBackID:(NSString*)callbackID {
    NSString* msg = [NSString stringWithFormat: @"During server call, error %@", error];
    [self sendErrorDict:@{@"message": msg} callBackID:callbackID];
}

- (void) sendErrorDict:(NSDictionary*) errDict callBackID:(NSString*)callbackID {
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_ERROR
                               messageAsDictionary:errDict];
    [self.commandDelegate sendPluginResult:result callbackId:callbackID];
}

@end
