#import "AVAudioSession+SetCategory.h"

@implementation AVAudioSession (SetCategory)

- (BOOL) objcSetCategory: (AVAudioSessionCategory) category error: (NSError**) error
{
    return [self setCategory:category error:error];
}

@end
