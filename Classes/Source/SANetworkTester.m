//
//  SANetworkTester.m
//  SANetworkTester
//
//  Created by Shams on 21/06/2013.
//
//

#import "SANetworkTester.h"

static NSString *const SAGoogleDns = @"8.8.8.8";
static NSString *const SAAppleAddess = @"www.apple.com";

@interface SANetworkTester ()

/**
 *  does all actions fro mapple example
 */
@property (nonatomic, strong) SimplePing *pinger;

/**
 *  timeout if no response is given
 */
@property (nonatomic, strong) NSTimer *sendTimer;

/**
 *  Block property
 */
@property (copy) void (^completionHandler)();
@property (copy) void (^errorHandler)();

@end

@implementation SANetworkTester


#pragma mark -
#pragma mark - class method
- (void)dealloc {
    [self.pinger stop];
    [self.sendTimer invalidate];
}

+ (id)initWithHost:(NSString *)hostName andDelegate:(id)delegate {
    SANetworkTester *networkTester = [[SANetworkTester alloc] init];

    networkTester.pinger = [SimplePing simplePingWithHostName:hostName];
    networkTester.pinger.delegate = networkTester;
    networkTester.networkTesterDelegate = delegate;
    [networkTester.pinger start];
    
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    } while (networkTester.pinger);

    return networkTester;
}

+ (id)googleDnsWithDelegate:(id)delegate {
    SANetworkTester *networkTester = [[SANetworkTester alloc] init];

    networkTester.pinger = [SimplePing simplePingWithHostName:SAGoogleDns];
    networkTester.pinger.delegate = networkTester;
    networkTester.networkTesterDelegate = delegate;
    [networkTester.pinger start];
        
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    } while (networkTester.pinger != nil);

    return networkTester;
}

+ (id)appleWithDelegate:(id)delegate {
    SANetworkTester *networkTester = [[SANetworkTester alloc] init];
    
    networkTester.pinger = [SimplePing simplePingWithHostName:SAAppleAddess];
    networkTester.pinger.delegate = networkTester;
    networkTester.networkTesterDelegate = delegate;
    [networkTester.pinger start];
    
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    } while (networkTester.pinger != nil);
    
    return networkTester;
}

+ (void)googleDNSWithCompletion:(SACompletionHandler)completionHandler errorHandler:(SAErrorHandler)errorHandler {
    SANetworkTester *networkTester = [[SANetworkTester alloc] init];
    
    networkTester.pinger = [SimplePing simplePingWithHostName:SAGoogleDns];
    networkTester.pinger.delegate = networkTester;
    networkTester.completionHandler = completionHandler;
    networkTester.errorHandler = errorHandler;
    [networkTester.pinger start];
    
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    } while (networkTester.pinger != nil);
    
}


#pragma mark - object method
- (NSString *)shortErrorFromError:(NSError *)error {
    NSString *result;
    NSNumber *failureNum;
    int failure;
    const char *failureStr;
    result = nil;
    
    // Handle DNS errors as a special case.
    if ([error.domain isEqual:(NSString *)kCFErrorDomainCFNetwork] && (error.code == kCFHostErrorUnknown) ) {
        failureNum = [error.userInfo objectForKey:(id)kCFGetAddrInfoFailureKey];
        failure = failureNum.intValue;
        
        if (failure != 0) {
            failureStr = gai_strerror(failure);
            if (failureStr != NULL) {
                result = [NSString stringWithUTF8String:failureStr];
            }
        }
    }
    
    // Otherwise try various properties of the error object.
    if (!result) {
        result = error.localizedFailureReason;
    }
    
    if (!result) {
        result = error.localizedDescription;
    }
    
    if (!result) {
        result = error.description;
    }
    
    return result;
}

- (void)sendPing {
    [self.pinger sendPingWithData:nil];
    
}

- (void)stopPingWithError:(NSError *)error {
    if (error) {
        if ([self.networkTesterDelegate respondsToSelector:@selector(didFailToReceiveResponseFromAddress:withError:)]) {
            [self.networkTesterDelegate performSelector:@selector(didFailToReceiveResponseFromAddress:withError:)
                                          withObject:self.pinger.hostName
                                          withObject:error];
        } else if (self.completionHandler) {
            self.errorHandler(self.pinger.hostName, error);
        }

    } else {
        NSNumber *responses = [NSNumber numberWithInteger:_attempts];
        
        if ([self.networkTesterDelegate respondsToSelector:@selector(didReceiveResponse:)]) {

            [self.networkTesterDelegate performSelector:@selector(didReceiveResponse:) withObject:responses];
        } else if (self.completionHandler) {
            self.completionHandler(responses);
        }
    }

    [self.sendTimer invalidate];
    self.sendTimer = nil;
    self.pinger = nil;
}


#pragma mark - SinglePingDelegate
- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address {
    [self sendPing]; // ???
    self.sendTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                    selector:@selector(sendPing)
                                                    userInfo:nil
                                                     repeats:YES];
    
}

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet {
    if (_attempts < 3) {
//        testintg only
//        NSLog(@"#%u ping sent", (unsigned int) OSSwapBigToHostInt16(((const ICMPHeader *) packet.bytes)->sequenceNumber));
        _attempts++;
    } else {
        [self stopPingWithError:nil];
    }

}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet {
//    testng only
//    NSLog(@"#%u ping received", (unsigned int) OSSwapBigToHostInt16([SimplePing icmpInPacket:packet]->sequenceNumber));
    
    if (_response == 3) {
        [self stopPingWithError:nil];
        return;
    }
    
    _response++;
}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error {
    [self stopPingWithError:error];
    
}

- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet error:(NSError *)error {
    [self stopPingWithError:error];
    
}

- (void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet {
    [self stopPingWithError:[NSError errorWithDomain:@"ReceiveUnexpectedPacket" code:1000 userInfo:nil]];
    
}


@end
