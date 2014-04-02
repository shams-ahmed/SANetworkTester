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

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


#pragma mark - Test cases for network ping
- (void)testForGooglePing {
    [SANetworkTester googleDNSWithCompletion:nil errorHandler:^(NSString *address, NSError *error) {
        XCTFail(@"SAN: could not ping google");
        
    }];
    
}

- (void)testForApplePing {
    [SANetworkTester appleDNSWithCompletion:nil errorHandler:^(NSString *address, NSError *error) {
        XCTFail(@"SAN: could not ping apple");
        
    }];
    
}

- (void)testForPingForNilObject {
    [SANetworkTester googleDNSWithCompletion:^(NSNumber *response) {
        XCTAssertNotNil(response, @"SAN: response is nil");
    } errorHandler:^(NSString *address, NSError *error) {
        XCTAssertNotNil(address, @"SAN: address ping has returned nil");
        XCTAssertNotNil(error, @"SAN: could not geta error object");
    }];
    
}

- (void)testNumberOfResponses {
    [SANetworkTester googleDNSWithCompletion:^(NSNumber *response) {
        XCTAssertEqual(response.intValue, [[SANetworkTester alloc] init].attempts, @"SAN: some pings were not received back from google dns");
    }
                                errorHandler:nil];

}


#pragma mark - Test cases for network status
- (void)testForActiveWifiNetwork {
    XCTAssertEqual([SANetworkTester networkStatus], SAReachableViaWiFi, @"SAN: network status is not wifi");
    
}

- (void)testForActiveNetwork {
    XCTAssertNotEqual([SANetworkTester networkStatus], SANotReachable, @"SAN: network has active connection");
    
}


@end
