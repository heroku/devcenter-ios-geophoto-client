#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface PhotosViewController : UIViewController <CLLocationManagerDelegate, MKMapViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
@private
    CLLocationManager *_locationManager;
    NSSet *_photos;
    
    MKMapView *_mapView;
    UIActivityIndicatorView *_activityIndicatorView;
}

@end
