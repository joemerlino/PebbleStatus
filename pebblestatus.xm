#include "BluetoothManager.framework/BluetoothManager.h"
#import "libstatusbar/LSStatusBarItem.h"
#import "libstatusbar/UIApplication_libstatusbar.h"

@interface NSDistributedNotificationCenter : NSNotificationCenter
@end

@interface BluetoothManager (pebblestatus)
-(BOOL)getHideBluetooth;
-(void)updateForPebbleConnection;
@end

%hook BluetoothManager
static LSStatusBarItem *pebbleItem;

%new -(void)updateForPebbleConnection{
	BOOL pebbleConnected = NO;
	for(id device in [self connectedDevices]){
		if([[device name] rangeOfString:@"Pebble"].location != NSNotFound){
			NSLog(@"[pebblestatus] Detected connection to Pebble with name: %@", [device name]);
			pebbleConnected = YES;
			break;
		}
	}
	
	pebbleItem =  [[%c(LSStatusBarItem) alloc] initWithIdentifier: @"pbstatus.Connected" alignment:StatusBarAlignmentRight];
	pebbleItem.imageName = @"PB_connected";

	if(pebbleConnected){
		NSLog(@"[pebblestatus] Statusbar updated to display Pebble connected!");
		pebbleItem.visible = YES;
	}

	else{
		NSLog(@"[pebblestatus] Statusbar updated to display that NO Pebble is connected.");
		pebbleItem.visible = NO;
	}
}

-(id)init{
	NSLog(@"[pebblestatus] BluetoothManager initialized, checking for Pebble...");
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
		[self updateForPebbleConnection];
	});
	return %orig;
}

-(void)_connectedStatusChanged {
	NSLog(@"[pebblestatus] Detected change of Bluetooth connection status, checking for Pebble...");
	[self updateForPebbleConnection];
	%orig;
}//end statuschanged
%end

%hook UIStatusBarItemView

- (void)setVisible:(BOOL)arg1 frame:(struct CGRect )arg2 duration:(double)arg3{
	if([NSStringFromClass([self class]) containsString:@"UIStatusBarBluetoothItemView"]){
		BOOL pebbleConnected;
		for(id device in [[%c(BluetoothManager) sharedInstance] connectedDevices]){
			if([[device name] rangeOfString:@"Pebble"].location != NSNotFound){
				pebbleConnected = YES;
				break;
			}
		}
		if(pebbleConnected){
			arg2.size.width = 0;
			arg1 = NO;
		}
	}
	%orig;
}
%end