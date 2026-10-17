#import "cifraletra_iap.h"

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

static NSString *const kInboxName = @"cifraletra_iap_inbox.json";
static NSString *const kOutboxName = @"cifraletra_iap_outbox.jsonl";
static NSString *const kMarkerName = @"cifraletra_iap.dir";
static NSString *const kReadyName = @"cifraletra_iap_ready";

@interface CifraLetraIAP : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property(nonatomic, strong) NSMutableDictionary<NSString *, SKProduct *> *products;
@property(nonatomic, strong) NSMutableArray<SKProductsRequest *> *requests;
@property(nonatomic, strong) NSMutableArray<NSString *> *bridgeDirs;
@property(nonatomic, copy) NSString *pendingPurchaseId;
@property(nonatomic, assign) BOOL started;
- (void)handleCommand:(NSDictionary *)command;
- (void)queryProduct:(NSString *)productId;
- (void)buyProduct:(NSString *)productId;
- (void)restorePurchases;
@end

@implementation CifraLetraIAP

+ (instancetype)shared {
	static CifraLetraIAP *instance;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		instance = [[CifraLetraIAP alloc] init];
	});
	return instance;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_products = [NSMutableDictionary dictionary];
		_requests = [NSMutableArray array];
		_bridgeDirs = [NSMutableArray array];
	}
	return self;
}

- (NSArray<NSString *> *)rootDirs {
	NSMutableArray<NSString *> *roots = [NSMutableArray array];
	NSArray<NSString *> *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSArray<NSString *> *support = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSArray<NSString *> *caches = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	if (docs.firstObject.length > 0) {
		[roots addObject:docs.firstObject];
	}
	if (support.firstObject.length > 0) {
		[roots addObject:support.firstObject];
	}
	if (caches.firstObject.length > 0) {
		[roots addObject:caches.firstObject];
	}
	return roots;
}

- (void)rememberDir:(NSString *)dir {
	if (dir.length == 0 || [self.bridgeDirs containsObject:dir]) {
		return;
	}
	[self.bridgeDirs addObject:dir];
}

- (void)scanForBridgeDirsFrom:(NSString *)root depth:(int)depth {
	if (root.length == 0 || depth < 0) {
		return;
	}
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:[root stringByAppendingPathComponent:kMarkerName]] ||
		[fm fileExistsAtPath:[root stringByAppendingPathComponent:kInboxName]] ||
		[fm fileExistsAtPath:[root stringByAppendingPathComponent:kOutboxName]]) {
		[self rememberDir:root];
	}
	if (depth == 0) {
		return;
	}
	NSArray<NSString *> *children = [fm contentsOfDirectoryAtPath:root error:nil];
	for (NSString *child in children) {
		if ([child hasPrefix:@"."]) {
			continue;
		}
		NSString *path = [root stringByAppendingPathComponent:child];
		BOOL isDir = NO;
		if ([fm fileExistsAtPath:path isDirectory:&isDir] && isDir) {
			[self scanForBridgeDirsFrom:path depth:depth - 1];
		}
	}
}

- (NSArray<NSString *> *)activeDirs {
	for (NSString *root in [self rootDirs]) {
		[self rememberDir:root];
		[self scanForBridgeDirsFrom:root depth:3];
	}
	return [self.bridgeDirs copy];
}

- (void)start {
	if (self.started) {
		return;
	}
	self.started = YES;
	NSLog(@"[CifraLetraIAP] StoreKit observer started");
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
	[self writeReadyMarker];
	[self poll];
}

- (void)writeReadyMarker {
	NSFileManager *fm = [NSFileManager defaultManager];
	for (NSString *dir in [self activeDirs]) {
		NSString *path = [dir stringByAppendingPathComponent:kReadyName];
		[fm createFileAtPath:path contents:[@"ok" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
	}
}

- (void)emit:(NSDictionary *)payload {
	if (![NSJSONSerialization isValidJSONObject:payload]) {
		return;
	}
	NSError *error = nil;
	NSData *data = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&error];
	if (data == nil || error != nil) {
		return;
	}
	NSString *line = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (line.length == 0) {
		return;
	}
	line = [line stringByAppendingString:@"\n"];
	NSData *lineData = [line dataUsingEncoding:NSUTF8StringEncoding];
	NSFileManager *fm = [NSFileManager defaultManager];
	for (NSString *dir in [self activeDirs]) {
		NSString *path = [dir stringByAppendingPathComponent:kOutboxName];
		if (![fm fileExistsAtPath:path]) {
			[fm createFileAtPath:path contents:nil attributes:nil];
		}
		NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
		if (handle == nil) {
			[line writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
			continue;
		}
		@try {
			[handle seekToEndOfFile];
			[handle writeData:lineData];
		} @finally {
			[handle closeFile];
		}
	}
}

- (void)poll {
	[self consumeInbox];
	__weak CifraLetraIAP *weakSelf = self;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[weakSelf poll];
	});
}

