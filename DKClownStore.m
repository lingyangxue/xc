#import "DKClownStore.h"
#import <objc/runtime.h>

DKClownType const DKClownTypeText     = @"text";
DKClownType const DKClownTypeTime     = @"time";
DKClownType const DKClownTypeImage    = @"image";
DKClownType const DKClownTypeTransfer = @"transfer";

NSString *const kDKClownEntryType  = @"type";
NSString *const kDKClownEntryValue = @"value";
NSString *const kDKClownEntryExtra = @"extra";

static NSString *const kDKClownPlistName     = @"DKHelperClownOverrides.plist";
static NSString *const kDKClownRestoreKey    = @"DKClownRestoreOriginal";

@interface DKClownStore ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *store;
@end

@implementation DKClownStore

+ (instancetype)sharedStore {
    static DKClownStore *s; static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [DKClownStore new]; });
    return s;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 对应反汇编：dictionaryWithContentsOfFile: -> mutableCopy / 空 dictionary
        NSDictionary *saved = [NSDictionary dictionaryWithContentsOfFile:self.filePath];
        _store = saved ? saved.mutableCopy : [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - 路径（对应 DKClownOverrideFilePath）

- (NSString *)filePath {
    NSArray<NSString *> *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                    NSUserDomainMask, YES);
    return [dirs.firstObject stringByAppendingPathComponent:kDKClownPlistName];
}

- (void)flush {
    [self.store writeToFile:self.filePath atomically:YES];
}

#pragma mark - 读写

- (NSDictionary *)entryForKey:(NSString *)key {
    if (key.length == 0) return nil;                     // 对应 CBZ x0 -> return nil
    id obj = self.store[key];
    return [obj isKindOfClass:NSDictionary.class] ? obj : nil;  // 对应 isKindOfClass 校验
}

- (void)setEntry:(NSDictionary *)entry forKey:(NSString *)key {
    if (key.length == 0 || ![entry isKindOfClass:NSDictionary.class]) return;
    self.store[key] = entry;
    [self flush];
}

- (void)removeEntryForKey:(NSString *)key {
    if (key.length == 0) return;
    [self.store removeObjectForKey:key];
    [self flush];
}

/// 对应 -[BNHelperSettingController clearClownCache]
- (void)clearAll {
    [self.store removeAllObjects];
    [self flush];
    [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:nil];
}

#pragma mark - 消息 key（对应 DKClownMessageKeyForModel）

- (NSString *)keyForMessage:(id)msg {
    if (!msg) return nil;
    // 依次尝试微信消息 model 的常用唯一标识字段
    for (NSString *prop in @[@"m_ui64MesSvrID", @"m_uiMesSvrID", @"m_uiLocalID", @"m_uiMessageID"]) {
        id v = [msg valueForKey:prop];
        if (v && ![v isEqual:@0]) return [NSString stringWithFormat:@"%@:%@", prop, v];
    }
    // 兜底：用描述做 key（同一消息对象在会话内稳定）
    return [NSString stringWithFormat:@"desc:%@", [msg description]];
}

#pragma mark - 总开关

- (BOOL)restoreOriginal {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDKClownRestoreKey];
}

- (void)setRestoreOriginal:(BOOL)restoreOriginal {
    [[NSUserDefaults standardUserDefaults] setBool:restoreOriginal forKey:kDKClownRestoreKey];
}

@end
