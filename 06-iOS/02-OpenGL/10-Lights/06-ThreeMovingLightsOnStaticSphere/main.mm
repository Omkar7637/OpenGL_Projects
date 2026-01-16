//
//  main.m
//  OpenGLES
//
//  Created by apple on 07/11/24.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char* argv[])
{
    // Code
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];  // Create AutoRelease Pool For Memory Management
    
    // Get The AppDelegate Class Name In The Form Of String
    NSString *delegateClassName = NSStringFromClass([AppDelegate class]);
    
    UIApplicationMain(argc, argv, nil, delegateClassName);  // IOS Main
    
    [pool release];
    
    return 0;
}
