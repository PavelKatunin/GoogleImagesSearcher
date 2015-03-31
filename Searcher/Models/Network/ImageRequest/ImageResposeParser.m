#import "ImageResposeParser.h"
#import "ImageResponse.h"

@implementation ImageResposeParser

- (ApiResponse *)parseData:(NSData *)data {
    ImageResponse *imageResponse = [[ImageResponse alloc] init];
    UIImage *image = [UIImage imageWithData:data];
    imageResponse.image = image;
    return imageResponse;
}

@end
