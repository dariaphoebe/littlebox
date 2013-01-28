/*
 
 Copyright 2013 Klout
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

#import "LBUtils.h"

@implementation LBUtils(image)

+ (UIImage*)squareCroppedImageFromImage:(UIImage*)originalImage withSize:(int)dimension {
    if (!originalImage) return nil;
    // YES for opaque, scale 0.0 to use correct pixel dimensions for retina/nonretina
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(dimension, dimension), YES, 0.0);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextClipToRect(currentContext, CGRectMake(0, 0, dimension, dimension));
    int width = originalImage.size.width;
    int height = originalImage.size.height;
    int xOffset = 0;
    int yOffset = 0;
    if (width > height) {
        // scale height to dimension, scale width proportionately
        width = (((float)(width)) / height) * dimension;
        height = dimension;
        xOffset = (dimension - width) / 2.0; // a negative value
    } else {
        // scale width to dimesion, scale height
        height = (((float)(height)) / width) * dimension;
        width = dimension;
        // set yOffset to 33% of the total amount of height cropped, thus placing the crop rectangle towards the top of the portrait in an attempt to avoid cropping people's eyes/foreheads/etc.
        yOffset = (dimension - height) / 3.0; // a negative value
    }
    [originalImage drawInRect:CGRectMake(xOffset, yOffset, width, height)]; // this respects orientation properties
    UIImage *cropScaled = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return cropScaled;
}

@end
