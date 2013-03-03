
#import "HaskellConnection.h"
#import "HVAppDelegate.h"

NSString * HaskellConnectionDidCloseNotification = @"HaskellConnectionDidCloseNotification";

@interface HaskellConnection () <NSStreamDelegate>
@end

@implementation HaskellConnection

@synthesize inputStream  = _inputStream;
@synthesize outputStream = _outputStream;
@synthesize haskellData;

uint8_t *code;
short codeToRead;


- (id)initWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
{
    self = [super init];
    if (self != nil) {
        self->_inputStream = inputStream;
        self->_outputStream = outputStream;
        self->haskellData=[NSMutableData dataWithCapacity:1000];
        code=malloc(sizeof(uint8_t)*5);
    }
    return self;
}

- (void)dealloc {
    free(code);
}

-(BOOL)isDisp
{
    code[4]='\0';
    return (strcmp(code,"disp")==0);
}

-(BOOL)isPlay
{
    code[4]='\0';
    return (strcmp(code,"play")==0);
}


- (NSData*)data
{
    return (self->haskellData);
}


- (BOOL)open {
    [self.inputStream  setDelegate:self];
    [self.outputStream setDelegate:self];
    [self.inputStream  scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream  open];
    [self.outputStream open];
    codeToRead=4;
    return YES;
}

- (void)close {
    [self.inputStream  setDelegate:nil];
    [self.outputStream setDelegate:nil];
    [self.inputStream  close];
    [self.outputStream close];
    [self.inputStream  removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [(NSNotificationCenter *)[NSNotificationCenter defaultCenter] postNotificationName:HaskellConnectionDidCloseNotification object:self];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)streamEvent {
    assert(aStream == self.inputStream || aStream == self.outputStream);
    #pragma unused(aStream)
    
    switch(streamEvent) {
        case NSStreamEventHasBytesAvailable: {
            uint8_t buffer[2048];
            NSInteger actuallyRead = [self.inputStream read:(uint8_t *)buffer maxLength:sizeof(buffer)];
            if (actuallyRead > 0)
            {
                if (codeToRead > 0)
                {
                    short i=0;
                    short start=codeToRead;
                    while ((actuallyRead > 0) && (codeToRead > 0))
                    {
                        code[i+(4 - start)] = buffer[i];
                        actuallyRead--;
                        codeToRead--;
                        i++;
                    }
                    [self->haskellData appendBytes:(buffer+i) length:actuallyRead];
                }
                else
                {
                   [self->haskellData appendBytes:buffer length:actuallyRead];
                }
            } else {
                // A non-positive value from -read:maxLength: indicates either end of file (0) or 
                // an error (-1).  In either case we just wait for the corresponding stream event 
                // to come through.
            }
        } break;
        case NSStreamEventEndEncountered:
        case NSStreamEventErrorOccurred: {
            [self close];
        } break;
        case NSStreamEventHasSpaceAvailable:
        case NSStreamEventOpenCompleted:
        default: {
            // do nothing
        } break;
    }
}

@end
