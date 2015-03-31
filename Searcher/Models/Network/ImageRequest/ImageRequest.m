#import "ImageRequest.h"
#import "ImageResposeParser.h"

@implementation ImageRequest

- (instancetype)initWithUrlString:(NSString *)urlString {
    self = [super initWithRequestString:urlString];
    if (self != nil) {
        self.parser = [[ImageResposeParser alloc] init];
    }
    return self;
}

@end