- (void)consumeInbox {
	NSFileManager *fm = [NSFileManager defaultManager];
	for (NSString *dir in [self activeDirs]) {
		NSString *path = [dir stringByAppendingPathComponent:kInboxName];
		if (![fm fileExistsAtPath:path]) {
			continue;
		}
		NSData *data = [NSData dataWithContentsOfFile:path];
		[fm removeItemAtPath:path error:nil];
		if (data.length == 0) {
			continue;
		}
		id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
		if ([json isKindOfClass:[NSArray class]]) {
			for (id item in (NSArray *)json) {
				if ([item isKindOfClass:[NSDictionary class]]) {
					[self handleCommand:item];
				}
			}
		} else if ([json isKindOfClass:[NSDictionary class]]) {
			[self handleCommand:json];
		}
	}
}

- (void)handleCommand:(NSDictionary *)command {
	NSString *action = [NSString stringWithFormat:@"%@", command[@"action"] ?: @""];
	NSString *productId = [NSString stringWithFormat:@"%@", command[@"product_id"] ?: @""];
	NSLog(@"[CifraLetraIAP] command action=%@ product=%@", action, productId);
	if ([action isEqualToString:@"query"]) {
		[self queryProduct:productId];
	} else if ([action isEqualToString:@"purchase"]) {
		[self buyProduct:productId];
	} else if ([action isEqualToString:@"restore"]) {
		[self restorePurchases];
	}
}

- (void)queryProduct:(NSString *)productId {
	if (productId.length == 0) {
		[self emit:@{ @"type": @"product_info", @"result": @"error", @"error": @"missing_product_id" }];
		return;
	}
	SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:productId]];
	request.delegate = self;
	[self.requests addObject:request];
	[request start];
}

