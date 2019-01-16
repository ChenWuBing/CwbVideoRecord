
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger,PrivacyPermissionType) {
    PrivacyPermissionTypePhoto = 0,
    PrivacyPermissionTypeCamera,
    PrivacyPermissionTypeMedia,
    PrivacyPermissionTypeMicrophone,
    PrivacyPermissionTypeLocation,
    PrivacyPermissionTypeBluetooth,
    PrivacyPermissionTypePushNotification,
    PrivacyPermissionTypeSpeech,
    PrivacyPermissionTypeEvent,
    PrivacyPermissionTypeContact,
    PrivacyPermissionTypeReminder,
};

typedef NS_ENUM(NSUInteger,PrivacyPermissionAuthorizationStatus) {
    PrivacyPermissionAuthorizationStatusAuthorized = 0,
    PrivacyPermissionAuthorizationStatusDenied,
    PrivacyPermissionAuthorizationStatusNotDetermined,
    PrivacyPermissionAuthorizationStatusRestricted,
    PrivacyPermissionAuthorizationStatusLocationAlways,
    PrivacyPermissionAuthorizationStatusLocationWhenInUse,
    PrivacyPermissionAuthorizationStatusUnkonwn,
};

@interface PrivacyPermission : NSObject

+ (instancetype)sharedInstance;

/**
 * @brief `Function for access the permissions` -> 获取权限函数
 * @param type `The enumeration type for access permission` -> 获取权限枚举类型
 * @param completion `A block for the permission result and the value of authorization status` -> 获取权限结果和对应权限状态的block
 */
- (void)accessPrivacyPermissionWithType:(PrivacyPermissionType)type completion:(void(^)(BOOL response,PrivacyPermissionAuthorizationStatus status))completion;

@end
