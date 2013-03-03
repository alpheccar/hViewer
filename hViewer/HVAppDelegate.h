#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "HaskellServer.h"
#import <AVFoundation/AVFoundation.h>



@interface HVAppDelegate : NSObject <NSApplicationDelegate,HaskellDataDelegate,NSUserInterfaceValidations,AVAudioPlayerDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet PDFView *pdfView;
@property (retain) HaskellServer *server;
@property (retain) AVAudioPlayer *audioPlayer;

-(void)playData:(NSData*)theData;
-(void)displayData:(NSData*)theData;

@end
