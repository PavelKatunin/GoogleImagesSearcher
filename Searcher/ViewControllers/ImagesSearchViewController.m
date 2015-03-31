#import "ImagesSearchViewController.h"
#import "ImageUrlsRequest.h"
#import "ImageUrlsResponse.h"
#import "ImageDescriptor.h"
#import "ImageResponse.h"
#import "ImageRequest.h"

static NSString *const kImageCellId = @"ImageCellId";

@interface ImagesSearchViewController () <UITextFieldDelegate,
                              UITableViewDataSource,
                              UITableViewDelegate,
                              ApiRequestDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *tableViewBottomOffset;

@property (nonatomic, strong) NSArray *imageDescriptors;

@property (nonatomic, strong) ImageUrlsRequest *urlsRequest;
@property (nonatomic, strong) NSOperationQueue *loadingImagesQueue;

- (void)startLoadImagesWithRequest:(NSString *)request;
- (void)startLoadImagesForDescriptors:(NSArray *)descriptors;
- (void)addLoadingImageOperationWithUrl:(NSString *)url;
- (NSArray *)imageDescriptorsWithUrls:(NSArray *)urls;
- (NSUInteger)indexOfImageDescriptorForUrlString:(NSString *)url;

- (void)subscribeForNotification:(NSString *)name selector:(SEL)selector;
- (void)unsubscribeFromNotification:(NSString *)name;
- (void)subscribeKeyboardNotifications;
- (void)unsubscribeKeyboardNotifications;

@end

@implementation ImagesSearchViewController

#pragma mark - view life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.loadingImagesQueue = [[NSOperationQueue alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self subscribeKeyboardNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self unsubscribeKeyboardNotifications];
}

#pragma mark - ApiRequestDelegate

- (void)apiRequest:(ApiRequest *)request didReturnResponse:(ApiResponse *)response {
    if ([response isKindOfClass:[ImageUrlsResponse class]]) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        ImageUrlsResponse *urlsResponse = (ImageUrlsResponse *)response;
        self.imageDescriptors = [self imageDescriptorsWithUrls:urlsResponse.urls];
        
        [self startLoadImagesForDescriptors:self.imageDescriptors];
        [self.tableView reloadData];
    }
    else if ([response isKindOfClass:[ImageResponse class]]) {
        if (self.imageDescriptors != nil) {
            ImageResponse *imageResponse = (ImageResponse *)response;
            NSUInteger index = [self indexOfImageDescriptorForUrlString:request.urlString];
            ImageDescriptor *descriptor = self.imageDescriptors[index];
            descriptor.image = imageResponse.image;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]
                                  withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

- (void)apiRequest:(ApiRequest *)request didReturnError:(NSError *)error {
    // TODO: handle, localize
    if ([request isKindOfClass:[ImageUrlsRequest class]]) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Connection lost"
                                                                       message:@"connection lost"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        ImagesSearchViewController * __weak wSelf = self;
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok"
                                                   style:UIAlertActionStyleCancel
                                                 handler:^(UIAlertAction *action) {
                                                     [wSelf dismissViewControllerAnimated:YES
                                                                               completion:nil];
                                                 }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    self.imageDescriptors = nil;
    [self.tableView reloadData];
    [self startLoadImagesWithRequest:textField.text];
    [textField resignFirstResponder];
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.imageDescriptors.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kImageCellId
                                                                 forIndexPath:indexPath];
    ImageDescriptor *descriptor = self.imageDescriptors[indexPath.row];
    cell.imageView.image = descriptor.image ? descriptor.image : [UIImage imageNamed:@"ph.jpg"];
    cell.textLabel.text = descriptor.urlString;
    return cell;
}

#pragma mark - private methods

- (void)subscribeForNotification:(NSString *)name selector:(SEL)selector {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:selector
                                                 name:name
                                               object:nil];
}

- (void)unsubscribeFromNotification:(NSString *)name {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:name
                                                  object:nil];
}

- (void)subscribeKeyboardNotifications {
    [self subscribeForNotification:UIKeyboardWillShowNotification selector:@selector(keyboardWillShowNotification:)];
    [self subscribeForNotification:UIKeyboardWillHideNotification selector:@selector(keyboardWillHideNotification:)];
}

- (void)unsubscribeKeyboardNotifications {
    [self unsubscribeFromNotification:UIKeyboardWillShowNotification];
    [self unsubscribeFromNotification:UIKeyboardDidShowNotification];
    [self unsubscribeFromNotification:UIKeyboardWillHideNotification];
    [self unsubscribeFromNotification:UIKeyboardDidHideNotification];
}

- (void)startLoadImagesWithRequest:(NSString *)request {
    [self.urlsRequest cancel];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    self.urlsRequest = [[ImageUrlsRequest alloc] initWithSerchString:request];
    self.urlsRequest.delegate = self;
    [self.urlsRequest start];
}

- (void)startLoadImagesForDescriptors:(NSArray *)descriptors {
    [self.loadingImagesQueue cancelAllOperations];
    [self.imageDescriptors enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ImageDescriptor *descriptor = (ImageDescriptor *)obj;
        [self addLoadingImageOperationWithUrl:descriptor.urlString];
    }];
}

- (void)addLoadingImageOperationWithUrl:(NSString *)url {
    ImageRequest *imageRequest = [[ImageRequest alloc] initWithUrlString:url];
    imageRequest.delegate = self;
    [self.loadingImagesQueue addOperation:imageRequest];
}

- (NSArray *)imageDescriptorsWithUrls:(NSArray *)urls {
    __block NSMutableArray *descriptors = [NSMutableArray array];
    [urls enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ImageDescriptor *descriptor = [[ImageDescriptor alloc] init];
        descriptor.urlString = obj;
        [descriptors addObject:descriptor];
    }];
    return descriptors;
}

- (NSUInteger)indexOfImageDescriptorForUrlString:(NSString *)url {
    NSUInteger index = [self.imageDescriptors indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        ImageDescriptor *descriptor = (ImageDescriptor *)obj;
        return [descriptor.urlString isEqualToString:url];
    }];
    return index;
}

#pragma mark - Keyboard notifications

- (void)keyboardWillShowNotification:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
        
    const CGRect keyboardFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    const CGPoint keyboardTargetOrigin = [self.view convertRect:keyboardFrame
                                                           fromView:nil].origin;
    const CGFloat viewOverlapValue = CGRectGetHeight(self.view.bounds) - keyboardTargetOrigin.y;
        
    self.tableViewBottomOffset.constant = -viewOverlapValue;
    [self.view setNeedsUpdateConstraints];
        
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[info[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[info[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
        
    [self.view layoutIfNeeded];
        
    [UIView commitAnimations];
}

- (void)keyboardWillHideNotification:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    
    self.tableViewBottomOffset.constant = 0;
    [self.view setNeedsUpdateConstraints];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[info[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[info[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [self.view layoutIfNeeded];
    
    [UIView commitAnimations];
}

@end
