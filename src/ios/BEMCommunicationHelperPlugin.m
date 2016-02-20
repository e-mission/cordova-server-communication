#import "BEMCommunicationHelperPlugin.h"
#import "BEMCommunicationHelper.h"

@implementation BEMCommunicationHelperPlugin

- (void)getSettings:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = [command callbackId];
    
    @try {
        NSString* relativeURL = [[command arguments] objectAtIndex:0];
        NSDictionary* filledMessage = [[command arguments] objectAtIndex:1];

        [BEMCommunicationHelper pushGetJSON:filledMessage toURL:relativeURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error != NULL) {
                [self sendError:error];
            }
            NSError *parseError;
            NSDictionary *parsedResult = [NSJSONSerialization JSONObjectWithData:data
                                                                options:kNilOptions
                                                                  error: &parseError];
            if (parseError != NULL) {
                [self sendError:parseError];
            }
            CDVPluginResult* result = [CDVPluginResult
                                       resultWithStatus:CDVCommandStatus_OK
                                       messageAsDictionary:parsedResult];
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        }];
    }
    @catch (NSException *exception) {
        [self sendError:exception];
    }
}

- (void) sendError:(NSError*) error {
    NSString* msg = [NSString stringWithFormat: @"While getting settings, error %@", error];
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_ERROR
                               messageAsString:msg];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

@end
