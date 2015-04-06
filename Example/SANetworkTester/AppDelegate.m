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
#ifdef DEBUG
    BOOL isTestMode = [[self class] isTesting];
    
    if (isTestMode) {
        return YES;
    }    
#endif
    
    /* 1. Active Network test - i.e wifi or data */
    /*
    switch ([SANetworkTester networkStatus]) {
        case SANotReachable:
            [self showAlert:@"Network is not reachable via WIFI, DATA or WWAN"];
            break;
        case SAReachableViaWiFi:
            [self showAlert:@"Network is reachable via WIFI"];
            break;
        case SAReachableViaWWAN:
            [self showAlert:@"Network is reachable via WWAN"];
            break;
        default:
            break;
    }
    */
    
    
    /* 2. Ping test with Delegate approach*/
    // [SANetworkTester googleDnsWithDelegate:self];
    
    
    /* 3. Ping test with Block approach*/
    __weak typeof(self) weakSelf = self;
    
    [SANetworkTester googleDNSWithCompletion:^(NSNumber *response) {
        __strong typeof(self) strongSelf = weakSelf;
        
        [strongSelf showAlert:[NSString stringWithFormat:@"Received %@ packets", response]];
        
    } errorHandler:^(NSString *address, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        
        [strongSelf showAlert:[NSString stringWithFormat:@"Failed %@ wError: %@", address, error.localizedDescription]];

    }];
    
    return YES;
}


#pragma mark
#pragma mark - SANetworkTesterDelegate

- (void)didFailToReceiveResponseFromAddress:(NSString *)address withError:(NSError *)error {
    [self showAlert:[NSString stringWithFormat:@"failed %@ wError: %@", address, error.localizedDescription]];
    
}

- (void)didReceiveNetworkResponse:(NSNumber *)response {
    [self showAlert:[NSString stringWithFormat:@"received %@ packets", response]];
    
}


#pragma mark
#pragma mark - Helper method for demo purpose only

- (void)showAlert:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:@"SANetworkTester"
                                message:message
                               delegate:nil
                      cancelButtonTitle:@"Ok"
                      otherButtonTitles:nil]
     show];
}

+ (BOOL) isTesting
{
    NSDictionary *environment = [[NSProcessInfo processInfo] environment];
    return [environment objectForKey:@"TESTING"] != nil;
}

@end
