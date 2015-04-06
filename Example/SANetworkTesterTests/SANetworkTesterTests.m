//
//  SANetworkTesterTests.m
//  SANetworkTesterTests
//
//  Created by Shams on 01/04/2014.
//  Copyright (c) 2014 SA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SANetworkTester.h"

@interface SANetworkTesterTests : XCTestCase

@end

@implementation SANetworkTesterTests

#pragma mark -
#pragma mark - Setup


- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


#pragma mark -
#pragma mark - Test cases for network ping

- (void)testForGooglePing {
    XCTestExpectation *expect = [self expectationWithDescription:@"async test 1"];
    
    [SANetworkTester googleDNSWithCompletion:^(NSNumber *response)
    {
        [expect fulfill];
    }
                                errorHandler:^(NSString *address, NSError *error)
    {
        XCTFail(@"SAN: could not ping google");
    }];
    
    [self waitForExpectationsWithTimeout:15 handler:nil];
}

- (void)testForApplePing {
    XCTestExpectation *expect = [self expectationWithDescription:@"async test 2"];
    
    [SANetworkTester appleDNSWithCompletion:^(NSNumber *response)
    {
        [expect fulfill];
    }
                               errorHandler:^(NSString *address, NSError *error)
    {
        XCTFail(@"SAN: could not ping apple");
    }];
    
    [self waitForExpectationsWithTimeout:15 handler:nil];
}

- (void)testNumberOfResponses {
    XCTestExpectation *expect = [self expectationWithDescription:@"async test 3"];
    
    [SANetworkTester googleDNSWithCompletion:^(NSNumber *response)
    {
        [expect fulfill];
        
        XCTAssertEqual(response.intValue, 3, @"SAN: some pings were not received back from google dns");
    }
                                errorHandler:^(NSString *address, NSError *error)
    {
        XCTFail(@"SAN: did not match appempts");
        
    }];
    
    [self waitForExpectationsWithTimeout:15 handler:nil];
}


#pragma mark -
#pragma mark - Test cases for network status

- (void)testForActiveWifiNetwork {
    XCTAssertEqual([SANetworkTester networkStatus], SAReachableViaWiFi, @"SAN: network status is not wifi");
    
}

- (void)testForActiveNetwork {
    XCTAssertNotEqual([SANetworkTester networkStatus], SANotReachable, @"SAN: network has active connection");
    
}


@end
