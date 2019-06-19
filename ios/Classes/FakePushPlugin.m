#import "FakePushPlugin.h"
#import <FakeXinGePush/XGPush.h>
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import <UserNotifications/UserNotifications.h>
#endif

@interface FakePushPlugin () <XGPushDelegate>

@end

@implementation FakePushPlugin {
    FlutterMethodChannel *_channel;
    
    NSDictionary *_launchNotification;
    BOOL _resumingFromBackground;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"v7lin.github.io/fake_push"
                                     binaryMessenger:[registrar messenger]];
    FakePushPlugin* instance = [[FakePushPlugin alloc] initWithChannel:channel];
    [registrar addApplicationDelegate:instance];
    [registrar addMethodCallDelegate:instance channel:channel];
}

static NSString * const METHOD_ARENOTIFICATIONSENABLED = @"areNotificationsEnabled";
static NSString * const METHOD_REQUESTNOTIFICATIONSPERMISSION = @"requestNotificationsPermission";
static NSString * const METHOD_STARTWORK = @"startWork";
static NSString * const METHOD_GETDEVICETOKEN = @"getDeviceToken";
static NSString * const METHOD_STOPWORK = @"stopWork";
static NSString * const METHOD_BINDACCOUNT = @"bindAccount";
static NSString * const METHOD_UNBINDACCOUNT = @"unbindAccount";
static NSString * const METHOD_BINDTAGS = @"bindTags";
static NSString * const METHOD_UNBINDTAGS = @"unbindTags";

static NSString * const METHOD_ONREGISTEREDDEVICETOKEN = @"onRegisteredDeviceToken";
static NSString * const METHOD_ONMESSAGE = @"onMessage";
static NSString * const METHOD_ONNOTIFICATION = @"onNotification";
static NSString * const METHOD_ONLAUNCHNOTIFICATION = @"onLaunchNotification";
static NSString * const METHOD_ONRESUMENOTIFICATION = @"onResumeNotification";

static NSString * const ARGUMENT_KEY_ENABLEDEBUG = @"enableDebug";
static NSString * const ARGUMENT_KEY_ACCOUNT = @"account";
static NSString * const ARGUMENT_KEY_TAGS = @"tags";

static NSString * const ARGUMENT_KEY_RESULT_TITLE = @"title";
static NSString * const ARGUMENT_KEY_RESULT_CONTENT = @"content";
static NSString * const ARGUMENT_KEY_RESULT_CUSTOMCONTENT = @"customContent";

static NSString * const SHAREDPREF_KEY_HAS_BEEN_DETERMINED = @"fake_push_has_been_determined";

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel {
    self = [super init];
    if (self) {
        _channel = channel;
        _resumingFromBackground = NO;
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([METHOD_ARENOTIFICATIONSENABLED isEqualToString:call.method]) {
        [[XGPush defaultManager] deviceNotificationIsAllowed:^(BOOL isAllowed) {
            result([NSNumber numberWithBool:isAllowed]);
        }];
    } else if ([METHOD_REQUESTNOTIFICATIONSPERMISSION isEqualToString:call.method]) {
        [self requestNotificationsPermission:call result:result];
    } else if ([METHOD_STARTWORK isEqualToString:call.method]) {
        [self startWork:call result:result];
    } else if ([METHOD_GETDEVICETOKEN isEqualToString:call.method]) {
        result([[XGPushTokenManager defaultTokenManager] deviceTokenString]);
    } else if ([METHOD_STOPWORK isEqualToString:call.method]) {
        [self stopWork:call result:result];
    } else if ([METHOD_BINDACCOUNT isEqualToString:call.method]) {
        [self bindAccount:call result:result];
    } else if ([METHOD_UNBINDACCOUNT isEqualToString:call.method]) {
        [self unbindAccount:call result:result];
    } else if ([METHOD_BINDTAGS isEqualToString:call.method]) {
        [self bindTags:call result:result];
    } else if ([METHOD_UNBINDTAGS isEqualToString:call.method]) {
        [self unbindTags:call result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)requestNotificationsPermission:(FlutterMethodCall*)call result:(FlutterResult)result {
    if (@available(iOS 10.0, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined) {
                [self requestNotificationsPermissionNotDetermined];
            } else {
                NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                [self performSelectorOnMainThread:@selector(openURLCompat:) withObject:url waitUntilDone:NO];
            }
        }];
    } else {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SHAREDPREF_KEY_HAS_BEEN_DETERMINED]) {
            NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [self performSelectorOnMainThread:@selector(openURLCompat:) withObject:url waitUntilDone:NO];
        } else {
            [self requestNotificationsPermissionNotDetermined];
        }
    }
    result(nil);
}

- (void)requestNotificationsPermissionNotDetermined {
    if (@available(iOS 10.0, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        }];
    } else {
        UIUserNotificationType myTypes = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:myTypes categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
}

- (void) openURLCompat:(NSURL *)url {
    if (@available(iOS 11.0, *)) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    } else {
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)startWork:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSNumber *enableDebug = call.arguments[ARGUMENT_KEY_ENABLEDEBUG];
    [[XGPush defaultManager] setEnableDebug:[enableDebug boolValue]];
    NSString *accessId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"XG_ACCESS_ID"];
    NSString *accessKey = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"XG_ACCESS_KEY"];
    uint32_t accessIdUint32 = (uint32_t)[accessId longLongValue];
    [[XGPush defaultManager] startXGWithAppID:accessIdUint32 appKey:accessKey delegate:self];
    if (_launchNotification != nil) {
        [self didLaunchRemoteNotification:_launchNotification];
    }
    result(nil);
}

- (void)stopWork:(FlutterMethodCall*)call result:(FlutterResult)result {
    [[XGPush defaultManager] stopXGNotification];
    result(nil);
}

