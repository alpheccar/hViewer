

#import "HaskellServer.h"
#import "HaskellConnection.h"
#import "HVAppDelegate.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

@interface HaskellServer () <NSStreamDelegate>

// read/write versions of public properties

@property (nonatomic, assign, readwrite) NSUInteger         port;

// private properties

@property (nonatomic, strong, readwrite) NSNetService *     netService;
@property (nonatomic, strong, readonly ) NSMutableSet *     connections;    // of EchoConnection

@end

@implementation HaskellServer {
    CFSocketRef             _ipv4socket;
}

@synthesize port = _port;

@synthesize netService = _netService;
@synthesize connections = _connections;
@synthesize delegate;

- (id)init
{
    self = [super init];
    if (self != nil) {
        _connections = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self stop];
}

-(void)setDelegate:(id<HaskellDataDelegate>)theDelegate
{
    self->delegate=theDelegate;
}

- (void)echoConnectionDidCloseNotification:(NSNotification *)note
{
    HaskellConnection *connection = [note object];
    assert([connection isKindOfClass:[HaskellConnection class]]);
    id d=self->delegate;
    if ([connection isDisp] && [d respondsToSelector:@selector(displayData:)])
    {
        [d displayData:[connection data]];
    }
    
    if ([connection isPlay] && [d respondsToSelector:@selector(playData:)])
    {
        [d playData:[connection data]];
    }

    [(NSNotificationCenter *)[NSNotificationCenter defaultCenter] removeObserver:self name:HaskellConnectionDidCloseNotification object:connection];
    [self.connections removeObject:connection];
        NSLog(@"Connection closed.");
}

- (void)acceptConnection:(CFSocketNativeHandle)nativeSocketHandle
{
    CFReadStreamRef readStream = NULL;
    CFWriteStreamRef writeStream = NULL;
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &readStream, &writeStream);
    if (readStream && writeStream) {
        CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);

        HaskellConnection * connection = [[HaskellConnection alloc] initWithInputStream:(__bridge NSInputStream *)readStream outputStream:(__bridge NSOutputStream *)writeStream];
        [self.connections addObject:connection];
        [connection open];
        [(NSNotificationCenter *)[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(echoConnectionDidCloseNotification:) name:HaskellConnectionDidCloseNotification object:connection];
        NSLog(@"Added connection.");
    } else {
        // On any failure, we need to destroy the CFSocketNativeHandle 
        // since we are not going to use it any more.
        (void) close(nativeSocketHandle);
    }
    if (readStream) CFRelease(readStream);
    if (writeStream) CFRelease(writeStream);
}

// This function is called by CFSocket when a new connection comes in.
// We gather the data we need, and then convert the function call to a method
// invocation on EchoServer.
static void EchoServerAcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    assert(type == kCFSocketAcceptCallBack);
    #pragma unused(type)
    #pragma unused(address)
    
    HaskellServer *server = (__bridge HaskellServer *)info;
    assert(socket == server->_ipv4socket);
    #pragma unused(socket)
    
    // For an accept callback, the data parameter is a pointer to a CFSocketNativeHandle.
    [server acceptConnection:*(CFSocketNativeHandle *)data];
}

- (BOOL)start {
    assert(_ipv4socket == NULL);       // don't call -start twice!

    CFSocketContext socketCtxt = {0, (__bridge void *) self, NULL, NULL, NULL};
    _ipv4socket = CFSocketCreate(kCFAllocatorDefault, PF_INET,  SOCK_STREAM, 0, kCFSocketAcceptCallBack, &EchoServerAcceptCallBack, &socketCtxt);

    if (NULL == _ipv4socket) {
        [self stop];
        return NO;
    }

    static const int yes = 1;
    (void) setsockopt(CFSocketGetNative(_ipv4socket), SOL_SOCKET, SO_REUSEADDR, (const void *) &yes, sizeof(yes));

    // Set up the IPv4 listening socket; port is 0, which will cause the kernel to choose a port for us.
    struct sockaddr_in addr4;
    memset(&addr4, 0, sizeof(addr4));
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_port = htons(PORT);
    addr4.sin_addr.s_addr = htonl(INADDR_ANY);
    if (kCFSocketSuccess != CFSocketSetAddress(_ipv4socket, (__bridge CFDataRef) [NSData dataWithBytes:&addr4 length:sizeof(addr4)])) {
        [self stop];
        return NO;
    }
    
    // Now that the IPv4 binding was successful, we get the port number 
    // -- we will need it for the IPv6 listening socket and for the NSNetService.
    NSData *addr = (__bridge_transfer NSData *)CFSocketCopyAddress(_ipv4socket);
    //assert([addr length] == sizeof(struct sockaddr_in));
    self.port = ntohs(((const struct sockaddr_in *)[addr bytes])->sin_port);


    // Set up the run loop sources for the sockets.
    CFRunLoopSourceRef source4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv4socket, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source4, kCFRunLoopCommonModes);
    CFRelease(source4);

    return YES;
}

- (void)stop {
   
    for (HaskellConnection * connection in [self.connections copy]) {
        [connection close];
    }
    if (_ipv4socket != NULL) {
        CFSocketInvalidate(_ipv4socket);
        CFRelease(_ipv4socket);
        _ipv4socket = NULL;
    }
}

@end
