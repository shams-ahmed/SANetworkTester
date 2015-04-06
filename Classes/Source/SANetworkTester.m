//
//  SANetworkTester.m
//  SANetworkTester
//
//  Created by Shams on 21/06/2013.
//
//

#import "SANetworkTester.h"
#import "SimplePing.h"
#import "Reachability.h"
#include <sys/socket.h>
#include <netdb.h>

#pragma mark -
#pragma mark - Know IP Address for ping's

static NSString *const SAPingGoogleA = @"8.8.8.8";
static NSString *const SAPingGoogleB = @"8.8.4.4";
static NSString *const SAPingApple = @"www.apple.com";

static NSInteger const SAAttemptLimit = 3;


@interface SANetworkTester () <SimplePingDelegate>

#pragma mark - 
#pragma mark - Private

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
@property (nonatomic, copy) void (^completionHandler)();
@property (nonatomic, copy) void (^errorHandler)();


@end

@implementation SANetworkTester


#pragma mark -
#pragma mark - Lifecycle

- (void)dealloc {
    [_pinger stop];
    [_sendTimer invalidate];
    _pinger = nil;
    _sendTimer = nil;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        
    }
    
    return self;
}


#pragma mark -
#pragma mark - Class Method

+ (instancetype)initWithHost:(NSString *)hostName andDelegate:(id)delegate {
    __block SANetworkTester *networkTester = [[SANetworkTester alloc] init];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^
    {
        networkTester.pinger = [SimplePing simplePingWithHostName:hostName];
        networkTester.pinger.delegate = networkTester;
        networkTester.networkTesterDelegate = delegate;
        
        [networkTester.pinger start];

        do {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate distantFuture]];
            
        } while (networkTester.pinger);
        
    });
    
    return networkTester;
}

+ (instancetype)googleDnsWithDelegate:(id)delegate {
    return [self initWithHost:SAPingGoogleA andDelegate:delegate];
    
}

+ (instancetype)appleWithDelegate:(id)delegate {
    return [self initWithHost:SAPingApple andDelegate:delegate];
    
}

+ (void)networkTestUsingBlockWithCompletion:(SACompletionHandler)completionHandler errorHandler:(SAErrorHandler)errorHandler address:(NSString *)address {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^
    {
        SANetworkTester *networkTester = [[SANetworkTester alloc] init];
        
        networkTester.pinger = [SimplePing simplePingWithHostName:address];
        networkTester.pinger.delegate = networkTester;
        networkTester.completionHandler = completionHandler;
        networkTester.errorHandler = errorHandler;
        
        [networkTester.pinger start];
        
        do {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate distantFuture]];
            
        } while (networkTester.pinger != nil);
        
    });
    
}

+ (void)googleDNSWithCompletion:(SACompletionHandler)completionHandler errorHandler:(SAErrorHandler)errorHandler {
    [self networkTestUsingBlockWithCompletion:completionHandler
                                 errorHandler:errorHandler
                                      address:SAPingGoogleA];
    
}

+ (void)appleDNSWithCompletion:(SACompletionHandler)completionHandler errorHandler:(SAErrorHandler)errorHandler {
    [self networkTestUsingBlockWithCompletion:completionHandler
                                 errorHandler:errorHandler
                                      address:SAPingGoogleA];
    
}

+ (SACurrentNetworkStatus)networkStatus {
    switch ([Reachability reachabilityForInternetConnection].currentReachabilityStatus) {
        case 0: // NotReachable
            return SANotReachable;
        case 1: // ReachableViaWiFi
            return SAReachableViaWiFi;
        case 2: // ReachableViaWWAN
            return SAReachableViaWWAN;
        default:
            return SANotReachable;
    }
    
}


#pragma mark -
#pragma mark - Timer

- (void)timerFireMethod:(NSTimer *)timer {
    [self.pinger sendPingWithData:nil];
}


#pragma mark -
#pragma mark - Error

- (NSString *)shortErrorFromError:(NSError *)error {
    NSString *result;
    NSNumber *failureKey;
    const char *failedReason;
    
    // Handle DNS errors as a special case.
    if ([error.domain isEqualToString:(NSString *)kCFErrorDomainCFNetwork] &&
        (error.code == kCFHostErrorUnknown)) {
        failureKey = [error.userInfo objectForKey:(id)kCFGetAddrInfoFailureKey];
        
        if (failureKey.intValue != 0) {
            failedReason = gai_strerror(failureKey.intValue);
            
            if (failedReason != NULL) {
                result = [NSString stringWithUTF8String:failedReason];
            }
        }
    }
    
    // Otherwise try various properties of the error object.
    if (!result) {
        result = error.localizedFailureReason;
    }
    
    if (!result) {
        result = error.description;
    }
    
    return result;
}

- (void)stopPingWithError:(NSError *)error {
    __block NSError *aError = error;
    __block NSString *hostAddress = self.pinger.hostName;
    __weak typeof(self) weakSelf = self;
    
    
    /**
     *  dealloc all objects and kill timer
     */
    [self.pinger stop];
    [self.sendTimer invalidate];
    self.sendTimer = nil;
    self.pinger = nil;
    
    /**
     *  send result
     */
    if (aError) {
        if ([self.networkTesterDelegate respondsToSelector:@selector(didFailToReceiveResponseFromAddress:withError:)]) {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                __strong typeof(self) strongSelf = weakSelf;
                
                [strongSelf.networkTesterDelegate performSelector:@selector(didFailToReceiveResponseFromAddress:withError:)
                                                       withObject:hostAddress
                                                       withObject:error];
                
            });
            
        } else if (self.completionHandler) {
            self.errorHandler(hostAddress, error);
            
        }

    } else {
        __block NSNumber *responses = [NSNumber numberWithInteger:_attempts];
        
        if ([self.networkTesterDelegate respondsToSelector:@selector(didReceiveNetworkResponse:)]) {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                __strong typeof(self) strongSelf = weakSelf;
                
                [strongSelf.networkTesterDelegate performSelector:@selector(didReceiveNetworkResponse:)
                                                       withObject:responses];
                
            });

        } else if (self.completionHandler) {
            self.completionHandler(responses);
            
        }
        
    }
    
}


#pragma mark -
#pragma mark - SinglePingDelegate

- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address {
    /**
     *  start timer to make addional request
     */
    self.sendTimer = [NSTimer scheduledTimerWithTimeInterval:0.75
                                                      target:self
                                                    selector:@selector(timerFireMethod:)
                                                    userInfo:nil
                                                     repeats:YES];
    
    [self.sendTimer fire];
    
}

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet {
    if (_attempts == SAAttemptLimit) {
        _response > 0 ? [self stopPingWithError:nil] : [self stopPingWithError:[NSError errorWithDomain:@"SAN: Receive unexpected packet"
                                                                                                   code:1000
                                                                                               userInfo:nil]];
        
        return;
    } else if (_attempts < SAAttemptLimit) {
        _attempts++;

    } else {
        return;
    }

}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet {
    /**
     *  if response and limit match then pass test
     */
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
    [self stopPingWithError:[NSError errorWithDomain:@"SAN: Received unexpected packet"
                                                code:1000
                                            userInfo:nil]];
}


@end
