//
//  TextFieldDemoViewController.swift
//  XBTextInputView_Example
//
//  Created by xiaobin liu on 2020/3/13.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import XBTextInputView

/// MARK - Demo
final class TextFieldDemoViewController: UIViewController {

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
        /// 平滑圆角 https://github.com/JunyuKuang/Rhythm/blob/12d2e95173a4278af424a5b05f2f2402d9fe748e/LyricsUI/AlbumArtworkView.swift#L75
        $0.clipsToBounds = true
        if #available(iOS 13, *) {
            $0.layer.cornerCurve = .continuous
        } else {
            $0.layer.setValue(true, forKey: "continuousCorners")
        }
        $0.placeholderColor = UIColor.black
        $0.placeholder = "情输入内容"
        $0.clearButtonMode = .always
        $0.clearButtonPositionAdjustment = UIOffset(horizontal: -10, vertical: 0)
        $0.delegate = self
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
}

/// MARK - UITextFieldDelegate
extension TextFieldDemoViewController: XBTextFieldDelegate {
    
    func textField(_ textField: XBTextField, didPreventTextChangeInRange range: NSRange, replacementString: String?) {
        debugPrint("超出了长度\(replacementString ?? "")")
    }
}
