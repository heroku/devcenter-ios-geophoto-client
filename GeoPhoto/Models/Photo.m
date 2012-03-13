#import "Photo.h"

#import "GeoPhotoAPIClient.h"
#import "ISO8601DateFormatter.h"

static CGFloat const kPhotoJPEGQuality = 0.6;

static NSDate * NSDateFromISO8601String(NSString *string) {
    static ISO8601DateFormatter *_iso8601DateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _iso8601DateFormatter = [[ISO8601DateFormatter alloc] init];
    });
    
    if (!string) {
        return nil;
    }
    
    return [_iso8601DateFormatter dateFromString:string];
}

static NSString * NSStringFromCoordinate(CLLocationCoordinate2D coordinate) {
    return [NSString stringWithFormat:@"(%f, %f)", coordinate.latitude, coordinate.longitude];
}

static NSString * NSStringFromDate(NSDate *date) {
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setLocale:[NSLocale currentLocale]];
        [_dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [_dateFormatter setDoesRelativeDateFormatting:YES];
    });
    
    return [_dateFormatter stringFromDate:date];
}

@interface Photo ()
@property (strong, nonatomic, readwrite) NSString *imageURLString;
@property (strong, nonatomic, readwrite) NSString *thumbnailImageURLString;
@property (strong, nonatomic, readwrite) NSDate *timestamp;
@property (assign, nonatomic, readwrite) CLLocationDegrees latitude;
@property (assign, nonatomic, readwrite) CLLocationDegrees longitude;
@end

@implementation Photo
@synthesize imageURLString = _imageURLString;
@synthesize thumbnailImageURLString = _thumbnailImageURLString;
@synthesize timestamp = _timestamp;
@synthesize latitude = _latitude;
@synthesize longitude = _longitude;
@dynamic imageURL;
@dynamic location;

- (id)initWithAttributes:(NSDictionary *)attributes {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.imageURLString = [attributes valueForKeyPath:@"image_urls.original"];
    self.thumbnailImageURLString = [attributes valueForKeyPath:@"image_urls.thumbnail"];
    
    self.timestamp = NSDateFromISO8601String([attributes valueForKeyPath:@"created_at"]);
    
    self.latitude = [[attributes valueForKeyPath:@"lat"] doubleValue];
    self.longitude = [[attributes valueForKeyPath:@"lng"] doubleValue];
        
    return self;
}

- (void)dealloc {
    [_imageURLString release];
    [_thumbnailImageURLString release];
    [_timestamp release];
    [super dealloc];
}

- (NSURL *)imageURL {
    return [NSURL URLWithString:self.imageURLString];
}

- (NSURL *)thumbnailImageURL {
    return [NSURL URLWithString:self.thumbnailImageURLString];
}

- (CLLocation *)location {
    return [[[CLLocation alloc] initWithLatitude:self.latitude longitude:self.longitude] autorelease];
}

#pragma mark -

+ (void)photosNearLocation:(CLLocation *)location 
                     block:(void (^)(NSSet *photos, NSError *error))block 
{
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionary];
    [mutableParameters setObject:[NSNumber numberWithDouble:location.coordinate.latitude] forKey:@"lat"];
    [mutableParameters setObject:[NSNumber numberWithDouble:location.coordinate.longitude] forKey:@"lng"];  
    
    [[GeoPhotoAPIClient sharedClient] getPath:@"/photos" parameters:mutableParameters success:^(AFHTTPRequestOperation *operation, id JSON) {
        NSMutableSet *mutablePhotos = [NSMutableSet set];
        for (NSDictionary *attributes in [JSON valueForKeyPath:@"photos"]) {
            Photo *photo = [[[Photo alloc] initWithAttributes:attributes] autorelease];
            [mutablePhotos addObject:photo];
        }
        
        if (block) {
            block([NSSet setWithSet:mutablePhotos], nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block(nil, error);
        }
    }];
}

+ (void)uploadPhotoAtLocation:(CLLocation *)location
                        image:(UIImage *)image
                        block:(void (^)(Photo *photo, NSError *error))block
{
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionary];
    [mutableParameters setObject:[NSNumber numberWithDouble:location.coordinate.latitude] forKey:@"photo[lat]"];
    [mutableParameters setObject:[NSNumber numberWithDouble:location.coordinate.longitude] forKey:@"photo[lng]"];
    
    NSMutableURLRequest *mutableURLRequest = [[GeoPhotoAPIClient sharedClient] multipartFormRequestWithMethod:@"POST" path:@"/photos" parameters:mutableParameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:UIImageJPEGRepresentation(image, kPhotoJPEGQuality) name:@"photo[image]" fileName:@"image.jpg" mimeType:@"image/jpeg"];
    }];
    
    AFHTTPRequestOperation *operation = [[GeoPhotoAPIClient sharedClient] HTTPRequestOperationWithRequest:mutableURLRequest success:^(AFHTTPRequestOperation *operation, id JSON) {
        Photo *photo = [[[Photo alloc] initWithAttributes:[JSON valueForKeyPath:@"photo"]] autorelease];
        
        if (block) {
            block(photo, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block(nil, error);
        }
    }];
    [[GeoPhotoAPIClient sharedClient] enqueueHTTPRequestOperation:operation];
}

#pragma mark - MKAnnotation

- (NSString *)title {
    return NSStringFromCoordinate(self.coordinate);
}

- (NSString *)subtitle {
    return NSStringFromDate(self.timestamp);
}

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(self.latitude, self.longitude);
}

@end