- (void)buyProduct:(NSString *)productId {
	if (productId.length == 0) {
		[self emit:@{ @"type": @"purchase", @"result": @"error", @"error": @"missing_product_id" }];
		return;
	}
	if (![SKPaymentQueue canMakePayments]) {
		NSLog(@"[CifraLetraIAP] payments disabled");
		[self emit:@{ @"type": @"purchase", @"result": @"error", @"error": @"payments_disabled" }];
		return;
	}
	SKProduct *product = self.products[productId];
	if (product == nil) {
		NSLog(@"[CifraLetraIAP] product not cached, querying %@", productId);
		self.pendingPurchaseId = productId;
		[self queryProduct:productId];
		return;
	}
	SKPayment *payment = [SKPayment paymentWithProduct:product];
	NSLog(@"[CifraLetraIAP] addPayment %@", productId);
	[self emit:@{
		@"type": @"purchase",
		@"result": @"progress",
		@"product_id": productId
	}];
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)restorePurchases {
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (NSString *)localizedPriceForProduct:(SKProduct *)product {
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	formatter.formatterBehavior = NSNumberFormatterBehavior10_4;
	formatter.numberStyle = NSNumberFormatterCurrencyStyle;
	formatter.locale = product.priceLocale;
	NSString *text = [formatter stringFromNumber:product.price];
	return text ?: @"";
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
	[self.requests removeObject:request];
	NSMutableArray *ids = [NSMutableArray array];
	NSMutableArray *titles = [NSMutableArray array];
	NSMutableArray *prices = [NSMutableArray array];
	NSMutableArray *localized = [NSMutableArray array];
	NSMutableArray *codes = [NSMutableArray array];
	NSString *firstPrice = @"";
	NSString *firstId = @"";
	for (SKProduct *product in response.products) {
		self.products[product.productIdentifier] = product;
		[ids addObject:product.productIdentifier ?: @""];
		[titles addObject:product.localizedTitle ?: @""];
		[prices addObject:product.price ?: @0];
		NSString *localizedPrice = [self localizedPriceForProduct:product];
		[localized addObject:localizedPrice];
		NSString *code = [[product.priceLocale objectForKey:NSLocaleCurrencyCode] description] ?: @"";
		[codes addObject:code];
		if (firstPrice.length == 0) {
			firstPrice = localizedPrice;
			firstId = product.productIdentifier ?: @"";
		}
	}
	NSLog(@"[CifraLetraIAP] products loaded count=%lu invalid=%lu ids=%@", (unsigned long)response.products.count, (unsigned long)response.invalidProductIdentifiers.count, response.invalidProductIdentifiers);
	NSMutableArray *invalid = [NSMutableArray array];
	for (NSString *invalidId in response.invalidProductIdentifiers) {
		[invalid addObject:invalidId];
	}
	[self emit:@{
		@"type": @"product_info",
		@"result": @"ok",
		@"ids": ids,
		@"titles": titles,
		@"prices": prices,
		@"localized_prices": localized,
		@"localized_price": firstPrice,
		@"formatted_price": firstPrice,
		@"product_id": firstId,
		@"currency_codes": codes,
		@"invalid_ids": invalid
	}];
	if (self.pendingPurchaseId.length > 0) {
		NSString *pending = self.pendingPurchaseId;
		self.pendingPurchaseId = nil;
		if (self.products[pending] != nil) {
			[self buyProduct:pending];
		} else {
			[self emit:@{
				@"type": @"purchase",
				@"result": @"error",
				@"product_id": pending,
				@"error": @"invalid_product"
			}];
		}
	}
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
	if ([request isKindOfClass:[SKProductsRequest class]]) {
		[self.requests removeObject:(SKProductsRequest *)request];
	}
	NSString *message = error.localizedDescription ?: @"product_info_failed";
	[self emit:@{ @"type": @"product_info", @"result": @"error", @"error": message }];
	if (self.pendingPurchaseId.length > 0) {
		NSString *pending = self.pendingPurchaseId;
		self.pendingPurchaseId = nil;
		[self emit:@{
			@"type": @"purchase",
			@"result": @"error",
			@"product_id": pending,
			@"error": message
		}];
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
	for (SKPaymentTransaction *transaction in transactions) {
		NSString *pid = transaction.payment.productIdentifier ?: @"";
		switch (transaction.transactionState) {
			case SKPaymentTransactionStatePurchased: {
				NSLog(@"[CifraLetraIAP] purchased %@", pid);
				[self emit:@{
					@"type": @"purchase",
					@"result": @"ok",
					@"product_id": pid,
					@"transaction_id": transaction.transactionIdentifier ?: @""
				}];
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				break;
			}
			case SKPaymentTransactionStateRestored: {
				[self emit:@{
					@"type": @"restore",
					@"result": @"ok",
					@"product_id": pid,
					@"transaction_id": transaction.transactionIdentifier ?: @""
				}];
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				break;
			}
			case SKPaymentTransactionStateFailed: {
				BOOL cancelled = transaction.error.code == SKErrorPaymentCancelled;
				NSLog(@"[CifraLetraIAP] failed %@ cancelled=%d error=%@", pid, cancelled, transaction.error);
				[self emit:@{
					@"type": @"purchase",
					@"result": @"error",
					@"product_id": pid,
					@"cancelled": @(cancelled),
					@"error": transaction.error.localizedDescription ?: @"purchase_failed"
				}];
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				break;
			}
			case SKPaymentTransactionStatePurchasing:
			case SKPaymentTransactionStateDeferred:
				[self emit:@{ @"type": @"purchase", @"result": @"progress", @"product_id": pid }];
				break;
			default:
				break;
		}
	}
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
	[self emit:@{ @"type": @"restore", @"result": @"completed" }];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
	[self emit:@{
		@"type": @"restore",
		@"result": @"error",
		@"error": error.localizedDescription ?: @"restore_failed"
	}];
}

@end

__attribute__((constructor))
static void cifraletra_iap_ctor(void) {
	cifraletra_iap_start();
}

__attribute__((visibility("default")))
void cifraletra_iap_start(void) {
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			[[CifraLetraIAP shared] start];
		});
	});
}
