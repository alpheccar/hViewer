#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "HaskellServer.h"



@interface HVAppDelegate : NSObject <NSApplicationDelegate,HaskellDataDelegate,NSUserInterfaceValidations>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet PDFView *pdfView;
@property (retain) HaskellServer *server;

-(void)didFinishLoadingHaskellData:(NSData*)theData;

@end
