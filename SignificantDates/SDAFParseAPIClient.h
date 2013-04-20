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
//- (NSMutableURLRequest *)GETRequestForClass:(NSString *)className parameters:(NSDictionary *)parameters;
//- (NSMutableURLRequest *)GETRequestForAllRecordsOfClass:(NSString *)className updatedAfterDate:(NSDate *)updatedDate;

@end
