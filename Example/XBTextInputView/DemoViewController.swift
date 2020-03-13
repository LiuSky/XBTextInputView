//
//  DemoViewController.swift
//  XBTextInputView_Example
//
//  Created by xiaobin liu on 2020/3/13.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import XBTextInputView

/// MARK - Demo
final class DemoViewController: UIViewController {

    /// 格式
    public var formatterType: FormatterType = .default {
        didSet {
            textField.formatterType = formatterType
        }
    }
    
    /// 文本
    private lazy var textField: XBTextField = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = UIColor.gray
        $0.layer.cornerRadius = 10
        $0.layer.masksToBounds = true
        $0.placeholderColor = UIColor.black
        $0.placeholder = "情输入内容"
        $0.clearButtonMode = .always
        $0.clearButtonPositionAdjustment = UIOffset(horizontal: -10, vertical: 0)
        $0.addTarget(self, action: #selector(handleTextChangeEvent(_:)), for: UIControl.Event.editingChanged)
        return $0
    }(XBTextField())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        view.addSubview(textField)
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            textField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            textField.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc
    private func handleTextChangeEvent(_ textField: XBTextField) {
        debugPrint(textField.text ?? "")
    }
}

/// MARK - UITextFieldDelegate
extension DemoViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        debugPrint("do thing")
        return true
    }
}
