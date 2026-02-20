#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "HighlanderLogo" asset catalog image resource.
static NSString * const ACImageNameHighlanderLogo AC_SWIFT_PRIVATE = @"HighlanderLogo";

#undef AC_SWIFT_PRIVATE
