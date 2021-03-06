#import "RSSignatureView.h"
#import "RCTConvert.h"
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "PPSSignatureView.h"
#import "RSSignatureViewManager.h"

#define DEGREES_TO_RADIANS(x) (M_PI * (x) / 180.0)

@implementation RSSignatureView {
  CAShapeLayer *_border;
  BOOL _loaded;
  EAGLContext *_context;
  UILabel *titleLabel;
}

@synthesize sign;
@synthesize manager;

- (instancetype)init
{
  if ((self = [super init])) {
    _border = [CAShapeLayer layer];
    _border.strokeColor = [UIColor blackColor].CGColor;
    _border.fillColor = nil;
    _border.lineDashPattern = @[@4, @2];
    
    [self.layer addSublayer:_border];
  }
  
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  if (!_loaded) {
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    CGSize screen = self.bounds.size;
    
    self.sign = [[PPSSignatureView alloc]
                 initWithFrame: CGRectMake(0, 0, screen.width, screen.height)
                 context: _context];
    
    [self addSubview:sign];
    titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, sign.bounds.size.height - 80, 24)];
    [titleLabel setCenter:CGPointMake(40, sign.bounds.size.height/2)];
    [titleLabel setTransform:CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(90))];
    [titleLabel setText:@"x_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _"];
    [titleLabel setLineBreakMode:NSLineBreakByClipping];
    [titleLabel setTextAlignment: NSTextAlignmentLeft];
    [titleLabel setTextColor:[UIColor colorWithRed:200/255.f green:200/255.f blue:200/255.f alpha:1.f]];
    //[titleLabel setBackgroundColor:[UIColor greenColor]];
    [sign addSubview:titleLabel];
    
    
    //Save button
    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [saveButton setTransform:CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(90))];
    [saveButton addTarget:self action:@selector(onSaveButtonPressed)
         forControlEvents:UIControlEventTouchUpInside];
    [saveButton setTitle:@"Save" forState:UIControlStateNormal];
    [saveButton setTitleColor:[UIColor whiteColor]forState: UIControlStateNormal];
    saveButton.titleLabel.font =  [UIFont fontWithName:@"AvenirNext-Medium" size:18];
    
    CGSize buttonSize = CGSizeMake(55, 80.0); //Width/Height is swapped
    
    saveButton.frame = CGRectMake(sign.bounds.size.width - buttonSize.width, sign.bounds.size.height - buttonSize.height, buttonSize.width, buttonSize.height);
    [saveButton setBackgroundColor:[UIColor colorWithRed:72.0f/255.0f green:209.0f/255.0f blue:204.0f/255.0f alpha:1.0]];
    [sign addSubview:saveButton];
    
    //Clear button
    UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [clearButton setTransform:CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(90))];
    [clearButton addTarget:self action:@selector(onClearButtonPressed)
          forControlEvents:UIControlEventTouchUpInside];
    [clearButton setTitle:@"Reset" forState:UIControlStateNormal];
    [clearButton setTitleColor:[UIColor whiteColor]forState: UIControlStateNormal];
    clearButton.titleLabel.font =  [UIFont fontWithName:@"AvenirNext-Medium" size:18];
    
    clearButton.frame = CGRectMake(sign.bounds.size.width - buttonSize.width, 0, buttonSize.width, buttonSize.height);
    [clearButton setBackgroundColor:[UIColor colorWithRed:72.0f/255.0f green:209.0f/255.0f blue:204.0f/255.0f alpha:1.0]];
    [sign addSubview:clearButton];
    
    //cancel button
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [cancelButton setTransform:CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(90))];
    [cancelButton addTarget:self action:@selector(onCancelButtonPressed)
           forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor whiteColor]forState: UIControlStateNormal];
    cancelButton.titleLabel.font =  [UIFont fontWithName:@"AvenirNext-Medium" size:18];
    
    cancelButton.frame = CGRectMake(0, sign.bounds.size.height - buttonSize.height, buttonSize.width, buttonSize.height);
    [cancelButton setBackgroundColor:[UIColor colorWithRed:72.0f/255.0f green:209.0f/255.0f blue:204.0f/255.0f alpha:1.0]];
    [sign addSubview:cancelButton];
    
  }
  _loaded = true;
  _border.path = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
  _border.frame = self.bounds;
}

-(void) onSaveButtonPressed {
  UIImage *signImage = [self.sign signatureImage];
  UIImage *signImageRotated = [self imageRotatedByDegrees:signImage deg:-90];
  
  NSError *error;
  
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths firstObject];
  NSString *tempPath = [documentsDirectory stringByAppendingFormat:@"/signature.png"];
  
  //remove if file already exists
  if ([[NSFileManager defaultManager] fileExistsAtPath:tempPath]) {
    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:&error];
    if (error) {
      NSLog(@"Error: %@", error.debugDescription);
    }
  }
  
  // Convert UIImage object into NSData (a wrapper for a stream of bytes) formatted according to PNG spec
  NSData *imageData = UIImagePNGRepresentation(signImageRotated);
  BOOL isSuccess = [imageData writeToFile:tempPath atomically:YES];
  if (isSuccess) {
    NSString *base64Encoded = [imageData base64EncodedStringWithOptions:0];
    [self.manager saveImage: tempPath withEncoded:base64Encoded];
  }
}

-(void) onClearButtonPressed {
  [self.sign erase];
}

-(void) onCancelButtonPressed {
  [self.manager cancelSignature];
}

- (UIImage *)imageRotatedByDegrees:(UIImage*)oldImage deg:(CGFloat)degrees{
  //Calculate the size of the rotated view's containing box for our drawing space
  UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,oldImage.size.width, oldImage.size.height)];
  CGAffineTransform t = CGAffineTransformMakeRotation(degrees * M_PI / 180);
  rotatedViewBox.transform = t;
  CGSize rotatedSize = rotatedViewBox.frame.size;
  
  //Create the bitmap context
  UIGraphicsBeginImageContext(rotatedSize);
  CGContextRef bitmap = UIGraphicsGetCurrentContext();
  
  //Move the origin to the middle of the image so we will rotate and scale around the center.
  CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
  
  //Rotate the image context
  CGContextRotateCTM(bitmap, (degrees * M_PI / 180));
  
  //Now, draw the rotated/scaled image into the context
  CGContextScaleCTM(bitmap, 1.0, -1.0);
  CGContextDrawImage(bitmap, CGRectMake(-oldImage.size.width / 2, -oldImage.size.height / 2, oldImage.size.width, oldImage.size.height), [oldImage CGImage]);
  
  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return newImage;
}

@end
