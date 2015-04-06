# SANetworkTester

[![Version](http://cocoapod-badges.herokuapp.com/v/SANetworkTester/badge.png)](http://cocoadocs.org/docsets/SANetworkTester)
[![Platform](http://cocoapod-badges.herokuapp.com/p/SANetworkTester/badge.png)](http://cocoadocs.org/docsets/SANetworkTester)

SANetworkHelper makes your life easier to test network connection on a iOS device without having to spend time writing lots of code. Its has a few simple class methods that run in a background thread and return the response of the network by either using Block or Delegate.

Example method with Block:

    [SANetworkTester googleDNSWithCompletion:^(NSNumber *response) {
        // handle success
        [self showAlert:[NSString stringWithFormat:@"Received %@ packets", response]];
        
    } errorHandler:^(NSString *address, NSError *error) {
        // handle error
        [self showAlert:[NSString stringWithFormat:@"Failed %@ wError: %@", address, error.localizedDescription]];

    }];

Example method with Delegate:

1. #import < SANetworkTester.h >
2. add Delegate to class: <SANetworkTesterDelegate>
3. add two optional protocol methods: - (void)didFailToReceiveResponseFromAddress:(NSString *)address withError:(NSError *)error; and - (void)didReceiveResponse:(NSNumber *)response;
5. add method to run test: [SANetworkTester googleDnsWithDelegate:self];

## Screenshot
<img src="https://raw.githubusercontent.com/shams-ahmed/SANetworkTester/master/Resources/Screenshot.png">

## Usage

To run the example project; clone the repo, and build the exmaple project.

## Requirements

## Installation

SANetworkTester is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:

    pod "SANetworkTester"

Or directly drag and drop the Source folder and add these framework: 'CFNetwork', 'MobileCoreServices', 'SystemConfiguration'

## Author

shams-ahmed, shamsahmed@me.com

## License

SANetworkTester is available under the MIT license. See the LICENSE file for more info.



[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/shams-ahmed/sanetworktester/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

