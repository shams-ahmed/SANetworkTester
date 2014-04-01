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
static NSInteger const SAAttemptLimit = 3;


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


- (void)sendPing;
- (NSString *)shortErrorFromError:(NSError *)error;
- (void)stopPingWithError:(NSError *)error;
    
    
@end

@implementation SANetworkTester


#pragma mark -
#pragma mark - class method
- (void)dealloc {
    [self.pinger stop];
    [self.sendTimer invalidate];
}

- (id)init {
    self = [super init];
    if (self) {
    }
    
    return self;
}

+ (id)initWithHost:(NSString *)hostName andDelegate:(id)delegate {
    __block SANetworkTester *networkTester = [[SANetworkTester alloc] init];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        networkTester.pinger = [SimplePing simplePingWithHostName:hostName];
        networkTester.pinger.delegate = networkTester;
        networkTester.networkTesterDelegate = delegate;
        [networkTester.pinger start];

        do {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        } while (networkTester.pinger);
        
    });
    
    return networkTester;
}

+ (id)googleDnsWithDelegate:(id)delegate {
    return [self initWithHost:SAGoogleDns andDelegate:delegate];
}

+ (id)appleWithDelegate:(id)delegate {
    return [self initWithHost:SAAppleAddess andDelegate:delegate];
}

+ (void)networkTestUsingBlockWithCompletion:(SACompletionHandler)completionHandler errorHandler:(SAErrorHandler)errorHandler address:(NSString *)address {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        SANetworkTester *networkTester = [[SANetworkTester alloc] init];
        
        networkTester.pinger = [SimplePing simplePingWithHostName:address];
        networkTester.pinger.delegate = networkTester;
        networkTester.completionHandler = completionHandler;
        networkTester.errorHandler = errorHandler;
        [networkTester.pinger start];
        
        do {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        } while (networkTester.pinger != nil);
        
    });
    
}

+ (void)googleDNSWithCompletion:(SACompletionHandler)completionHandler errorHandler:(SAErrorHandler)errorHandler {
    [self networkTestUsingBlockWithCompletion:completionHandler errorHandler:errorHandler address:SAGoogleDns];
    
}

+ (void)appleDNSWithCompletion:(SACompletionHandler)completionHandler errorHandler:(SAErrorHandler)errorHandler {
    [self networkTestUsingBlockWithCompletion:completionHandler errorHandler:errorHandler address:SAAppleAddess];
    
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
    __block NSError *aError = error;
    __block NSString *hostAddress = self.pinger.hostName;
    
    if (aError) {
        if ([self.networkTesterDelegate respondsToSelector:@selector(didFailToReceiveResponseFromAddress:withError:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.networkTesterDelegate performSelector:@selector(didFailToReceiveResponseFromAddress:withError:)
                                              withObject:hostAddress
                                              withObject:error];
                
            });
            
        } else if (self.completionHandler) {
            self.errorHandler(hostAddress, error);
            
        }

    } else {
        __block NSNumber *responses = [NSNumber numberWithInteger:_attempts];
        
        if ([self.networkTesterDelegate respondsToSelector:@selector(didReceiveResponse:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.networkTesterDelegate performSelector:@selector(didReceiveResponse:) withObject:responses];
            });

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
    [self sendPing];
    self.sendTimer = [NSTimer scheduledTimerWithTimeInterval:0.75
                                                      target:self
                                                    selector:@selector(sendPing)
                                                    userInfo:nil
                                                     repeats:YES];
    
}

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet {
    if (_attempts < SAAttemptLimit) {
        _attempts++;
    }

}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet {
//    NSLog(@"#%u ping received", (unsigned int) OSSwapBigToHostInt16([SimplePing icmpInPacket:packet]->sequenceNumber));
    
    if (_response == SAAttemptLimit) {
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
