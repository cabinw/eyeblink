//
//  BTViewController.m
//  BlinkTest
//
//  Created by Wukaibing on 14/4/14.
//  Copyright (c) 2014 Wukaibing. All rights reserved.
//

#import "BTViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface BTViewController ()

@end

CORE_IMAGE_EXPORT NSString *const CIDetectorEyeBlink __OSX_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_7_0);


/* The value for this key is a bool NSNumber. If true, facial expressions, such as smile are extracted */
CORE_IMAGE_EXPORT NSString *const CIDetectorSmile __OSX_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_7_0);

@implementation BTViewController
@synthesize smile,blink,imageView;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self setupCapture];
}

- (void)setupCapture {
	/*We setup the input*/
	AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput
										  deviceInputWithDevice:[self frontCamera]
										  error:nil];
	/*We setupt the output*/
	AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
	/*While a frame is processes in -captureOutput:didOutputSampleBuffer:fromConnection: delegate methods no other frames are added in the queue.
	 If you don't want this behaviour set the property to NO */
	captureOutput.alwaysDiscardsLateVideoFrames = YES;
	/*We specify a minimum duration for each frame (play with this settings to avoid having too many frames waiting
	 in the queue because it can cause memory issues). It is similar to the inverse of the maximum framerate.
	 In this example we set a min frame duration of 1/10 seconds so a maximum framerate of 10fps. We say that
	 we are not able to process more than 10 frames per second.*/
	//captureOutput.minFrameDuration = CMTimeMake(1, 10);
	
	/*We create a serial queue to handle the processing of our frames*/
	dispatch_queue_t queue;
	queue = dispatch_queue_create("cameraQueue", NULL);
	[captureOutput setSampleBufferDelegate:self queue:queue];
    //	dispatch_release(queue);
	// Set the video output to store frame in BGRA (It is supposed to be faster)
	NSDictionary* videoSettings = @{(__bridge NSString*)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]};
	[captureOutput setVideoSettings:videoSettings];
	/*And we create a capture session*/
	self.captureSession = [[AVCaptureSession alloc] init];
	/*We add input and output*/
	[self.captureSession addInput:captureInput];
	[self.captureSession addOutput:captureOutput];
    /*We use medium quality, ont the iPhone 4 this demo would be laging too much, the conversion in UIImage and CGImage demands too much ressources for a 720p resolution.*/
    [self.captureSession setSessionPreset:AVCaptureSessionPresetHigh];
	/*We add the Custom Layer (We need to change the orientation of the layer so that the video is displayed correctly)*/
//	self.customLayer = [CALayer layer];
//	self.customLayer.frame = self.view.bounds;
//	self.customLayer.transform = CATransform3DRotate(CATransform3DIdentity, M_PI/2.0f, 0, 0, 1);
//	self.customLayer.contentsGravity = kCAGravityResizeAspectFill;
//	[self.view.layer addSublayer:self.customLayer];
//    [self.view bringSubviewToFront:smile];
    
	/*We add the preview layer*/
//	self.prevLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.captureSession];
//	self.prevLayer.frame = CGRectMake(100, 0, 100, 100);
//	self.prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//	[self.view.layer addSublayer: self.prevLayer];
	/*We start the capture*/
	[self.captureSession startRunning];
	
}

- (AVCaptureDevice *)frontCamera {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionFront) {
            return device;
        }
    }
    return nil;
}

