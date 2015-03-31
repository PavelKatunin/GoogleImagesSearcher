#import "ImageUrlsRequest.h"
#import "ImageUrlsResponseParser.h"

static NSString *const kRequestUrlFormat = @"https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=%@&rsz=8&start=10";

@implementation ImageUrlsRequest

#pragma mark - initialization

- (instancetype)initWithSerchString:(NSString *)searchString {
    self = [super initWithRequestString:[NSString stringWithFormat:kRequestUrlFormat,
                                                                   searchString]];
    if (self != nil) {
        self.parser = [[ImageUrlsResponseParser alloc] init];
    }
    return self;
}

@end
