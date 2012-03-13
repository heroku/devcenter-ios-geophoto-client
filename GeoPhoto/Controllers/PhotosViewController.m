#import "PhotosViewController.h"

#import "Photo.h"

#import "AFJSONRequestOperation.h"
#import "AFImageRequestOperation.h"

static CLLocationDistance const kMapRegionSpanDistance = 5000;

@interface PhotosViewController ()
@property (strong, nonatomic, readwrite) CLLocationManager *locationManager;
@property (strong, nonatomic, readwrite) MKMapView *mapView;
@property (strong, nonatomic, readwrite) UIActivityIndicatorView *activityIndicatorView;
@end

@implementation PhotosViewController
@synthesize locationManager = _locationManager;
@synthesize mapView = _mapView;
@synthesize activityIndicatorView = _activityIndicatorView;

- (void)dealloc {    
    [_locationManager release];
    [super dealloc];
}

#pragma mark - UIViewController

- (void)loadView {
    [super loadView];
    
    self.mapView = [[[MKMapView alloc] initWithFrame:self.view.bounds] autorelease];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    [self.view addSubview:self.mapView];
    
    self.activityIndicatorView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
    self.activityIndicatorView.hidesWhenStopped = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"GeoPhoto", nil);
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:self.activityIndicatorView] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(takePhoto:)] autorelease];
    
    NSURL *url = [NSURL URLWithString:@"http://localhost:5000/photos.json"];
    [AFJSONRequestOperation JSONRequestOperationWithRequest:[NSURLRequest requestWithURL:url] success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        for (NSDictionary *attributes in [JSON valueForKeyPath:@"photos"]) {
            Photo *photo = [[[Photo alloc] initWithAttributes:attributes] autorelease];
            [self.mapView addAnnotation:photo];
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"Error: %@", error);
    }];
    
    self.locationManager = [[[CLLocationManager alloc] init] autorelease];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    self.locationManager.distanceFilter = 80.0f;
    self.locationManager.purpose = NSLocalizedString(@"GeoPhoto uses your location to find nearby photos", nil);
    [self.locationManager startUpdatingLocation];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    [self.locationManager stopUpdatingLocation];
    
    _mapView = nil;
    _activityIndicatorView = nil;
}

#pragma mark - Actions

- (void)takePhoto:(id)sender {
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    
    UIImagePickerController *imagePickerController = [[[UIImagePickerController alloc] init] autorelease];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = sourceType;
    [self.navigationController presentViewController:imagePickerController animated:YES completion:nil];
}

#pragma mark - CLLocationMaangerDelegate

- (void)locationManager:(CLLocationManager *)manager 
    didUpdateToLocation:(CLLocation *)newLocation 
           fromLocation:(CLLocation *)oldLocation 
{
    [self.activityIndicatorView startAnimating];
    [Photo photosNearLocation:newLocation block:^(NSSet *photos, NSError *error) {
        [self.activityIndicatorView stopAnimating];
        if (error) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Nearby Photos Failed", nil) message:[error localizedFailureReason] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil] show];
        } else {
            [self.mapView addAnnotations:[photos allObjects]];
        }
    }];
    
    [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(manager.location.coordinate, kMapRegionSpanDistance, kMapRegionSpanDistance) animated:YES];
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView 
            viewForAnnotation:(id<MKAnnotation>)annotation 
{
    if (![annotation isKindOfClass:[Photo class]]) {
        return nil;
    }
    
    static NSString *AnnotationIdentifier = @"Pin";
    MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationIdentifier];
    if (!annotationView) {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationIdentifier];
        annotationView.canShowCallout = YES;
    } else {
        annotationView.annotation = annotation;
    }
    
    annotationView.image = [UIImage imageNamed:@"photo-placeholder.png"];
    AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:[NSURLRequest requestWithURL:[(Photo *)annotation thumbnailImageURL]] success:^(UIImage *image) {
        annotationView.image = image;
    }];
    [[NSOperationQueue mainQueue] addOperation:operation];

    return annotationView;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)imagePickerController 
        didFinishPickingImage:(UIImage *)image 
                  editingInfo:(NSDictionary *)editingInfo 
{
    [imagePickerController dismissModalViewControllerAnimated:YES]; 
    [self.activityIndicatorView startAnimating];
    [Photo uploadPhotoAtLocation:self.locationManager.location image:image block:^(Photo *photo, NSError *error) {
        [self.activityIndicatorView stopAnimating];

        if (error) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Upload Failed", nil) message:[error localizedFailureReason] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil] show];
        } else {
            [self.mapView addAnnotation:photo];
        }
    }];
}

@end
