//
//  SANetworkTester.h
//  SANetworkTester
//
//  Created by Shams on 21/06/2013.
//
//

#import <Foundation/Foundation.h>
#import "SimplePing.h"
#import "Reachability.h"
#include <sys/socket.h>
#include <netdb.h>


/**
 *  Block for Completion which returns responses
 *
 *  @param response number of successful attempt
 */
typedef void (^SACompletionHandler)(NSNumber *response);

/**
 *  error message from ping test
 *
 *  @param address current address
 *  @param error   error for verbose information
 */
typedef void (^SAErrorHandler)(NSString *address, NSError *error);


/**
 *  Protocol for response or fail of network
 */
@protocol SANetworkTesterDelegate <NSObject>

- (void)didFailToReceiveResponseFromAddress:(NSString *)address withError:(NSError *)error;
- (void)didReceiveResponse:(NSNumber *)response;

@end


@interface SANetworkTester : NSObject <SimplePingDelegate>

/**
 *  Delegate for SinglePing
 */
@property (nonatomic, weak) id<SANetworkTesterDelegate> networkTesterDelegate;

/**
 *  number of attempts
 */
@property (nonatomic) NSInteger attempts;

/**
 *  number of successful responses
 */
@property (nonatomic) NSInteger response;


/**
 *  checks for dns responses with supplied address
 *
 *  @param hostName ip addess like 8.8.8.8
 *
 *  @return self
 */
+ (id)initWithHost:(NSString *)hostName andDelegate:(id)delegate;

/**
 *  check with google public dns server
 *
 *  @return self
 */
+ (id)googleDnsWithDelegate:(id)delegate;

/**
 *  check with apple.com
 *
 *  @return self
 */
+ (id)appleWithDelegate:(id)delegate;


/**
 *  use own address to ping a network
 *
 *  @param completionHandler success block to be executed
 *  @param errorHandler      failed block to be executed 
 *  @param address           specified address
 */
+ (void)networkTestUsingBlockWithCompletion:(SACompletionHandler)completionHandler errorHandler:(SAErrorHandler)errorHandler address:(NSString *)address;

/**
 *  checks google dns using block
 *
 *  @param completionHandler success block to be executed
 *  @param errorHandler      failed block to be executed
 */
+ (void)googleDNSWithCompletion:(SACompletionHandler)completionHandler errorHandler:(SAErrorHandler)errorHandler;


/**
 *  checks apple dns using block
 *
 *  @param completionHandler success block to be executed
 *  @param errorHandler      failed block to be executed
 */
+ (void)appleDNSWithCompletion:(SACompletionHandler)completionHandler errorHandler:(SAErrorHandler)errorHandler;


@end
