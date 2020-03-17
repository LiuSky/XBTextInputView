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

    private lazy var textView: XBTextView = {
        $0.placeholder = "请输入文字"
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = UIColor.red
        $0.layer.cornerRadius = 10
        $0.layer.masksToBounds = true
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.textAlignment = .left
        $0.maximumTextLength = 100
        return $0
    }(XBTextView())
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            textView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }

}
