#import "ApiRequest.h"

@interface ApiRequest (Protected)

@property (nonatomic, strong) id <ApiResponseParser> parser;

- (ApiResponse *)parseResponseData:(NSData *)responseData;
- (void)dataUpdated;

@end
