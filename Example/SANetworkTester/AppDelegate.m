//
//  AppDelegate.m
//  SANetworkTester
//
//  Created by Shams on 01/04/2014.
//  Copyright (c) 2014 SA. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

#pragma mark
#pragma mark - AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window makeKeyAndVisible];
    
    
    /** NETWORK TEST
     *  Two routes to check ping either using Blocks or Delegate
     */

    /**
     *  Ping with delegate
     */
//    [SAPingHelper googleDnsWithDelegate:self];
    
    /**
     *  Ping with Block
     */
    [SANetworkTester googleDNSWithCompletion:^(NSNumber *response) {
        // handle success
        [self showAlert:[NSString stringWithFormat:@"Received %@ packets", response]];
        
    } errorHandler:^(NSString *address, NSError *error) {
        // handle error
        [self showAlert:[NSString stringWithFormat:@"Failed %@ wError: %@", address, error.localizedDescription]];
        
    }];
    
    return YES;
}


#pragma mark - SANetworkTesterDelegate
- (void)didFailToReceiveResponseFromAddress:(NSString *)address withError:(NSError *)error {
    [self showAlert:[NSString stringWithFormat:@"failed %@ wError: %@", address, error.localizedDescription]];
    
}

- (void)didReceiveResponse:(NSNumber *)response {
    [self showAlert:[NSString stringWithFormat:@"received %@ packets", response]];
    
}


#pragma mark - Helper method for demo only
- (void)showAlert:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:@"SANetworkTester"
                                message:message
                               delegate:nil
                      cancelButtonTitle:@"Ok"
                      otherButtonTitles:nil]
     show];
}


@end
