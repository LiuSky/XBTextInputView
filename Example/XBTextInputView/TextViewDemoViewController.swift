//
//  TextViewDemoViewController.swift
//  XBTextInputView_Example
//
//  Created by xiaobin liu on 2020/3/16.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import XBTextInputView

/// MARK - TextViewDemoViewController
final class TextViewDemoViewController: UIViewController {

    /// 格式
    public var formatterType: FormatterType = .default {
        didSet {
            textView.formatterType = formatterType
        }
    }
    
    private lazy var textView: XBTextView = {
        $0.placeholder = "请输入文字"
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = UIColor.white
        $0.layer.cornerRadius = 4
        $0.layer.masksToBounds = true
        $0.layer.borderColor = UIColor(red: 222/255.0, green: 224/255.0, blue: 226/255.0, alpha: 1.0).cgColor
        $0.layer.borderWidth = 1 / UIScreen.main.scale
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.textAlignment = .left
        $0.autoResizable = true
        $0.maximumTextLength = 300
        $0.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        $0.delegate = self
        return $0
    }(XBTextView())
    
    /// 高度
    private var textViewHeight: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -300),
        ])
        textViewHeight = textView.heightAnchor.constraint(equalToConstant: 100)
        textViewHeight?.isActive = true
        
        
        textView.text = "哈哈哈"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.textView.endEditing(true)
    }

}

/// MARK - XBTextViewDelegate
extension TextViewDemoViewController: XBTextViewDelegate {
    
    func textViewShouldReturn(_ textView: XBTextView) -> Bool {
        return false
    }
    
    func textView(_ textView: XBTextView, didPreventTextChangeInRange range: NSRange, replacementText: String?) {
        debugPrint(replacementText ?? "")
    }
    
    func textView(_ textView: XBTextView, newHeightAfterTextChanged height: CGFloat) {
        if height >= 100 {
            textViewHeight?.isActive = false
            textViewHeight?.constant = height
            textViewHeight?.isActive = true
        } else {
            if textViewHeight?.constant != 100 {
                textViewHeight?.isActive = false
                textViewHeight?.constant = 100
                textViewHeight?.isActive = true
            }
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        debugPrint("开始编辑")
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        debugPrint("结束编辑")
    }
    
    func textViewDidChange(_ textView: UITextView) {
        debugPrint("开始改变")
    }
}
