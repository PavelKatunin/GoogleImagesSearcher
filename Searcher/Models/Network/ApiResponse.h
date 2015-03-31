#import <Foundation/Foundation.h>

@interface ApiResponse : NSObject

@end

@protocol ApiResponseParser <NSObject>

- (ApiResponse *)parseData:(NSData *)data;

@end
