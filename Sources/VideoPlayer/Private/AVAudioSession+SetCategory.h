#import <AVFoundation/AVFoundation.h>

@interface AVAudioSession (SetCategory)

NS_ASSUME_NONNULL_BEGIN

/// workaround for "setCategory is unavailable in Swift4.2"
- (BOOL) objcSetCategory: (AVAudioSessionCategory) category error: (NSError  * _Nullable *) error;

NS_ASSUME_NONNULL_END

@end
