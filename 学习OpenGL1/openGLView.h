//
//  openGLView.h
//  学习OpenGL1
//
//  Created by liter on 16/10/20.
//  Copyright © 2016年 liter. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface openGLView : UIView

- (void)customInit;

- (UIImage *)getImagefromScreen;

- (void)setImageBuffer:(CVPixelBufferRef) bufferRef;
@end
