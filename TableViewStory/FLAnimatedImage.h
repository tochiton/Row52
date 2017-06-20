//
//  FLAnimatedImage.h
//  TableViewStory
//
//  Created by Developer on 6/15/17.
//  Copyright © 2017 Developer. All rights reserved.
//

#ifndef FLAnimatedImage_h
#define FLAnimatedImage_h


#endif /* FLAnimatedImage_h */
FLAnimatedImage *image = [FLAnimatedImage animatedImageWithGIFData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://upload.wikimedia.org/wikipedia/commons/2/2c/Rotating_earth_%28large%29.gif"]]];
FLAnimatedImageView *imageView = [[FLAnimatedImageView alloc] init];
imageView.animatedImage = image;
imageView.frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
[self.view addSubview:imageView];
