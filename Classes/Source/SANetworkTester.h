//
//  SAPingHelper.h
//  SAPingHelper
//
//  Created by Shams on 21/06/2013.
//
//

#import <Foundation/Foundation.h>
#include "SimplePing.h"
#include <sys/socket.h>
#include <netdb.h>

typedef void (^SACompletionHandler)(NSNumber *response);
typedef void (^SAErrorHandler)(NSString *address, NSError *error);

@protocol SANetworkTesterDelegate <NSObject>

- (void)didFailToReceiveResponseFromAddress:(NSString *)address withError:(NSError *)error;
- (void)didReceiveResponse:(NSNumber *)response;

@end


@interface SANetworkTester : NSObject <SimplePingDelegate>

/**
 *  Delegate from SinglePing
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
 *  checks google dns using block
 *
 *  @param completionHandler success block to be executed
 *  @param errorHandler      failed block to be executed
 */
+ (void)googleDNSWithCompletion:(SACompletionHandler)completionHandler errorHandler:(SAErrorHandler)errorHandler;


@end
