#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "OCAnimalServiceClient.h"

@import PactConsumerSwift;

@interface PactObjectiveCTests : XCTestCase
@property (strong, nonatomic) MockService *animalMockService;
@property (strong, nonatomic) OCAnimalServiceClient *animalServiceClient;
@end

@implementation PactObjectiveCTests

- (void)setUp {
  [super setUp];

  PactVerificationService *verificationService = [[PactVerificationService alloc] initWithUrl:@"https://localhost"
                                                                                         port:1234
                                                                     allowInsecureCertificate: TRUE];

  self.animalMockService = [[MockService alloc] initWithProvider:@"Animal Provider"
                                                  consumer:@"Animal Service Client Objective-C"
                                          andVerificationService: verificationService];

  self.animalServiceClient = [[OCAnimalServiceClient alloc] initWithBaseUrl:self.animalMockService.baseUrl];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testGetAlligator {
  typedef void (^CompleteBlock)(void);
  
  [[[[self.animalMockService given:@"an alligator exists"]
                             uponReceiving:@"ObjC - a request for an alligator"]
                             withRequestHTTPMethod:PactHTTPMethodGET
                                              path:@"/alligator"
                                             query:nil headers:nil body:nil]
                             willRespondWithHTTPStatus:200
                                               headers:@{@"Content-Type": @"application/json"}
                                                  body: @"{ \"name\": \"Mary\"}" ];
  
  [self.animalMockService run:^(CompleteBlock testComplete) {
      Animal *animal = [self.animalServiceClient getAlligator];
      XCTAssertEqualObjects(animal.name, @"Mary");
      testComplete();
  } withTimeout: 10];
}

- (void)testWithQueryParams {
  typedef void (^CompleteBlock)(void);
  
  [[[[self.animalMockService given:@"an alligator exists"]
                             uponReceiving:@"ObjC - a request for animals living in water"]
                             withRequestHTTPMethod:PactHTTPMethodGET
                                              path:@"/animals"
                                             query: @{ @"live" : @"water" }
                                           headers:nil body: nil]
                             willRespondWithHTTPStatus:200
                                               headers:@{@"Content-Type": @"application/json"}
   body: @[ @{ @"name": [Matcher somethingLike:@"Mary"] } ] ];
  
  [self.animalMockService run:^(CompleteBlock testComplete) {
      NSArray *animals = [self.animalServiceClient findAnimalsLiving:@"water"];

      XCTAssertEqual(animals.count, 1);
      Animal *animal = animals[0];
      XCTAssertEqualObjects(animal.name, @"Mary");
      testComplete();
  }];
}

#pragma mark - Mather tests

- (void)testMatchingRegex {
  typedef void (^CompleteBlock)(void);
  
  [[[[self.animalMockService given:@"an alligator exists with a birthdate"]
                              uponReceiving:@"ObjC - a request for alligator with birthdate"]
                              withRequestHTTPMethod:PactHTTPMethodGET
                                path:@"/alligator"
                                query: nil headers:nil body: nil]
                              willRespondWithHTTPStatus:200
                                headers:@{@"Content-Type": @"application/json"}
                                body: @{
                                        @"name": @"Mary",
                                        @"dateOfBirth": [Matcher termWithMatcher:@"\\d{2}\\/\\d{2}\\/\\d{4}" generate:@"02/02/1999"]
                                      }];
  
  [self.animalMockService run:^(CompleteBlock testComplete) {
    Animal *animal = [self.animalServiceClient getAlligator];
    XCTAssertEqualObjects(animal.name, @"Mary");
    XCTAssertEqualObjects(animal.dob, @"02/02/1999");
    testComplete();
  }];
}

- (void)testMatchingType {
  typedef void (^CompleteBlock)(void);
  
  [[[[self.animalMockService given:@"an alligator exists with legs"]
                              uponReceiving:@"ObjC - a request for alligator with legs"]
                              withRequestHTTPMethod:PactHTTPMethodGET
                                path:@"/alligator"
                                query: nil headers:nil body: nil]
                              willRespondWithHTTPStatus:200
                                headers:@{@"Content-Type": @"application/json"}
                                body: @{
                                         @"name": @"Mary",
                                         @"legs": [Matcher somethingLike:@4]
                                       }];
  
  [self.animalMockService run:^(CompleteBlock testComplete) {
    Animal *animal = [self.animalServiceClient getAlligator];
    XCTAssertEqualObjects(animal.name, @"Mary");
    XCTAssertEqualObjects(animal.legs, @4);
    testComplete();
  }];
}


- (void)testMatchingVariableLengthArray {
  typedef void (^CompleteBlock)(void);
  
  [[[[self.animalMockService given:@"multiple land based animals exist"]
                              uponReceiving:@"ObjC - a request for animals living on land"]
                              withRequestHTTPMethod:PactHTTPMethodGET
                                path:@"/animals"
                                query: @{ @"live" : @"land" }
                                headers:nil body: nil]
                              willRespondWithHTTPStatus:200
                                headers:@{@"Content-Type": @"application/json"}
                                body: [Matcher eachLike:@{ @"name": @"Bruce", @"legs": @4 } min:1]];
  
  [self.animalMockService run:^(CompleteBlock testComplete) {
    NSArray *animals = [self.animalServiceClient findAnimalsLiving:@"land"];
    
    XCTAssertEqual(animals.count, 1);
    Animal *animal = animals[0];
    XCTAssertEqualObjects(animal.name, @"Bruce");
    XCTAssertEqualObjects(animal.legs, @4);
    testComplete();
  }];
}

- (void)testAsyncCall {
    typedef void (^CompleteBlock)(void);
    
    [[[self.animalMockService uponReceiving:@"an async request"]
      withRequestHTTPMethod:PactHTTPMethodGET
      path:@"/path"
      query:nil
      headers:nil
      body: nil]
     willRespondWithHTTPStatus:200
     headers:@{@"Content-Type": @"application/json"}
     body: @{}];
    
    [self.animalMockService run:^(CompleteBlock testComplete) {
        NSString *dataUrl = @"http://localhost:1234/path";
        NSURL *url = [NSURL URLWithString:dataUrl];
        NSURLSessionDataTask *asyncTask = [[NSURLSession sharedSession]
                                           dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                               testComplete();
                                           }];
        [asyncTask resume];
    }
     ];
}

@end
