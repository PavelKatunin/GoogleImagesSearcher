#import "ApiRequest+Protected.h"

@implementation ApiRequest (Protected)

@dynamic parser;

#pragma mark - Protected methods

- (ApiResponse *)parseResponseData:(NSData *)responseData {
    return [self.parser parseData:responseData];
}

- (void)dataUpdated {
    // for overriding
}

@end
