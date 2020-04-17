//
//  OCViewController.m
//  XBTextInputView_Example
//
//  Created by xiaobin liu on 2020/4/17.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

#import "OCViewController.h"
#import <XBTextInputView/XBTextInputView-Swift.h>

@interface OCViewController ()
@property(nonatomic, strong) XBTextView *textView;
@end

@implementation OCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}


-(XBTextView *)textView {
    if (!_textView) {
        _textView = [[XBTextView alloc]initWithFrame:CGRectZero textContainer:nil];
        _textView.maximumTextLength = 15;
    }
    return _textView;;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
