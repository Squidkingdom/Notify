#import "Tweak.h"

BOOL added = NO;
BBServer *notificationserver;

%hook BBServer
-(id)initWithQueue:(id)arg1 {
    notificationserver = %orig;
    return notificationserver;
}
-(id)initWithQueue:(id)arg1 dataProviderManager:(id)arg2 syncService:(id)arg3 dismissalSyncCache:(id)arg4 observerListener:(id)arg5 utilitiesListener:(id)arg6 conduitListener:(id)arg7 systemStateListener:(id)arg8 settingsListener:(id)arg9 {
    notificationserver = %orig;
    return notificationserver;
}
- (void)dealloc {
  if (notificationserver == self) {
    notificationserver = nil;
  }
  %orig;
}
%end

static dispatch_queue_t getBBServerQueue() {
    static dispatch_queue_t queue;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        void *handle = dlopen(NULL, RTLD_GLOBAL);
        if (handle) {
            dispatch_queue_t __weak *pointer = (__weak dispatch_queue_t *) dlsym(handle, "__BBServerQueue");
            if (pointer) {
                queue = *pointer;
            }
            dlclose(handle);
        }
    });
    return queue;
}

static void sendNoti() {
	BBBulletin *bulletin = [[[objc_getClass("BBBulletin") class] alloc] init];
	bulletin.title = @"Title";
	bulletin.message = @"Content";
	bulletin.sectionID = @"com.apple.Preferences";
	bulletin.bulletinID = [[NSProcessInfo processInfo] globallyUniqueString];
	bulletin.recordID = [[NSProcessInfo processInfo] globallyUniqueString];
	bulletin.publisherBulletinID = [[NSProcessInfo processInfo] globallyUniqueString];

	bulletin.date = [NSDate date];

	bulletin.defaultAction = [[objc_getClass("BBAction") class] actionWithLaunchBundleID:nil callblock:nil];
	dispatch_sync(getBBServerQueue(), ^{
		[notificationserver publishBulletin:bulletin destinations:14];
	});
}
%hook SpringBoard
-(void)_ringerChanged:(struct __IOHIDEvent *)arg1 {
      sendNoti();
	    %orig;
}
%end
