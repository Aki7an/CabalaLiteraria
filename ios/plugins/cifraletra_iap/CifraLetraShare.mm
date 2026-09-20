#import "cifraletra_share.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSString *const kShareInbox = @"cifraletra_share_inbox.json";

@interface CifraLetraShare : NSObject
@property(nonatomic, assign) BOOL started;
- (void)start;
@end

@implementation CifraLetraShare

+ (instancetype)shared {
	static CifraLetraShare *instance;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		instance = [[CifraLetraShare alloc] init];
	});
	return instance;
}

- (void)start {
	if (self.started) {
		return;
	}
	self.started = YES;
	NSLog(@"[CifraLetraShare] started");
	[self poll];
}

- (NSArray<NSString *> *)candidateDirs {
	NSMutableArray<NSString *> *dirs = [NSMutableArray array];
	NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
	NSString *support = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
	if (docs.length > 0) {
		[dirs addObject:docs];
	}
	if (support.length > 0) {
		[dirs addObject:support];
	}
	return dirs;
}

- (void)poll {
	[self consumeInbox];
	__weak CifraLetraShare *weakSelf = self;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[weakSelf poll];
	});
}

- (void)consumeInbox {
	NSFileManager *fm = [NSFileManager defaultManager];
	for (NSString *dir in [self candidateDirs]) {
		NSString *path = [dir stringByAppendingPathComponent:kShareInbox];
		if (![fm fileExistsAtPath:path]) {
			continue;
		}
		NSData *data = [NSData dataWithContentsOfFile:path];
		[fm removeItemAtPath:path error:nil];
		if (data.length == 0) {
			continue;
		}
		id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
		if (![json isKindOfClass:[NSDictionary class]]) {
			continue;
		}
		NSDictionary *command = json;
		NSString *imagePath = [NSString stringWithFormat:@"%@", command[@"image"] ?: @""];
		NSString *text = [NSString stringWithFormat:@"%@", command[@"text"] ?: @""];
		NSString *target = [NSString stringWithFormat:@"%@", command[@"target"] ?: @""];
		NSLog(@"[CifraLetraShare] present image=%@ text_len=%lu target=%@", imagePath, (unsigned long)text.length, target);
		NSString *url = [NSString stringWithFormat:@"%@", command[@"url"] ?: @""];
		[self presentToTarget:target imagePath:imagePath text:text url:url];
		return;
	}
}

- (UIViewController *)topController {
	UIWindow *window = [self keyWindow];
	UIViewController *root = window.rootViewController;
	while (root.presentedViewController) {
		root = root.presentedViewController;
	}
	return root;
}

- (UIWindow *)keyWindow {
	UIWindow *fallback = nil;
	for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
		if (![scene isKindOfClass:[UIWindowScene class]]) {
			continue;
		}
		UIWindowScene *windowScene = (UIWindowScene *)scene;
		for (UIWindow *candidate in windowScene.windows) {
			if (candidate.isKeyWindow) {
				return candidate;
			}
			if (fallback == nil) {
				fallback = candidate;
			}
		}
		if (windowScene.activationState == UISceneActivationStateForegroundActive && windowScene.windows.firstObject) {
			fallback = windowScene.windows.firstObject;
		}
	}
	return fallback;
}

- (NSURL *)preparedImageURL:(NSString *)imagePath {
	if (imagePath.length == 0) {
		return nil;
	}
	NSFileManager *fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:imagePath]) {
		return nil;
	}
	NSString *tmp = [NSTemporaryDirectory() stringByAppendingPathComponent:@"cifraletra_share.png"];
	[fm removeItemAtPath:tmp error:nil];
	if ([fm copyItemAtPath:imagePath toPath:tmp error:nil]) {
		return [NSURL fileURLWithPath:tmp];
	}
	return [NSURL fileURLWithPath:imagePath];
}

