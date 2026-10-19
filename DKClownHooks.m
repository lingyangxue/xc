//
//  DKClownHooks.m
//  显示层 hook（对应原实现中 logos 生成的那批 _logos_method$...）
//
//  说明：原始 dylib 用 Theos/logos 在编译期绑定微信类名。
//  本独立版本改为运行时按类名查找 + MSHookMessageEx 交换，
//  无需微信头文件即可编译；类名/方法名以你目标微信版本的
//  实际符号为准（用 nm / weak_classdump 确认后填入下方配置）。
//
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "DKClownStore.h"
#import "DKClownEditor.h"

#pragma mark - 通用运行时 swizzle

static void DKSwap(Class cls, SEL sel, IMP newImp, IMP *outOrig) {
    if (!cls || !sel) return;
    Method m = class_getInstanceMethod(cls, sel);
    if (!m) return;
    IMP orig = method_getImplementation(m);
    if (outOrig) *outOrig = orig;
    method_setImplementation(m, newImp);
}

#pragma mark - 显示应用工具（对应 DKClownEntryForKey 的各处调用点）

/// 查询某条消息的某类修改；总开关打开（restoreOriginal=YES）时一律返回 nil
static NSDictionary *DKOverride(id msg, DKClownType type) {
    if (DKClownStore.sharedStore.restoreOriginal) return nil;
    NSString *key = [DKClownStore.sharedStore keyForMessage:msg];
    NSDictionary *e = [DKClownStore.sharedStore entryForKey:key];
    if (e && [e[kDKClownEntryType] isEqual:type]) return e;
    return nil;
}

/// 文字替换
static NSString *DKDisplayText(id msg, NSString *origText) {
    NSDictionary *e = DKOverride(msg, DKClownTypeText);
    return e ? e[kDKClownEntryValue] : origText;
}

/// 时间替换（返回 NSString，显示层自行格式化）
static NSString *DKDisplayTime(id msg, NSString *origTime) {
    NSDictionary *e = DKOverride(msg, DKClownTypeTime);
    return e ? e[kDKClownEntryValue] : origTime;
}

/// 转账金额替换
static NSString *DKDisplayAmount(id msg, NSString *origAmount) {
    NSDictionary *e = DKOverride(msg, DKClownTypeTransfer);
    return e ? e[kDKClownEntryValue] : origAmount;
}

/// 图片替换（对应 DKChatImageOverride / DKChatImageOverridePath）：
/// 有替换记录时返回替换图路径，否则返回原始路径。
static NSString *DKImagePath(id msg, NSString *origPath) {
    NSDictionary *e = DKOverride(msg, DKClownTypeImage);
    if (!e) return origPath;
    NSString *p = e[kDKClownEntryExtra];
    return ([[NSFileManager defaultManager] fileExistsAtPath:p]) ? p : origPath;
}

#pragma mark - Hook 配置（★按目标微信版本实际符号填写★）

/// 例：文字消息 Cell 展示方法（原实现 hook 的对象之一）
static NSString *const kTextCellClass  = @"ChatTextMessageCellView";   // TODO: 核实
static NSString *const kTextCellSel    = @"setMessage:";               // TODO: 核实
/// 例：Cell 取展示文字的方法
static NSString *const kGetTextSel     = @"displayText";               // TODO: 核实

#pragma mark - Hook 实现模板

static IMP g_origSetMessage;

/// setMessage: 的替换实现：绑定消息 -> 挂长按编辑器 -> 走原始展示
static void DKSetMessage(id self, SEL _cmd, id msg) {
    ((void(*)(id, SEL, id))g_origSetMessage)(self, _cmd, msg);
    if (msg) {
        [DKClownEditor attachToCell:(UIView *)self message:msg];
    }
}

#pragma mark - 安装

__attribute__((constructor))
static void DKClownInstall(void) {
    // 文字 cell：hook 展示方法
    Class textCell = NSClassFromString(kTextCellClass);
    DKSwap(textCell, NSSelectorFromString(kTextCellSel),
            (IMP)DKSetMessage, &g_origSetMessage);

    // 图片路径：hook 缓存取图方法（对应 DKChatImageOverride 调用点）
    // Class imgCell = NSClassFromString(@"...");
    // DKSwap(imgCell, @selector(...), (IMP)DKImagePathHook, &g_origImgGet);

    // 转账：hook 转账消息 model 的金额字段读取（对应 DKApplyTransferOverrideToModel）
    // Class transferModel = NSClassFromString(@"...");
    // DKSwap(transferModel, @selector(...), (IMP)DKAmountHook, &g_origAmountGet);
}

/*
 * 接入步骤：
 * 1. 在目标微信二进制上执行 `nm -g 微信二进制 | grep -i <关键字>`，
 *    或用前面做的 BL 调用者回溯，找出被 hook 的 Cell/model 真实类名与方法名；
 * 2. 填入上方 kTextCellClass 等配置；
 * 3. 在对应实现里调用 DKDisplayText / DKDisplayTime / DKDisplayAmount / DKImagePath
 *    完成"显示前查表替换"；
 * 4. 长按编辑入口已由 DKClownEditor 完成，无需改动。
 */
