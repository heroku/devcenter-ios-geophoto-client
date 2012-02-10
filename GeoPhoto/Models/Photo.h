#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface Photo : NSObject <MKAnnotation> {
@private
    NSString *_imageURLString;
    NSString *_thumbnailImageURLString;
    NSDate *_timestamp;
    
    CLLocationDegrees _latitude;
    CLLocationDegrees _longitude;
}

@property (strong, nonatomic, readonly) NSURL *imageURL;
@property (strong, nonatomic, readonly) NSURL *thumbnailImageURL;
@property (strong, nonatomic, readonly) NSDate *timestamp;
@property (strong, nonatomic, readonly) CLLocation *location;

- (id)initWithAttributes:(NSDictionary *)attributes;

+ (void)photosNearLocation:(CLLocation *)location 
                     block:(void (^)(NSSet *photos, NSError *error))block;

+ (void)uploadPhotoAtLocation:(CLLocation *)location
                        image:(UIImage *)image
                        block:(void (^)(Photo *photo, NSError *error))block;

@end
