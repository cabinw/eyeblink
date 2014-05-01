//
//  BTViewController.h
//  BlinkTest
//
//  Created by Wukaibing on 14/4/14.
//  Copyright (c) 2014 Wukaibing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

@interface BTViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate>

@property IBOutlet UILabel *smile;
@property IBOutlet UILabel *blink;

/*!
 @brief	The capture session takes the input from the camera and capture it
 */
@property (nonatomic, strong) AVCaptureSession *captureSession;

/*!
 @brief	The UIImageView we use to display the image generated from the imageBuffer
 */
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
/*!
 @brief	The CALayer we use to display the CGImageRef generated from the imageBuffer
 */
@property (nonatomic, strong) CALayer *customLayer;
/*!
 @brief	The CALAyer customized by apple to display the video corresponding to a capture session
 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *prevLayer;

/*!
 @brief	This method initializes the capture session
 */
- (void)setupCapture;

@end
