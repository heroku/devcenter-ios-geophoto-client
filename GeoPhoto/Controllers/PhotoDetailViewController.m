#import "PhotoDetailViewController.h"

#import "Photo.h"

#import "UIImageView+AFNetworking.h"

@interface PhotoDetailViewController ()
@property (readwrite, nonatomic, retain) Photo *photo;
@property (readwrite, nonatomic, retain) UIImageView *imageView;
@end

@implementation PhotoDetailViewController
@synthesize photo = _photo;
@synthesize imageView = _imageView;

- (id)initWithPhoto:(Photo *)photo {
    self = [super initWithNibName:nil bundle:nil];
    if (!self) {
        return nil;
    }
    
    self.photo = photo;
    
    return self;
}

- (void)dealloc {
    [_photo release];
    [_imageView release];
    [super dealloc];
}

#pragma mark - UIViewController

#pragma mark - UIViewController

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [UIColor underPageBackgroundColor];
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.photo.title;
    
    [self.imageView setImageWithURL:self.photo.imageURL];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    _imageView = nil;
}

@end
