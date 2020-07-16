#include "Tweak.h"
#import <dlfcn.h>
static BBServer *bbServer = nil;
static dispatch_queue_t getBBServerQueue()
{
    static dispatch_queue_t queue;
    static dispatch_once_t predicate;
    dispatch_once(&predicate,
    ^{
        void *handle = dlopen(NULL, RTLD_GLOBAL);
        if(handle)
        {
            dispatch_queue_t __weak *pointer = (__weak dispatch_queue_t *) dlsym(handle, "__BBServerQueue");
            if(pointer) queue = *pointer;
            dlclose(handle);
        }
    });
    return queue;
}

static void fakeNotification(NSString *sectionID, NSDate *date, NSString *message, bool banner) {
    BBBulletin *bulletin = [[%c(BBBulletin) alloc] init];

    bulletin.title = @"Notifica";
    bulletin.message = message;
    bulletin.sectionID = sectionID;
    // bulletin.bulletinID = [[NSProcessInfo processInfo] globallyUniqueString];
    // bulletin.recordID = [[NSProcessInfo processInfo] globallyUniqueString];
    // bulletin.publisherBulletinID = [[NSProcessInfo processInfo] globallyUniqueString];
    bulletin.date = date;
    bulletin.defaultAction = [%c(BBAction) actionWithLaunchBundleID:sectionID callblock:nil];

    if (banner) {
        SBLockScreenNotificationListController *listController=([[%c(UIApplication) sharedApplication] respondsToSelector:@selector(notificationDispatcher)] && [[[%c(UIApplication) sharedApplication] notificationDispatcher] respondsToSelector:@selector(notificationSource)]) ? [[[%c(UIApplication) sharedApplication] notificationDispatcher] notificationSource]  : [[[%c(SBLockScreenManager) sharedInstanceIfExists] lockScreenViewController] valueForKey:@"notificationController"];
        [listController observer:[listController valueForKey:@"observer"] addBulletin:bulletin forFeed:14];
    } else {
        if ([bbServer respondsToSelector:@selector(publishBulletin:destinations:alwaysToLockScreen:)]) {
            dispatch_sync(getBBServerQueue(), ^{
                [bbServer publishBulletin:bulletin destinations:4 alwaysToLockScreen:YES];
            });
        } else if ([bbServer respondsToSelector:@selector(publishBulletin:destinations:)]) {
            dispatch_sync(getBBServerQueue(), ^{
                [bbServer publishBulletin:bulletin destinations:4];
            });
        }
    }
}


%hook SpringBoard
-(void)_ringerChanged:(struct __IOHIDEvent *)arg1 {

        fakeNotification(@"com.apple.MobileSMS", [NSDate date], @"Test banner!", true);
        fakeNotification(@"com.apple.MobileSMS", [NSDate date], @"Test notification 9!", false);
        fakeNotification(@"com.apple.mobilephone", [NSDate date], @"Test notification 15!", false);
	%orig;
}
%end

%hook BBServer
- (id)init {
  id me = %orig;
  bbServer = me;
  return me;
}

-(id)initWithQueue:(id)arg1 {
  id me = %orig;
  bbServer = me;
  return me;
}

-(id)initWithQueue:(id)arg1 dataProviderManager:(id)arg2 syncService:(id)arg3 dismissalSyncCache:(id)arg4 observerListener:(id)arg5 utilitiesListener:(id)arg6 conduitListener:(id)arg7 systemStateListener:(id)arg8 settingsListener:(id)arg9 {
  id me = %orig;
  bbServer = me;
  return me;
}

- (void)dealloc {
  if (bbServer == self) {
    bbServer = nil;
  }

  %orig;
}
%end

%ctor{
  
}