-(BOOL) detect:(UIImage*) image{
    NSDate *currentTime=[NSDate date];
    int exifOrientation = 1;
    
    switch (image.imageOrientation) {
        case UIImageOrientationUp:
            exifOrientation = 1;
            break;
        case UIImageOrientationDown:
            exifOrientation = 3;
            break;
        case UIImageOrientationLeft:
            exifOrientation = 8;
            break;
        case UIImageOrientationRight:
            exifOrientation = 6;
            break;
        case UIImageOrientationUpMirrored:
            exifOrientation = 2;
            break;
        case UIImageOrientationDownMirrored:
            exifOrientation = 4;
            break;
        case UIImageOrientationLeftMirrored:
            exifOrientation = 5;
            break;
        case UIImageOrientationRightMirrored:
            exifOrientation = 7;
            break;
        default:
            break;
    }
    NSDictionary *detectorOptions = @{ CIDetectorAccuracy : CIDetectorAccuracyHigh };
    CIDetector *faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    
    NSArray *features = [faceDetector featuresInImage:[CIImage imageWithCGImage:image.CGImage]
                                              options:@{ CIDetectorSmile : @YES,
                                                         CIDetectorEyeBlink : @YES,
                                                         CIDetectorImageOrientation :[NSNumber numberWithInt:exifOrientation] }];

    for(CIFaceFeature *faceFeature in features)
    {
        if (!faceFeature.hasLeftEyePosition || !faceFeature.hasRightEyePosition) {
            [blink setText:@"没有检测到脸"];
            NSLog(@"Image processing time: %f",[[NSDate date] timeIntervalSinceDate:currentTime]);
            return  false;
        }
        
        if (faceFeature.hasSmile && faceFeature.leftEyeClosed && faceFeature.rightEyeClosed) {
            [imageView setImage:[UIImage imageNamed:@"close_smile.png"]];
            [smile setText:@"你笑了！"];
            [blink setText:@"你眨眼了！"];
            NSLog(@"Image processing time: %f",[[NSDate date] timeIntervalSinceDate:currentTime]);
            return true;
        }else if (faceFeature.hasSmile && (faceFeature.leftEyeClosed || faceFeature.rightEyeClosed)){
            [imageView setImage:[UIImage imageNamed:@"open_smile.png"]];
            [smile setText:@"你笑了！"];
            [blink setText:@"眼睛睁着"];
            NSLog(@"Image processing time: %f",[[NSDate date] timeIntervalSinceDate:currentTime]);
            return true;
        }else if (!faceFeature.hasSmile && (faceFeature.leftEyeClosed && faceFeature.rightEyeClosed)){
            [imageView setImage:[UIImage imageNamed:@"close_sad.png"]];
            [smile setText:@"你没笑"];
            [blink setText:@"你眨眼了！"];
            NSLog(@"Image processing time: %f",[[NSDate date] timeIntervalSinceDate:currentTime]);
            return true;
        }else if (!faceFeature.hasSmile && (faceFeature.leftEyeClosed || faceFeature.rightEyeClosed)){
            [imageView setImage:[UIImage imageNamed:@"open_sad.png"]];
            [smile setText:@"你没笑"];
            [blink setText:@"眼睛睁着"];
            NSLog(@"Image processing time: %f",[[NSDate date] timeIntervalSinceDate:currentTime]);
            return true;
        }
        
        return true;
    }
    
    [blink setText:@"没有检测到脸"];
    [smile setText:@"没有检测到脸"];
    NSLog(@"Image processing time: %f",[[NSDate date] timeIntervalSinceDate:currentTime]);
    return false;
}

#pragma mark -
#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
	   fromConnection:(AVCaptureConnection *)connection
{
	
	@autoreleasepool {
        
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        /*Lock the image buffer*/
        CVPixelBufferLockBaseAddress(imageBuffer,0);
        /*Get information about the image*/
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        
        /*Create a CGImageRef from the CVImageBufferRef*/
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGImageRef newImage = CGBitmapContextCreateImage(newContext);
        
        /*We release some components*/
        CGContextRelease(newContext);
        CGColorSpaceRelease(colorSpace);
        
        /*We display the result on the custom layer. All the display stuff must be done in the main thread because
         UIKit is no thread safe, and as we are not in the main thread (remember we didn't use the main_queue)
         we use performSelectorOnMainThread to call our CALayer and tell it to display the CGImage.*/
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.customLayer setContents:(__bridge id)newImage];
        });
        
        /*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly).
         Same thing as for the CALayer we are not in the main thread so ...*/
        UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
        
        /*We relase the CGImageRef*/
        CGImageRelease(newImage);
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self detect:image];
//            [self.imageView setImage:image];
//            if ([self eyeBlinked:image]) {
//                [smile setText:@"笑了"];
//            }else{
//                [smile setText:@"没笑"];
//            }
            
        });
        
//        [self performSelectorInBackground:@selector(detect:) withObject:image];
        
        /*We unlock the  image buffer*/
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    }
}

//-(void) detect:(UIImage*)image{
//    if ([self eyeBlinked:image]) {
//        [one setText:@"blinked"];
//    }else{
//        [one setText:@"not blinked"];
//    }
//}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
