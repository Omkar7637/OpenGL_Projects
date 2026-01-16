//
//  AppDelegate.m
//  OpenGLES
//
//  Created by apple on 06/11/24.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "GLESView.h"

@implementation AppDelegate
{
@private
    UIWindow *window;
    ViewController *viewController;
    GLESView *glesView;
}

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Code
    
    CGRect screenRect = [[UIScreen mainScreen]bounds];      // Get The IPhone Screen Rectangle
    window = [[UIWindow alloc]initWithFrame:screenRect];    // Create Window
    viewController = [[ViewController alloc]init];          // Create View Controller
    [window setRootViewController:viewController];          // Set Above ViewController As Window's View Controller
    glesView = [[GLESView alloc]initWithFrame:screenRect];  // Create Our Custom View
    [viewController setView:glesView];                      // Set Above View As View Of View Controller
    [glesView release];                                     // Decrement The Reference Count Of View
    [window makeKeyAndVisible];                             // Set Focus On This Window And Make It Visible
    
    // Start Display Link
    [glesView startDisplayLink];
    
    return YES;
}

-(void)applicationWillResignActive:(UIApplication *)application
{
    // Code
    
    // Stop Display Link
    [glesView stopDisplayLink];
}

-(void)applicationDidEnterBackground:(UIApplication *)application
{
    // Code
}

-(void)applicationWillEnterForeground:(UIApplication *)application
{
    // Code
}

-(void)applicationDidBecomeActive:(UIApplication *)application
{
    // Code
    
    // Start Display Link
    [glesView startDisplayLink];
}

-(void)applicationWillTerminate:(UIApplication *)application
{
    // Code
    
    // Stop Display Link
    [glesView stopDisplayLink];
}

-(void)dealloc
{
    // Code
    [super dealloc];
    
    [glesView release];
    [viewController release];
    [window release];
}

@end
