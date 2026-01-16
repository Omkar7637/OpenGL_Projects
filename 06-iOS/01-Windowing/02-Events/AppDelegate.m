//
//  AppDelegate.m
//  Window
//
//  Created by apple on 23/10/24.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "MyView.h"

@implementation AppDelegate
{
@private
    UIWindow *window;
    ViewController *viewController;
    MyView *myView;
}

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Code
    
    CGRect screenRect = [[UIScreen mainScreen]bounds];  // Get The IPhone Screen Rectangle
    window = [[UIWindow alloc]initWithFrame:screenRect];// Create Window
    viewController = [[ViewController alloc]init];      // Create View Controller
    [window setRootViewController:viewController];      // Set Above ViewController As Window's View Controller
    myView = [[MyView alloc]initWithFrame:screenRect];  // Create Our Custom View
    [viewController setView:myView];                    // Set Above View As View Of View Controller
    [myView release];                                   // Decrement The Reference Count Of View Incremented By setView
    [window makeKeyAndVisible];                         // Set Focus On This Window And Make It Visible
    
    return YES;
}

-(void)applicationWillResignActive:(UIApplication *)application
{
    // Code
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
}

-(void)applicationWillTerminate:(UIApplication *)application
{
    // Code
}

-(void)dealloc
{
    // Code
    [super dealloc];
    
    [myView release];
    [viewController release];
    [window release];
}

@end
