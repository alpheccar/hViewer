
#import <Foundation/Foundation.h>


#define PORT 9000

@protocol HaskellDataDelegate <NSObject>
@optional
- (void)displayData:(NSData*)theData;
- (void)playData:(NSData*)theData;
@end

@interface HaskellServer : NSObject

@property (nonatomic, assign, readonly ) NSUInteger     port;   // the actual port bound to, valid after -start

@property (nonatomic, weak) id<HaskellDataDelegate> delegate;

- (BOOL)start;
- (void)stop;

-(void)setDelegate:(id<HaskellDataDelegate>)theDelegate;

@end
