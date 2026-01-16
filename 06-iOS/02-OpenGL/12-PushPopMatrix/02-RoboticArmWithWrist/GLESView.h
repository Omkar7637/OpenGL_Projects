//
//  MyView.h
//  OpenGLES
//
//  Created by apple on 09/11/24.
//

#import <UIKit/UIKit.h>

@interface GLESView: UIView <UIGestureRecognizerDelegate>

-(void)startDisplayLink;
-(void)stopDisplayLink;

@end
