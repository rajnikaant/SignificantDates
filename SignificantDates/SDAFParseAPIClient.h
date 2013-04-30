//
//  SDAFParseAPIClient.h
//  SignificantDates
//
//  Created by Chris Wagner on 7/1/12.
//

#import "AFHTTPClient.h"

@interface SDAFParseAPIClient : AFHTTPClient

+ (SDAFParseAPIClient *)sharedClient;

-(NSMutableURLRequest *)POSTRequestForAccountCreateWithEmail:(NSString*)email;
-(NSMutableURLRequest *)POSTRequestForAccountSearchWithEmail:(NSString*)email;
-(NSMutableURLRequest *)POSTRequestForSendDataWithJSONString:(NSString*)jsonString;
-(NSMutableURLRequest *)GETRequestForDataWithJSONString:(NSString*)jsonString;

@end
