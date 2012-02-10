#import "PhotosViewController.h"
#import "PhotoDetailViewController.h"

#import "Photo.h"

static CLLocationDistance const kMapRegionSpanDistance = 5000;

@interface PhotosViewController ()
@property (strong, nonatomic, readwrite) CLLocationManager *locationManager;
@property (strong, nonatomic, readwrite) NSSet *photos;
@property (strong, nonatomic, readwrite) MKMapView *mapView;
@property (strong, nonatomic, readwrite) UIActivityIndicatorView *activityIndicatorView;
@end

@implementation PhotosViewController
@synthesize locationManager = _locationManager;
@synthesize photos = _photos;
@synthesize mapView = _mapView;
@synthesize activityIndicatorView = _activityIndicatorView;

- (void)dealloc {    
    [_locationManager release];
    [_photos release];
    [super dealloc];
}

- (void)setPhotos:(NSSet *)photos {
    [self willChangeValueForKey:@"photos"];
    [_photos autorelease];
    _photos = [photos retain];
    [self didChangeValueForKey:@"photos"];
    
    if ([self isViewLoaded]) {
        [self.mapView addAnnotations:[self.photos allObjects]];
    }
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
    
    self.locationManager = [[[CLLocationManager alloc] init] autorelease];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    self.locationManager.distanceFilter = 80.0f;
    self.locationManager.purpose = NSLocalizedString(@"GeoPhoto uses your location to find nearby photos", nil);
}

- (void)viewDidUnload {
    [super viewDidUnload];
    _mapView = nil;
    _activityIndicatorView = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.locationManager startUpdatingLocation];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - Actions

- (void)takePhoto:(id)sender {
    UIImagePickerController *imagePickerController = [[[UIImagePickerController alloc] init] autorelease];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    [self.navigationController presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)viewCurrentPhoto:(id)sender {
    Photo *photo = [[self.mapView selectedAnnotations] lastObject];
    PhotoDetailViewController *viewController = [[[PhotoDetailViewController alloc] initWithPhoto:photo] autorelease];
    UINavigationController *navigationController = [[[UINavigationController alloc] initWithRootViewController:viewController] autorelease];
    viewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissModalViewControllerAnimated:)] autorelease];
    [self presentModalViewController:navigationController animated:YES];
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
            self.photos = photos;
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
    MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationIdentifier];
    if (!annotationView) {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationIdentifier];
    } else {
        annotationView.annotation = annotation;
    }
    
    annotationView.canShowCallout = YES;
    
    UIButton *detailDisclosureButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [detailDisclosureButton addTarget:self action:@selector(viewCurrentPhoto:) forControlEvents:UIControlEventTouchUpInside];
    annotationView.rightCalloutAccessoryView = detailDisclosureButton;
    
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
            self.photos = [self.photos setByAddingObject:photo];
        }
    }];
}

@end
