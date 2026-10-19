#import "DKClownEditor.h"
#import <objc/runtime.h>

static const void *kDKClownMsgKey = &kDKClownMsgKey;

@implementation DKClownEditor

#pragma mark - 长按手势

+ (void)attachToCell:(UIView *)cell message:(id)messageWrap {
    if (!cell || objc_getAssociatedObject(cell, kDKClownMsgKey)) return; // 只挂一次
    objc_setAssociatedObject(cell, kDKClownMsgKey, messageWrap,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UILongPressGestureRecognizer *g =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPress:)];
    g.minimumPressDuration = 0.8;
    [cell addGestureRecognizer:g];
}

+ (void)onLongPress:(UILongPressGestureRecognizer *)g {
    if (g.state != UIGestureRecognizerStateBegan) return;
    UIView *cell = g.view;
    id msg = objc_getAssociatedObject(cell, kDKClownMsgKey);
    if (msg) [self presentForMessage:msg fromView:cell];
}

#pragma mark - 编辑菜单

+ (void)presentForMessage:(id)msg fromView:(UIView *)view {
    DKClownStore *store = DKClownStore.sharedStore;
    NSString *key = [store keyForMessage:msg];
    if (key.length == 0) return;

    UIAlertController *ac =
        [UIAlertController alertControllerWithTitle:@"小丑功能"
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleActionSheet];

    void (^edit)(DKClownType, NSString *) = ^(DKClownType type, NSString *title) {
        UIAlertController *input =
            [UIAlertController alertControllerWithTitle:title
                                                message:@"修改仅本机生效，重启微信后仍有效"
                                         preferredStyle:UIAlertControllerStyleAlert];
        [input addTextFieldWithConfigurationHandler:^(UITextField *tf) {
            NSDictionary *old = [store entryForKey:key];
            tf.text = old[kDKClownEntryValue] ?: @"";
        }];
        [input addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *a) {
            NSString *v = input.textFields.firstObject.text ?: @"";
            NSDictionary *entry = @{kDKClownEntryType: type, kDKClownEntryValue: v};
            [store setEntry:entry forKey:key];
        }]];
        [input addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [DKClownEditor.topPresenter presentViewController:input animated:YES completion:nil];
    };

    [ac addAction:[UIAlertAction actionWithTitle:@"聊天小丑（改文字）"
                                           style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction *a){ edit(DKClownTypeText, @"替换显示文字"); }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"时间小丑（改时间）"
                                           style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction *a){ edit(DKClownTypeTime, @"替换显示时间"); }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"转账小丑（改金额）"
                                           style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction *a){ edit(DKClownTypeTransfer, @"替换转账金额"); }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"还原本条"
                                           style:UIAlertActionStyleDestructive
                                         handler:^(UIAlertAction *a){ [store removeEntryForKey:key]; }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    [DKClownEditor.topPresenter presentViewController:ac animated:YES completion:nil];
}

#pragma mark - 顶层 VC

+ (UIViewController *)topPresenter {
    UIWindow *win = UIApplication.sharedApplication
        .connectedScenes.allObjects.firstObject ?: nil;
    UIViewController *root;
    // iOS 13+ Scene 与旧版 window 双兼容
    UIScene *scene = UIApplication.sharedApplication.connectedScenes.allObjects.firstObject;
    if ([scene isKindOfClass:UIWindowScene.class]) {
        UIWindowScene *ws = (UIWindowScene *)scene;
        root = ws.windows.firstObject.rootViewController;
    }
    if (!root) root = UIApplication.sharedApplication.keyWindow.rootViewController;
    while (root.presentedViewController) root = root.presentedViewController;
    return root;
}

@end
