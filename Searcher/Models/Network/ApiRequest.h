#import <Foundation/Foundation.h>
#import "ApiResponse.h"

@protocol ApiRequestDelegate;

@interface ApiRequest : NSOperation

@property (nonatomic, weak) id<ApiRequestDelegate> delegate;
@property (nonatomic, strong) NSString *urlString;

@property (readonly) BOOL isExecuting;
@property (readonly) BOOL isFinished;

- (instancetype)initWithRequestString:(NSString *)requestString;
- (instancetype)init NS_UNAVAILABLE;

@end

@protocol ApiRequestDelegate <NSObject>

- (void)apiRequest:(ApiRequest *)request didReturnResponse:(ApiResponse *)response;
- (void)apiRequest:(ApiRequest *)request didReturnError:(NSError *)error;

@end
