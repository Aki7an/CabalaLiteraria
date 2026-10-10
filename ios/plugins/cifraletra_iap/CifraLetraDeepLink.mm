#import "cifraletra_deeplink.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSString *const kDeepLinkInbox = @"cifraletra_deeplink.url";

@interface CifraLetraDeepLink : NSObject
+ (instancetype)shared;
- (void)storeURL:(NSURL *)url;
@end

@implementation CifraLetraDeepLink

+ (instancetype)shared {
	static CifraLetraDeepLink *instance;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		instance = [[CifraLetraDeepLink alloc] init];
	});
	return instance;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary *)options {
	(void)application;
	(void)options;
	[self storeURL:url];
	return YES;
}

- (BOOL)application:(UIApplication *)application
	continueUserActivity:(NSUserActivity *)userActivity
	  restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
	(void)application;
	(void)restorationHandler;
	if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
		[self storeURL:userActivity.webpageURL];
		return YES;
	}
	return NO;
}

- (void)storeURL:(NSURL *)url {
	if (url == nil) {
		return;
	}
	NSString *text = url.absoluteString;
	if (text.length == 0) {
		return;
	}
	NSLog(@"[CifraLetraDeepLink] %@", text);
	NSArray<NSString *> *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docs = dirs.firstObject;
	if (docs.length == 0) {
		return;
	}
	NSString *path = [docs stringByAppendingPathComponent:kDeepLinkInbox];
	[text writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@end

static BOOL cifraletra_deeplink_register(void) {
	Class cls = NSClassFromString(@"GDTApplicationDelegate");
	SEL sel = NSSelectorFromString(@"addService:");
	if (cls == Nil || ![cls respondsToSelector:sel]) {
		return NO;
	}
	IMP imp = [cls methodForSelector:sel];
	void (*func)(id, SEL, id) = (void (*)(id, SEL, id))imp;
	func(cls, sel, [CifraLetraDeepLink shared]);
	return YES;
}

static void cifraletra_deeplink_try_register(int attempt) {
	static BOOL registered = NO;
	if (registered) {
		return;
	}
	if (cifraletra_deeplink_register()) {
		registered = YES;
		NSLog(@"[CifraLetraDeepLink] registered");
		return;
	}
	if (attempt >= 30) {
		NSLog(@"[CifraLetraDeepLink] GDTApplicationDelegate not found");
		return;
	}
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		cifraletra_deeplink_try_register(attempt + 1);
	});
}

__attribute__((constructor))
static void cifraletra_deeplink_ctor(void) {
	cifraletra_deeplink_start();
}

__attribute__((visibility("default")))
void cifraletra_deeplink_start(void) {
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		if (!cifraletra_deeplink_register()) {
			dispatch_async(dispatch_get_main_queue(), ^{
				cifraletra_deeplink_try_register(0);
			});
		} else {
			NSLog(@"[CifraLetraDeepLink] registered");
		}
	});
}
