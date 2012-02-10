#import <Foundation/Foundation.h>
#import "AFHTTPClient.h"

@interface GeoPhotoAPIClient : AFHTTPClient

+ (GeoPhotoAPIClient *)sharedClient;

@end
