#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface PhotosViewController : UIViewController <CLLocationManagerDelegate, MKMapViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
@private
    CLLocationManager *_locationManager;
    
    MKMapView *_mapView;
    UIActivityIndicatorView *_activityIndicatorView;
}

@end
