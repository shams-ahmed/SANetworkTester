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

static NSString *const SAGoogleDns = @"8.8.8.8";
static NSString *const SAAppleAddess = @"www.apple.com";
static NSInteger const SAAttemptLimit = 3;


@interface SANetworkTester () <SimplePingDelegate>

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
#pragma mark - Class Method
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
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate distantFuture]];
            
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
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate distantFuture]];
            
        } while (networkTester.pinger != nil);
        
    });
    
}

+ (void)googleDNSWithCompletion:(SACompletionHandler)completionHandler errorHandler:(SAErrorHandler)errorHandler {
    [self networkTestUsingBlockWithCompletion:completionHandler
                                 errorHandler:errorHandler
                                      address:SAGoogleDns];
    
}

+ (void)appleDNSWithCompletion:(SACompletionHandler)completionHandler errorHandler:(SAErrorHandler)errorHandler {
    [self networkTestUsingBlockWithCompletion:completionHandler
                                 errorHandler:errorHandler
                                      address:SAAppleAddess];
    
}

+ (SACurrentNetworkStatus)networkStatus {
    switch ([Reachability reachabilityForInternetConnection].currentReachabilityStatus) {
        case 0: // NotReachable
            return SANotReachable;
            break;
        case 1: // ReachableViaWiFi
            return SAReachableViaWiFi;
            break;
        case 2: // ReachableViaWWAN
            return SAReachableViaWWAN;
            break;
        default:
            return SANotReachable;
            break;
    }
    
}


#pragma mark - Object Method
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
        
        if ([self.networkTesterDelegate respondsToSelector:@selector(didReceiveNetworkResponse:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.networkTesterDelegate performSelector:@selector(didReceiveNetworkResponse:)
                                                 withObject:responses];
                
            });

        } else if (self.completionHandler) {
            self.completionHandler(responses);
            
        }
        
    }
    
    /**
     *  dealloc all objects and kill timer
     */
    [self.sendTimer invalidate];
    self.sendTimer = nil;
    self.pinger = nil;
    
}


#pragma mark - SinglePingDelegate
- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address {
    [self sendPing];
    
    /**
     *  start timer to make addional request
     */
    self.sendTimer = [NSTimer scheduledTimerWithTimeInterval:0.75
                                                      target:self
                                                    selector:@selector(sendPing)
                                                    userInfo:nil
                                                     repeats:YES];
    
}

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet {
    if (_attempts == SAAttemptLimit) {
        _response > 0 ? [self stopPingWithError:nil] : [self stopPingWithError:[NSError errorWithDomain:@"ReceiveUnexpectedPacket"
                                                                                                   code:1000
                                                                                               userInfo:nil]];
        
        return;
    } else if (_attempts < SAAttemptLimit) {
        _attempts++;

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
    [self stopPingWithError:[NSError errorWithDomain:@"ReceiveUnexpectedPacket"
                                                code:1000
                                            userInfo:nil]];
    
}


@end
