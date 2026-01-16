//
//  MyView.h
//  OpenGLES
//
//  Created by apple on 29/10/24.
//

#import <UIKit/UIKit.h>

@interface GLESView: UIView <UIGestureRecognizerDelegate>

-(void)startDisplayLink;
-(void)stopDisplayLink;

@end
