//
//  DKClownStore.h
//  小丑模块 —— 本机显示内容修改（聊天/图片/时间/转账）
//  依据 wechatku.dylib 反汇编结构还原（DKClownOverrideStore 等）
//
//  原理：只修改本机显示。所有修改以 plist 存于微信 Documents 目录，
//  key 为消息唯一 ID，重启后仍然生效；关闭总开关即恢复原始内容。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 修改类型（对应原实现的 entry["type"]）
typedef NSString *DKClownType NS_TYPED_ENUM;
extern DKClownType const DKClownTypeText;     // 聊天小丑：替换文字
extern DKClownType const DKClownTypeTime;     // 时间小丑：替换显示时间
extern DKClownType const DKClownTypeImage;    // 图片小丑：替换图片
extern DKClownType const DKClownTypeTransfer; // 转账小丑：替换转账金额

/// entry 字典字段
extern NSString *const kDKClownEntryType;     // DKClownType
extern NSString *const kDKClownEntryValue;    // NSString：替换后的显示内容
extern NSString *const kDKClownEntryExtra;    // NSString：附加数据（如图片绝对路径）

@interface DKClownStore : NSObject

+ (instancetype)sharedStore;

#pragma mark - 存储（对应 DKClownOverrideFilePath / DKClownOverrideStore）

/// plist 完整路径：Documents/DKHelperClownOverrides.plist
@property (nonatomic, copy, readonly) NSString *filePath;

/// 读取某条修改记录；不存在或类型不符返回 nil（对应 DKClownEntryForKey）
- (nullable NSDictionary *)entryForKey:(nullable NSString *)key;

/// 写入/覆盖一条修改记录（对应 DKSetClownEntryValues）
- (void)setEntry:(NSDictionary *)entry forKey:(NSString *)key;

- (void)removeEntryForKey:(NSString *)key;

/// 永久清除全部修改记录（对应 clearClownCache，不可恢复）
- (void)clearAll;

#pragma mark - 消息 key（对应 DKClownMessageKeyForModel）

/// 由微信消息 model（CMessageWrap 或兼容对象）生成稳定唯一 key
- (nullable NSString *)keyForMessage:(id)messageWrap;

#pragma mark - 总开关（对应 +[DKHelperConfig clownRestoreOriginal]）

/// YES = 恢复原始显示；NO = 应用已保存的修改。持久化于 NSUserDefaults。
@property (nonatomic, assign) BOOL restoreOriginal;

@end

NS_ASSUME_NONNULL_END
