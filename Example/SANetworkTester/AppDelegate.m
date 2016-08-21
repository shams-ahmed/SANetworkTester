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
    if ([[self class] isTesting]) {
        return YES;
    }    
#endif
    
    [self exampleGetActiveNetworkStatus];

    // Example 1
    [self exampleGoogleDNSUsingDelegate];

    // Example 2
//    [self exampleGoogleDNSUsingBlock];
    
    return YES;
}

#pragma mark
#pragma mark - SANetworkTester

///  Active network test - i.e WIFI or DATA status
- (void)exampleGetActiveNetworkStatus {
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
}

///  Ping test with Delegate approach
- (void)exampleGoogleDNSUsingDelegate {
    [SANetworkTester googleDnsWithDelegate:self];
}

///  Ping test with Block approach
- (void)exampleGoogleDNSUsingBlock {
    __weak typeof(self) weakSelf = self;
    
    [SANetworkTester googleDNSWithCompletion:^(NSNumber *response) {
        __strong typeof(self) strongSelf = weakSelf;
        
        [strongSelf showAlert:[NSString stringWithFormat:@"Received %@ packets", response]];
    } errorHandler:^(NSString *address, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        
        [strongSelf showAlert:[NSString stringWithFormat:@"Failed %@ wError: %@", address, error.localizedDescription]];
    }];
}

#pragma mark
#pragma mark - SANetworkTesterDelegate

- (void)didFailToReceiveResponseFromAddress:(NSString *)address withError:(NSError *)error {
    [self showAlert:[NSString stringWithFormat:@"Failed %@ wError: %@", address, error.localizedDescription]];
}

- (void)didReceiveNetworkResponse:(NSNumber *)response {
    [self showAlert:[NSString stringWithFormat:@"Received %@ packets", response]];
}

#pragma mark
#pragma mark - Private - Helper for demo purpose only

- (void)showAlert:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[UIAlertView alloc] initWithTitle:@"SANetworkTester feedback"
                                    message:message
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil]
         show];
    });
}

#pragma mark
#pragma mark - Private - Test Helper

+ (BOOL)isTesting {
    NSDictionary *environment = [NSProcessInfo processInfo].environment;
    
    return environment[@"TESTING"] != nil;
}

@end
