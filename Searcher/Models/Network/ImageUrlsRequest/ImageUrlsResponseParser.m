#import "ImageUrlsResponseParser.h"
#import "ImageUrlsResponse.h"

@implementation ImageUrlsResponseParser

- (ApiResponse *)parseData:(NSData *)data {
    ImageUrlsResponse *response = nil;
    NSError *error;
    id object = [NSJSONSerialization
                 JSONObjectWithData:data
                 options:0
                 error:&error];
    
    if ([object isKindOfClass:[NSDictionary class]]) {
        response = [[ImageUrlsResponse alloc] init];
        __block NSMutableArray *urls = [[NSMutableArray alloc] init];
        NSDictionary *responseData = object[@"responseData"];
        NSArray *results = responseData[@"results"];
        [results enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *result = obj;
            [urls addObject:result[@"url"]];
        }];
        response.urls = urls;
    }
    
    return response;
}

@end