- (void)bindAccount:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *account = call.arguments[ARGUMENT_KEY_ACCOUNT];
    [[XGPushTokenManager defaultTokenManager] bindWithIdentifier:account type:XGPushTokenBindTypeAccount];
    result(nil);
}

- (void)unbindAccount:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *account = call.arguments[ARGUMENT_KEY_ACCOUNT];
    [[XGPushTokenManager defaultTokenManager] unbindWithIdentifer:account type:XGPushTokenBindTypeAccount];
    result(nil);
}

- (void)bindTags:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSArray *tags = call.arguments[ARGUMENT_KEY_TAGS];
    [[XGPushTokenManager defaultTokenManager] bindWithIdentifiers:tags type:XGPushTokenBindTypeTag];
    result(nil);
}

- (void)unbindTags:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSArray *tags = call.arguments[ARGUMENT_KEY_TAGS];
    [[XGPushTokenManager defaultTokenManager] unbindWithIdentifers:tags type:XGPushTokenBindTypeTag];
    result(nil);
}

- (void)didLaunchRemoteNotification:(NSDictionary *)userInfo {
    [_channel invokeMethod:METHOD_ONLAUNCHNOTIFICATION arguments:[self parseNotification:userInfo]];
}

- (void)didResumeRemoteNotification:(NSDictionary *)userInfo {
    [_channel invokeMethod:METHOD_ONRESUMENOTIFICATION arguments:[self parseNotification:userInfo]];
}

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo {
    int contentAvailable = 0;
    NSDictionary *aps = userInfo[@"aps"];
    if ([aps objectForKey:@"content-available"]) {
        contentAvailable = [[NSString stringWithFormat:@"%@", aps[@"content-available"]] intValue];
    }
    if (contentAvailable == 1) {
        // 静默消息
        [_channel invokeMethod:METHOD_ONMESSAGE arguments:[self parseMessage:userInfo]];
    } else {
        // 通知推送
        [_channel invokeMethod:METHOD_ONNOTIFICATION arguments:[self parseNotification:userInfo]];
    }
}

- (NSDictionary *)parseMessage:(NSDictionary *)userInfo {
    NSDictionary *alert = userInfo[@"aps"][@"alert"];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[ARGUMENT_KEY_RESULT_TITLE] = alert[@"title"] ?: @"";
    dict[ARGUMENT_KEY_RESULT_CONTENT] = alert[@"body"] ?: @"";
    dict[ARGUMENT_KEY_RESULT_CUSTOMCONTENT] = [self parseCustomContent:userInfo] ?: @"";
    return dict;
}

- (NSDictionary *)parseNotification:(NSDictionary *)userInfo {
    NSDictionary *alert = userInfo[@"aps"][@"alert"];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[ARGUMENT_KEY_RESULT_TITLE] = alert[@"title"] ?: @"";
    dict[ARGUMENT_KEY_RESULT_CONTENT] = alert[@"body"] ?: @"";
    dict[ARGUMENT_KEY_RESULT_CUSTOMCONTENT] = [self parseCustomContent:userInfo] ?: @"";
    return dict;
}

- (NSString *)parseCustomContent:(NSDictionary *)userInfo {
    NSMutableDictionary *customContent = [[NSMutableDictionary alloc] init];
    
    NSEnumerator *enumerator = [userInfo keyEnumerator];
    id key;
    while ((key = [enumerator nextObject])) {
        if (![key isEqual: @"xg"] && ![key isEqual: @"aps"]) {
            customContent[key] = userInfo[key];
        }
    }
    
    if (customContent.count == 0) {
        return nil;
    }
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:customContent options:NSJSONWritingPrettyPrinted error:&error];
    if(!error) {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

# pragma mark - AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[XGPush defaultManager] reportXGNotificationInfo:launchOptions];
    if (launchOptions != nil) {
        _launchNotification = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    }
    return YES;
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    if (@available(iOS 10.0, *)) {
        // do nothing
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:SHAREDPREF_KEY_HAS_BEEN_DETERMINED];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    _resumingFromBackground = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    _resumingFromBackground = NO;
}

- (BOOL)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [[XGPush defaultManager] reportXGNotificationInfo:userInfo];
    if (_resumingFromBackground) {
        [self didResumeRemoteNotification:userInfo];
    } else {
        [self didReceiveRemoteNotification:userInfo];
    }
    completionHandler(UIBackgroundFetchResultNewData);
    return YES;
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"ios push device token: %@", [[NSString alloc] initWithData:deviceToken encoding:NSUTF8StringEncoding]);
}

# pragma mark - XGPushDelegate

// iOS 10 新增 API
// iOS 10 会走新 API, iOS 10 以前会走到老 API
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
// App 用户点击通知
// App 用户选择通知中的行为
// App 用户在通知中心清除消息
// 无论本地推送还是远程推送都会走这个回调
- (void)xgPushUserNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler __IOS_AVAILABLE(10.0) {
    [[XGPush defaultManager] reportXGNotificationResponse:response];
    [self didResumeRemoteNotification:response.notification.request.content.userInfo];
    // resume
    completionHandler();
}

// App 在前台弹通知需要调用这个接口
- (void)xgPushUserNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler __IOS_AVAILABLE(10.0) {
    [[XGPush defaultManager] reportXGNotificationInfo:notification.request.content.userInfo];
    [self didReceiveRemoteNotification:notification.request.content.userInfo];
    completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
}
#endif

-(void)xgPushDidRegisteredDeviceToken:(NSString *)deviceToken error:(NSError *)error {
    NSLog(@"xg push device token: %@", deviceToken);
    [_channel invokeMethod:METHOD_ONREGISTEREDDEVICETOKEN arguments:deviceToken];
}

@end
