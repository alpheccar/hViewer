

#import <Foundation/Foundation.h>

@interface HaskellConnection : NSObject



- (id)initWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream;

@property (nonatomic, strong, readonly ) NSInputStream *    inputStream;
@property (nonatomic, strong, readonly ) NSOutputStream *   outputStream;
@property (nonatomic, strong) NSMutableData *haskellData;

- (BOOL)open;
- (void)close;
- (NSData*)data;


extern NSString * HaskellConnectionDidCloseNotification;
    // This notification is posted when the connection closes, either because you called 
    // -close or because of on-the-wire events (the client closing the connection, a network 
    // error, and so on).

@end
