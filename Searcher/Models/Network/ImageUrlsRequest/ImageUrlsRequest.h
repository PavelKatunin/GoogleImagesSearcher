#import <Foundation/Foundation.h>
#import "ApiRequest+Protected.h"

@interface ImageUrlsRequest : ApiRequest

- (instancetype)initWithSerchString:(NSString *)searchString;

@end
