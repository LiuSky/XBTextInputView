//
//  XBTextField.swift
//  XBTextInputView
//
//  Created by xiaobin liu on 2020/3/13.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit

/// MARK - XBTextField
open class XBTextField: UITextField {
    
    /// MARK - 私有的类，专用于实现 WZTextFieldDelegate，避免 self.delegate = self 的写法（以前是 WZTextField 自己实现了 delegate）
    private class TextFieldDelegator: NSObject, UITextFieldDelegate, UIScrollViewDelegate {
        
        /// 文本
        public weak var textField: XBTextField?
        
        /// 当前文本
        private var currentString: String?
        
        /// 处理文本更改事件
        /// - Parameter textField: <#textField description#>
        @objc
        public func handleTextChangeEvent(_ textField: XBTextField) {
            
            // 1、iOS 10 以下的版本，从中文输入法的候选词里选词输入，是不会走到 textField:shouldChangeCharactersInRange:replacementString: 的，所以要在这里截断文字
            // 2、如果是中文输入法正在输入拼音的过程中（markedTextRange 不为 nil），是不应该限制字数的（例如输入“huang”这5个字符，其实只是为了输入“黄”这一个字符），所以在 shouldChange 那边不会限制，而是放在 didChange 这里限制。
            guard let _ = textField.markedTextRange else {
                if (textField.text! as NSString).length > textField.maximumTextLength {
                    textField.text = (textField.text! as NSString).substring(to: textField.maximumTextLength)
                }
                
                guard let regexString = textField.formatterType.regexString,
                      let text = textField.text  else {
                        return
                }
                
                let predicate = NSPredicate(format: "SELF MATCHES %@", regexString)
                if !(predicate.evaluate(with: text) || text.count <= 0) {
                    
                    /// 因为底层会对Text 进行通知以及更新。所有会触发两次
                    let shouldResponseToProgrammaticallyTextChanges = textField.shouldResponseToProgrammaticallyTextChanges
                    textField.shouldResponseToProgrammaticallyTextChanges = false
                    textField.text = currentString
                    textField.shouldResponseToProgrammaticallyTextChanges = shouldResponseToProgrammaticallyTextChanges
                } else {
                    currentString = textField.text
                }
                return
            }
        }
        
        
        
        /// UITextFieldDelegate
        /// - Parameters:
        ///   - textField: UITextField
        ///   - range: NSRange
        ///   - string: String
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            
            
            guard let temTextField = textField as? XBTextField,
                temTextField.maximumTextLength < Int.max  else {
                return true
            }
            
            // 如果是中文输入法正在输入拼音的过程中（markedTextRange 不为 nil），是不应该限制字数的（例如输入“huang”这5个字符，其实只是为了输入“黄”这一个字符），所以在 shouldChange 这里不会限制，而是放在 didChange 那里限制。
            if textField.markedTextRange != nil {
                return true
            }
            
            let isDeleting = range.length > 0 && string.count <= 0
            if isDeleting {
                //if NSMaxRange(range) > textField.text?.count ?? 0 {
                //  目前测试如果包含emoji的表情的话会删除不掉
                //       return false
                //                } else {
                return true
                //                }
            }
            
            let rangeLength = range.length
            if (textField.text?.count ?? 0) - rangeLength + string.count > temTextField.maximumTextLength {
                
                // 将要插入的文字裁剪成这么长，就可以让它插入了
                let substringLength = temTextField.maximumTextLength - (textField.text?.count ?? 0) + rangeLength
                if substringLength > 0 && (textField.text?.count ?? 0) > substringLength {
                    
                    let characterSequencesRange = (string as NSString).rangeOfComposedCharacterSequences(for: NSMakeRange(0, substringLength))
                    let allowedText = (string as NSString).substring(with: characterSequencesRange)
                    if allowedText.count <= substringLength {
                        textField.text = (textField.text! as NSString).replacingCharacters(in: range, with: allowedText)
                        textField.sendActions(for: UIControl.Event.editingChanged)
                        NotificationCenter.default.post(name: UITextField.textDidChangeNotification, object: textField)
                    }
                }
                return false
            }
            
            return true
        }
        
        
        /// UIScrollViewDelegate
        /// - Parameter scrollView: scrollView
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            
            // 以下代码修复系统的 UITextField 在 iOS 10 下的 bug
            guard let _ = self.textField?.subviews.first as? UIScrollView else {
                return
            }
            