- (void)presentImage:(NSString *)imagePath text:(NSString *)text {
	NSMutableArray *items = [NSMutableArray array];
	UIImage *image = imagePath.length > 0 ? [UIImage imageWithContentsOfFile:imagePath] : nil;
	if (image == nil) {
		NSURL *fileURL = [self preparedImageURL:imagePath];
		if (fileURL) {
			image = [UIImage imageWithContentsOfFile:fileURL.path];
			if (image == nil) {
				[items addObject:fileURL];
			}
		}
	}
	if (image) {
		[items addObject:image];
	}
	if (text.length > 0) {
		[items addObject:text];
	}
	if (items.count == 0) {
		return;
	}
	NSLog(@"[CifraLetraShare] activity items=%lu card=%d", (unsigned long)items.count, image != nil);
	UIActivityViewController *sheet = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
	sheet.excludedActivityTypes = @[
		UIActivityTypePrint,
		UIActivityTypeAssignToContact,
		UIActivityTypeAddToReadingList,
		UIActivityTypeMarkupAsPDF
	];
	UIViewController *host = [self topController];
	if (host == nil) {
		NSLog(@"[CifraLetraShare] no view controller");
		return;
	}
	if (sheet.popoverPresentationController) {
		sheet.popoverPresentationController.sourceView = host.view;
		sheet.popoverPresentationController.sourceRect = CGRectMake(host.view.bounds.size.width * 0.5, host.view.bounds.size.height * 0.5, 1, 1);
	}
	[host presentViewController:sheet animated:YES completion:nil];
}

- (NSString *)percentEncode:(NSString *)text {
	NSMutableCharacterSet *allowed = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
	[allowed removeCharactersInString:@"&=?+/"];
	return [text stringByAddingPercentEncodingWithAllowedCharacters:allowed] ?: @"";
}

