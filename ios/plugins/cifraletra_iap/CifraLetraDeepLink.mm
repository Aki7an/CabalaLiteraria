#import "cifraletra_deeplink.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSString *const kDeepLinkInbox = @"cifraletra_deeplink.url";

@interface CifraLetraDeepLink : NSObject
+ (instancetype)shared;
- (void)storeURL:(NSURL *)url;
@end

static void cifraletra_store_argument(NSString *arg) {
	if (arg.length == 0) {
		return;
	}
	if ([arg rangeOfString:@"cifraletra:" options:NSCaseInsensitiveSearch].location == NSNotFound) {
		return;
	}
	NSString *text = arg;
	if ([text hasPrefix:@"--uri="]) {
		text = [text substringFromIndex:6];
	}
	text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	text = [text stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\"'"]];
	NSURL *url = [NSURL URLWithString:text];
	if (url == nil) {
		NSString *encoded = [text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
		url = [NSURL URLWithString:encoded];
	}
	[[CifraLetraDeepLink shared] storeURL:url];
}

static BOOL cifraletra_filtering_arguments = NO;
static IMP cifraletra_original_arguments = NULL;

static NSArray *cifraletra_arguments(id self, SEL cmd) {
	NSArray *(*original)(id, SEL) = (NSArray *(*)(id, SEL))cifraletra_original_arguments;
	NSArray *args = original != NULL ? original(self, cmd) : @[];
	if (cifraletra_filtering_arguments || args.count == 0) {
		return args;
	}
	cifraletra_filtering_arguments = YES;
	NSMutableArray *kept = [NSMutableArray arrayWithCapacity:args.count];
	for (id item in args) {
		if (![item isKindOfClass:[NSString class]]) {
			[kept addObject:item];
			continue;
		}
		NSString *arg = (NSString *)item;
		if ([arg rangeOfString:@"cifraletra:" options:NSCaseInsensitiveSearch].location != NSNotFound) {
			cifraletra_store_argument(arg);
			continue;
		}
		[kept addObject:arg];
	}
	cifraletra_filtering_arguments = NO;
	return kept;
}

@implementation CifraLetraDeepLink

+ (void)load {
	Method method = class_getInstanceMethod([NSProcessInfo class], @selector(arguments));
	if (method == NULL || cifraletra_original_arguments != NULL) {
		return;
	}
	cifraletra_original_arguments = method_getImplementation(method);
	method_setImplementation(method, (IMP)cifraletra_arguments);
}

+ (instancetype)shared {
	static CifraLetraDeepLink *instance;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		instance = [[CifraLetraDeepLink alloc] init];
	});
	return instance;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	(void)application;
	id url = launchOptions[UIApplicationLaunchOptionsURLKey];
	if ([url isKindOfClass:[NSURL class]]) {
		[self storeURL:(NSURL *)url];
	}
	return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary *)options {
	(void)application;
	(void)options;
	[self storeURL:url];
	return YES;
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions API_AVAILABLE(ios(13.0)) {
	(void)scene;
	(void)session;
	for (UIOpenURLContext *context in connectionOptions.URLContexts) {
		[self storeURL:context.URL];
	}
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts API_AVAILABLE(ios(13.0)) {
	(void)scene;
	for (UIOpenURLContext *context in URLContexts) {
		[self storeURL:context.URL];
	}
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

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity API_AVAILABLE(ios(13.0)) {
	(void)scene;
	if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
		[self storeURL:userActivity.webpageURL];
	}
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
