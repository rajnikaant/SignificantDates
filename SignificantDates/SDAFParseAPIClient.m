//
//  SDAFParseAPIClient.m
//  SignificantDates
//
//  Created by Chris Wagner on 7/1/12.
//

#import "SDAFParseAPIClient.h"
#import "AFJSONRequestOperation.h"

static NSString * const kSDFParseAPIBaseURLString = @"http://192.168.1.111:3000/";

@implementation SDAFParseAPIClient

+ (SDAFParseAPIClient *)sharedClient {
    static SDAFParseAPIClient *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[SDAFParseAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kSDFParseAPIBaseURLString]];
    }); 
    
    return sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [self setParameterEncoding:AFJSONParameterEncoding];
    }
    
    return self;
}

-(NSMutableURLRequest *)POSTRequestForAccountSearchWithEmail:(NSString*)email {
    NSMutableURLRequest *request = nil;
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:email forKey:@"email"];
    [params setValue:[[[UIDevice currentDevice] identifierForVendor] UUIDString] forKey:@"ifv"];
    request = [self requestWithMethod:@"POST"
                                 path:@"accounts/search.json"
                           parameters:params];
    return request;
}

-(NSMutableURLRequest *)POSTRequestForAccountCreateWithEmail:(NSString*)email {
    NSMutableURLRequest *request = nil;
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:email forKey:@"email"];
    [params setValue:[[[UIDevice currentDevice] identifierForVendor] UUIDString] forKey:@"ifv"];
    request = [self requestWithMethod:@"POST"
                                 path:@"accounts.json"
                           parameters:params];
    return request;
}

-(NSMutableURLRequest *)POSTRequestForSendDataWithJSONString:(NSString*)jsonString {
    NSMutableURLRequest *request = nil;
    NSDictionary *params = [NSDictionary dictionaryWithObject:jsonString  forKey:@"accounts"];
    request = [self requestWithMethod:@"POST"
                                 path:@"syncs/push.json"
                           parameters:params];
    return request;
}

-(NSMutableURLRequest *)GETRequestForDataWithJSONString:(NSString*)jsonString {
    NSMutableURLRequest *request = nil;
    NSMutableDictionary *params =
    [NSMutableDictionary dictionaryWithObject:[[[UIDevice currentDevice] identifierForVendor] UUIDString]
                                       forKey:@"ifv"];
    [params setValue:jsonString forKey:@"accounts"];
    request = [self requestWithMethod:@"GET"
                                 path:@"syncs/recent.json"
                           parameters:params];
    return request;
}

@end