- (void)openURLString:(NSString *)raw completion:(void (^)(BOOL ok))completion {
	NSURL *url = [NSURL URLWithString:raw];
	if (url == nil) {
		if (completion) {
			completion(NO);
		}
		return;
	}
	NSString *scheme = url.scheme.lowercaseString;
	BOOL custom = scheme.length > 0 && ![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"];
	if (custom && ![UIApplication.sharedApplication canOpenURL:url]) {
		if (completion) {
			completion(NO);
		}
		return;
	}
	[UIApplication.sharedApplication openURL:url options:@{} completionHandler:completion];
}

- (UIImage *)loadImage:(NSString *)imagePath {
	if (imagePath.length == 0) {
		return nil;
	}
	UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
	if (image) {
		return image;
	}
	NSURL *fileURL = [self preparedImageURL:imagePath];
	if (fileURL) {
		return [UIImage imageWithContentsOfFile:fileURL.path];
	}
	return nil;
}

- (void)copyCardToPasteboard:(UIImage *)image text:(NSString *)text {
	NSMutableArray *items = [NSMutableArray array];
	if (image) {
		NSMutableDictionary *card = [NSMutableDictionary dictionary];
		NSData *png = UIImagePNGRepresentation(image);
		if (png.length > 0) {
			card[@"public.png"] = png;
		}
		card[@"public.image"] = image;
		[items addObject:card];
	}
	if (text.length > 0) {
		[items addObject:@{
			@"public.utf8-plain-text": text,
			@"public.plain-text": text,
		}];
	}
	if (items.count == 0) {
		return;
	}
	UIPasteboard.generalPasteboard.items = items;
}

- (void)presentToTarget:(NSString *)target imagePath:(NSString *)imagePath text:(NSString *)text url:(NSString *)url {
	UIImage *image = [self loadImage:imagePath];
	if ([target isEqualToString:@"x"]) {
		[self presentToX:image text:text];
		return;
	}
	if ([target isEqualToString:@"instagram"]) {
		[self presentToInstagram:image text:text url:url imagePath:imagePath];
		return;
	}
	if ([target isEqualToString:@"facebook"]) {
		[self presentToFacebook:image text:text url:url];
		return;
	}
	if ([target isEqualToString:@"tiktok"]) {
		[self presentToTikTok:image text:text];
		return;
	}
	[self presentImage:imagePath text:text];
}

- (void)presentToX:(UIImage *)image text:(NSString *)text {
	[self copyCardToPasteboard:image text:text];
	NSLog(@"[CifraLetraShare] opening X compose card=%d", image != nil);
	NSString *appURL = @"twitter://post?message=";
	NSString *webURL = @"https://x.com/compose/post";
	__weak CifraLetraShare *weakSelf = self;
	[self openURLString:appURL completion:^(BOOL ok) {
		if (ok) {
			return;
		}
		[weakSelf openURLString:webURL completion:nil];
	}];
}

- (void)presentToInstagram:(UIImage *)image text:(NSString *)text url:(NSString *)url imagePath:(NSString *)imagePath {
	NSData *png = image ? UIImagePNGRepresentation(image) : nil;
	if (png.length > 0) {
		NSMutableDictionary *sticker = [NSMutableDictionary dictionary];
		sticker[@"com.instagram.sharedSticker.backgroundImage"] = png;
		if (url.length > 0) {
			sticker[@"com.instagram.sharedSticker.contentURL"] = url;
		}
		NSDate *expires = [[NSDate date] dateByAddingTimeInterval:60.0 * 5.0];
		[UIPasteboard.generalPasteboard setItems:@[ sticker ]
			options:@{ UIPasteboardOptionExpirationDate: expires }];
		NSString *bundle = [[NSBundle mainBundle] bundleIdentifier] ?: @"com.aki7an.cifraletra";
		NSString *stories = [NSString stringWithFormat:@"instagram-stories://share?source_application=%@", [self percentEncode:bundle]];
		__weak CifraLetraShare *weakSelf = self;
		NSLog(@"[CifraLetraShare] opening Instagram Stories with card");
		[self openURLString:stories completion:^(BOOL ok) {
			if (ok) {
				return;
			}
			[weakSelf copyCardToPasteboard:image text:text];
			[weakSelf openURLString:@"instagram://app" completion:^(BOOL instaOk) {
				if (!instaOk) {
					[weakSelf presentImage:imagePath text:text];
				}
			}];
		}];
		return;
	}
	[self copyCardToPasteboard:image text:text];
	__weak CifraLetraShare *weakSelf = self;
	[self openURLString:@"instagram://app" completion:^(BOOL ok) {
		if (!ok) {
			[weakSelf presentImage:imagePath text:text];
		}
	}];
}

- (void)presentToFacebook:(UIImage *)image text:(NSString *)text url:(NSString *)url {
	[self copyCardToPasteboard:image text:text];
	NSString *shareURL = url.length > 0 ? url : text;
	NSString *web = [NSString stringWithFormat:@"https://www.facebook.com/sharer/sharer.php?u=%@", [self percentEncode:shareURL]];
	NSLog(@"[CifraLetraShare] opening Facebook card=%d", image != nil);
	__weak CifraLetraShare *weakSelf = self;
	[self openURLString:@"fb://" completion:^(BOOL ok) {
		if (ok) {
			return;
		}
		[weakSelf openURLString:web completion:nil];
	}];
}

- (void)presentToTikTok:(UIImage *)image text:(NSString *)text {
	[self copyCardToPasteboard:image text:text];
	NSLog(@"[CifraLetraShare] opening TikTok card=%d", image != nil);
	__weak CifraLetraShare *weakSelf = self;
	[self openURLString:@"tiktok://" completion:^(BOOL ok) {
		if (ok) {
			return;
		}
		[weakSelf openURLString:@"snssdk1233://" completion:nil];
	}];
}

@end

__attribute__((constructor))
static void cifraletra_share_ctor(void) {
	cifraletra_share_start();
}

__attribute__((visibility("default")))
void cifraletra_share_start(void) {
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			[[CifraLetraShare shared] start];
		});
	});
}
