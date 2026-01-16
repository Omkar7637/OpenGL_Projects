//
//  MyView.m
//  Window
//
//  Created by apple on 23/10/24.
//

#import "MyView.h"

@implementation MyView
{
    NSString *string;
}

-(id)initWithFrame:(CGRect)frame
{
    // Code
    self = [super initWithFrame:frame];
    if (self)
    {
        // Set The Background To Black
        [self setBackgroundColor:[UIColor blackColor]];
        
        // Set The String
        string = @"Hello World !!!";
        
        // ++++++++++++++++++++++++++ Single Tap +++++++++++++++++++++++++++++++++
        
        UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onSingleTap:)];                        // 1: Create Object Of Single Tap Gesture Recognizer
        [singleTapGestureRecognizer setNumberOfTapsRequired:1];     // 2: Set Number Of Taps Required
        [singleTapGestureRecognizer setNumberOfTouchesRequired:1];  // 3: Set Number Of Fingers Required
        [singleTapGestureRecognizer setDelegate:self];              // 4: Set The Delegate As Self
        [self addGestureRecognizer:singleTapGestureRecognizer];     // 5: Add Abov Configured Gesture Recognizer In Self
        
        // ++++++++++++++++++++++++++ Double Tap +++++++++++++++++++++++++++++++++
        UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onDoubleTap:)];                        // 1: Create Object Of Single Tap Gesture Recognizer
        [doubleTapGestureRecognizer setNumberOfTapsRequired:2];     // 2: Set Number Of Taps Required
        [doubleTapGestureRecognizer setNumberOfTouchesRequired:1];  // 3: Set Number Of Fingers Required
        [doubleTapGestureRecognizer setDelegate:self];              // 4: Set The Delegate As Self
        [self addGestureRecognizer:doubleTapGestureRecognizer];     // 5: Add Abov Configured Gesture Recognizer In Self
        
        // Double Tap Should Fail For Two Single Taps
        [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
        
        // +++++++++++++++++++++++++++ Swipe +++++++++++++++++++++++++++++++++++++
        UISwipeGestureRecognizer *swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(onSwipe:)];
        [swipeGestureRecognizer setDelegate:self];
        [self addGestureRecognizer:swipeGestureRecognizer];
        
        // ++++++++++++++++++++++++++ Long Press +++++++++++++++++++++++++++++++++
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(onLongPress:)];
        [longPressGestureRecognizer setDelegate:self];
        [self addGestureRecognizer:longPressGestureRecognizer];
    }
    return self;
}

-(void)drawRect:(CGRect)rect
{
    // Code
    // Declare The Background Color Black
    UIColor *bgColor = [UIColor blackColor];
    
    // Set This Color
    [bgColor set];
    
    // Fill The Window Rectangle/Dirty Rectangle With Above Black Color
    UIRectFill(rect);
    
    // Create The Font For Our Screen
    UIFont *stringFont = [UIFont fontWithName: @"Helvetica" size:32];
    
    // Create String Color
    UIColor *fgColor = [UIColor greenColor];
    
    // Create Dictionary For Our Stirng Attributes Using Above Two
    NSDictionary *stringDictionary = [NSDictionary dictionaryWithObjectsAndKeys: stringFont, NSFontAttributeName, fgColor, NSForegroundColorAttributeName, nil];
    
    // Create The Size Of The String According To Size Of Font And Other Attributes
    CGSize stringSize = [string sizeWithAttributes: stringDictionary];
    
    // Create Point For Drawing Of String
    CGPoint stringPoint;
    stringPoint.x = (rect.size.width/2 - stringSize.width/2);
    stringPoint.y = (rect.size.height/2 - stringSize.height/2);
    
    // Finally, Draw The Stirng Hello World !!!
    [string drawAtPoint: stringPoint withAttributes: stringDictionary];
}

-(BOOL)becomeFirstResponder
{
    // Code
    return YES;
}

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    // Code
}

-(void)onSingleTap:(UITapGestureRecognizer*)gestureRecognizer
{
    // Code
}

-(void)onDoubleTap:(UITapGestureRecognizer*)gestureRecognizer
{
    // Code
}

-(void)onSwipe:(UISwipeGestureRecognizer*)gestureRecognizer
{
    // Code
}

-(void)onLongPress:(UILongPressGestureRecognizer*)gestureRecognizer
{
    // Code
}

-(void)dealloc
{
    // Code
    [super dealloc];
}

@end
