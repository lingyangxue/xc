//
//  DKClownEditor.h
//  修改入口 UI：聊天页长按消息 -> 弹输入框 -> 保存修改（对应原实现的长按交互）
//
#import <UIKit/UIKit.h>
#import "DKClownStore.h"

NS_ASSUME_NONNULL_BEGIN

/// 长按消息 cell 后弹出的"小丑"编辑菜单（改文字 / 改时间 / 改图片 / 改转账金额 / 还原）
@interface DKClownEditor : NSObject

/// 给任意 cell 挂长按手势（在 cell 展示 hook 里调用一次即可）
+ (void)attachToCell:(UIView *)cell message:(id)messageWrap;

/// 手动弹出编辑菜单
+ (void)presentForMessage:(id)messageWrap fromView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