            let paragraphStyle = textField?.defaultTextAttributes[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle
            let font = textField?.defaultTextAttributes[NSAttributedString.Key.font] as? UIFont
            let lineHeight = (paragraphStyle?.minimumLineHeight ?? 0) > 0 ? paragraphStyle?.minimumLineHeight : font?.lineHeight
            if scrollView.contentSize.height > ceil(lineHeight ?? 0) && scrollView.contentOffset.y < 0 {
                scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: 0)
            }
        }
    }
    
    
    /// 修改 placeholder 的颜色，默认是 UIColorPlaceholder
    public var placeholderColor: UIColor = UIColor(red: 196.0/255.0, green: 200.0/255.0, blue: 208.0/255.0, alpha: 1.0) {
        didSet {
            updateAttributedPlaceholderIfNeeded()
        }
    }
    
    /// 显示允许输入的最大文字长度，默认为 NSUIntegerMax，也即不限制长度
    public var maximumTextLength: Int = Int.max
    
    /// 当通过 `setText:`、`setAttributedText:`等方式修改文字时，是否应该自动触发 UIControlEventEditingChanged 事件及 UITextFieldTextDidChangeNotification 通知 默认为YES（注意系统的 UITextField 对这种行为默认是 NO）
    public var shouldResponseToProgrammaticallyTextChanges: Bool = true
    
    /// 格式类型
    public var formatterType = FormatterType.default
    
    /// 文字在输入框内的 padding。如果出现 clearButton，则 textInsets.right 会控制 clearButton 的右边距
    @objc public dynamic var textInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 7)
    
    /// clearButton 在默认位置上的偏移
    @objc public dynamic var clearButtonPositionAdjustment: UIOffset = UIOffset.zero
    
    /// 占位符
    open override var placeholder: String? {
        didSet {
            updateAttributedPlaceholderIfNeeded()
        }
    }
    
    /// 文本重写
    open override var text: String? {
        didSet {
            
            guard oldValue != self.text,
                  shouldResponseToProgrammaticallyTextChanges else {
                return
            }
            
            fireTextDidChangeEventForTextField()
        }
    }
    
    /// 富文本
    open override var attributedText: NSAttributedString? {
        didSet {
            
            guard oldValue != self.attributedText,
                  shouldResponseToProgrammaticallyTextChanges else {
                 return
            }
            
            fireTextDidChangeEventForTextField()
        }
    }
    
    /// delegator
    private lazy var delegator: TextFieldDelegator = {
        $0.textField = self
        addTarget($0, action: #selector($0.handleTextChangeEvent(_:)), for: UIControl.Event.editingChanged)
        return $0
    }(TextFieldDelegator())
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = delegator
    }
    
    
    /// 重写 textRect
    /// - Parameter bounds: bounds
    open override func textRect(forBounds bounds: CGRect) -> CGRect {
        
        var rect = bounds
        rect.origin.x += textInsets.left
        rect.origin.y += textInsets.top
        rect.size.width -= (textInsets.left + textInsets.right)
        rect.size.height -= (textInsets.top + textInsets.bottom)
        return super.textRect(forBounds: rect)
    }
    
    
    /// 重写 editingRect
    /// - Parameter bounds: bounds
    open override func editingRect(forBounds bounds: CGRect) -> CGRect {
        
        var rect = bounds
        rect.origin.x += textInsets.left
        rect.origin.y += textInsets.top
        rect.size.width -= (textInsets.left + textInsets.right)
        rect.size.height -= (textInsets.top + textInsets.bottom)
        return super.editingRect(forBounds: rect)
    }
    
    
    /// 重写 clearButtonRect
    /// - Parameter bounds: bounds
    open override func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        
        var result = super.clearButtonRect(forBounds: bounds)
        result = result.offsetBy(dx: clearButtonPositionAdjustment.horizontal, dy: clearButtonPositionAdjustment.vertical)
        return result
    }
    
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        // 以下代码修复系统的 UITextField 在 iOS 10 下的 bug
        if #available(iOS 10.0, *) {
            
            guard let scrollView = self.subviews.first as? UIScrollView,
                let _ = scrollView.delegate else {
                    return
            }
            
            scrollView.delegate = delegator
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// MARK - private func
extension XBTextField {
    
    /// 更新占位符属性
    private func updateAttributedPlaceholderIfNeeded() {
        
        guard let temPlaceholder = placeholder else {
            return
        }
        
        attributedPlaceholder = NSAttributedString(string: temPlaceholder,
                                                   attributes: [NSAttributedString.Key.foregroundColor : placeholderColor])
    }
    
    
    /// 文本改变通知
    private func fireTextDidChangeEventForTextField() {
        sendActions(for: UIControl.Event.editingChanged)
        NotificationCenter.default.post(name: UITextField.textDidChangeNotification, object: self)
    }
}
