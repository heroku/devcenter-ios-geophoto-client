#import "GeoPhotoAPIClient.h"

#import "AFJSONRequestOperation.h"

NSString * const kAFGeoPhotoAPIBaseURLString = @"http://localhost:5000/";

@implementation GeoPhotoAPIClient

+ (GeoPhotoAPIClient *)sharedClient {
    static GeoPhotoAPIClient *_sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:kAFGeoPhotoAPIBaseURLString]];
    });
    
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	[self setDefaultHeader:@"Accept" value:@"application/json"];
    	    
    return self;
}

@end
