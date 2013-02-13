#import "HVAppDelegate.h"

@implementation HVAppDelegate

@synthesize pdfView,window,server;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
        self->server = [[HaskellServer alloc] init];
        if ( [self->server start] ) {
            NSLog(@"Started server on port %zu.", (size_t) [self->server port]);
            [self->server setDelegate:self];
        } else {
            NSLog(@"Error starting server");
        }
    
}

-(void)didFinishLoadingHaskellData:(NSData*)theData
{
    PDFDocument *pdf=[[PDFDocument alloc] initWithData:theData];
    [self->pdfView setDocument:pdf];
}

- (IBAction)saveDocument:(id)sender
{
    NSSavePanel * savePanel = [NSSavePanel savePanel];
    // Restrict the file type to whatever you like
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"pdf"]];
    // Set the starting directory
    // Perform other setup
    // Use a completion handler -- this is a block which takes one argument
    // which corresponds to the button that was clicked
    [savePanel beginSheetModalForWindow:self->window completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            // Close panel before handling errors
            [[self->pdfView document] writeToURL:[savePanel URL]]; 
            //NSLog(@"Got URL: %@", [savePanel URL]);
            // Do what you need to do with the selected path
        }
    }];
}

- (BOOL)validateUserInterfaceItem:(NSMenuItem *)item {
    if ([item action] == @selector(saveDocument:))
    {
        if ([self->pdfView document]!=nil)
            return YES;
        else
            return NO;
    }
    
    return YES;
}

@end
