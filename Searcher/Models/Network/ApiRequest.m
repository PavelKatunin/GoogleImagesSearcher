#import "ApiRequest.h"
#import "ApiRequest+Protected.h"

@interface ApiRequest () <NSURLConnectionDataDelegate>

@property (nonatomic, strong) id <ApiResponseParser> parser;
@property (nonatomic, strong) NSURLConnection *currentConnection;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSURLRequest *request;

@property (assign) BOOL isExecuting;
@property (assign) BOOL isFinished;

@end

@implementation ApiRequest

#pragma mark - initialization

- (instancetype)initWithRequestString:(NSString *)requestString {
    self = [super init];
    if (self != nil) {
        self.urlString = requestString;
        self.request = [NSURLRequest requestWithURL:[NSURL URLWithString:[requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:self.request
                                                                      delegate:self
                                                              startImmediately:NO];
        self.currentConnection = connection;
    }
    return self;
}

#pragma mark - NSOperation

- (BOOL)isConcurrent {
    return YES;
}

- (void)start {
    if ([self isCancelled]) {
        [self setIsFinished:YES];
        [self setIsExecuting:NO];
    }
    else {
        [self setIsExecuting:YES];
        [self setIsFinished:NO];
        
        self.data = [[NSMutableData alloc] init];
        
        self.currentConnection = [[NSURLConnection alloc] initWithRequest:self.request
                                                                 delegate:self
                                                         startImmediately:NO];
        [self.currentConnection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                              forMode:NSDefaultRunLoopMode];
        [self.currentConnection start];
    }
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.data = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (![self isCancelled]) {
        [self.data appendData:data];
    }
    else {
        [self setIsExecuting:NO];
        [self setIsFinished:YES];
        [connection cancel];
        self.data = nil;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self dataUpdated];
    [self.delegate apiRequest:self didReturnResponse:[self parseResponseData:self.data]];
    [self setIsExecuting:NO];
    [self setIsFinished:YES];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.delegate apiRequest:self didReturnError:error];
    [self setIsExecuting:NO];
    [self setIsFinished:YES];
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    return YES;
}

@end
