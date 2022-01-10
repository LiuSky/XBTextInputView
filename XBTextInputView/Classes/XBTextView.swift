//
//  XBTextView.swift
//  XBTextInputView_Example
//
//  Created by xiaobin liu on 2020/3/16.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit


/// MARK - XBTextViewDelegate
@objc public protocol XBTextViewDelegate: UITextViewDelegate {
    
    /**
     *  输入框高度发生变化时的回调，仅当 `autoResizable` 属性为 YES 时才有效。
     *  @note 只有当内容高度与当前输入框的高度不一致时才会调用到这里，所以无需在内部做高度是否变化的判断。
     */
    @objc optional func textView(_ textView: XBTextView,
                                 newHeightAfterTextChanged height: CGFloat) -> Void
    
    /**
     *  用户点击键盘的 return 按钮时的回调（return 按钮本质上是输入换行符“\n”）
     *  @return 返回 YES 表示程序认为当前的点击是为了进行类似“发送”之类的操作，所以最终“\n”并不会被输入到文本框里。返回 NO 表示程序认为当前的点击只是普通的输入，所以会继续询问 textView(_:shouldChangeTextIn:replacementText:) 方法，根据该方法的返回结果来决定是否要输入这个“\n”。
     *  @see maximumTextLength
     */
    @objc optional func textViewShouldReturn(_ textView: XBTextView) -> Bool
    
    /**
     *  配合 `maximumTextLength` 属性使用，在输入文字超过限制时被调用。例如如果你的输入框在按下键盘“Done”按键时做一些发送操作，就可以在这个方法里判断 replacementText. isEqualToString:@"\n"]。
     *  @warning 在 textViewDidChange(_:) 里也会触发文字长度拦截，由于此时 textView 的文字已经改变完，所以无法得知发生改变的文本位置及改变的文本内容，所以此时 range 和 replacementText 这两个参数的值也会比较特殊，具体请看参数讲解。
     *
     *  @param textView 触发的 textView
     *  @param range 要变化的文字的位置，如果在 textViewDidChange(_:) 里，这里的 range 也即文字变化后的 range，所以可能比最大长度要大。
     *  @param replacementText 要变化的文字，如果在 textViewDidChange(_:) 里，这里永远传入 nil。
     */
    @objc optional func textView(_ textView: XBTextView,
                                 didPreventTextChangeInRange range: NSRange,
                                 replacementText: String?) -> Void
}

/// 系统 textView 默认的字号大小，用于 placeholder 默认的文字大小。实测得到，请勿修改。
private let kSystemTextViewDefaultFontPointSize: CGFloat = 12.0

/// 当系统的 textView.textContainerInset 为 UIEdgeInsets.zero 时，文字与 textView 边缘的间距。实测得到，请勿修改（在输入框font大于13时准确，小于等于12时，y有-1px的偏差）。
private let kSystemTextViewFixTextInsets: UIEdgeInsets = UIEdgeInsets.init(top: 0, left: 5, bottom: 0, right: 5)


/// MARK - XBTextView
@objcMembers
open class XBTextView: UITextView {
    
    /// 当通过 `setText:`、`setAttributedText:`等方式修改文字时，是否应该自动触发 `UITextViewDelegate` 里的 `textView:shouldChangeTextInRange:replacementText:`、 `textViewDidChange:` 方法
    // 默认为YES（注意系统的 UITextView 对这种行为默认是 NO）
    public var shouldResponseToProgrammaticallyTextChanges: Bool = true
    
    /// 显示允许输入的最大文字长度，默认为 Int.max，也即不限制长度
    public var maximumTextLength: UInt = UInt.max
    
    /// 占位符
    public var placeholder: String? {
        didSet {
            placeholderLabel.attributedText = NSAttributedString(string: placeholder ?? "", attributes: typingAttributes)
            placeholderLabel.textColor = placeholderColor
            sendSubviewToBack(placeholderLabel)
            setNeedsLayout()
        }
    }
    
    /// 占位符颜色
    public var placeholderColor: UIColor = UIColor(red: 196.0/255.0, green: 200.0/255.0, blue: 208.0/255.0, alpha: 1.0)
    
    /// placeholder 在默认位置上的偏移（默认位置会自动根据 textContainerInset、contentInset 来调整）
    public var placeholderMargins: UIEdgeInsets = UIEdgeInsets.zero
    
    /**
     *  是否支持自动拓展高度，默认为 false
     *  @see textView(_:newHeightAfterTextChanged:)
     */
    public var autoResizable: Bool = false
    
    /// 格式类型
    public var formatterType = FormatterType.default
    
    /// 占位符标签
    private lazy var placeholderLabel: UILabel = {
        $0.font = UIFont.systemFont(ofSize: kSystemTextViewDefaultFontPointSize)
        $0.textColor = placeholderColor
        $0.numberOfLines = 0
        $0.alpha = 0
        return $0
    }(UILabel())
    
    /// 原始委托
    private weak var originalDelegate: XBTextViewDelegate?
    
    /// 当前文本
    private var currentString: String?
    
    /// 初始化
    convenience init() {
        self.init(frame: CGRect.zero, textContainer: nil)
    }
    
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        didInitialized()
    }
    
    
    /// didInitialized
    private func didInitialized() {
        delegate = self
        scrollsToTop = false
        
        if #available(iOS 11, *) {
            contentInsetAdjustmentBehavior = .never
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleTextChanged(_:)), name: UITextView.textDidChangeNotification, object: nil)
        configView()
    }
    
    /// 配置视图
    private func configView() {
        addSubview(placeholderLabel)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// MARK - override
extension XBTextView {
    
    /// 设置文本
    open override var text: String! {
        get {
            return super.text
        }
        set {
            
            let textBeforeChange = self.text ?? ""
            let textDifferent = isCurrentTextDifferentOfText(newValue)
            
            // 如果前后文字没变化，则什么都不做
            if !textDifferent {
                super.text = newValue
                return
            }
            
            // 前后文字发生变化，则要根据是否主动接管 delegate 来决定是否要询问 delegate
            if shouldResponseToProgrammaticallyTextChanges {
                
                let shouldChangeText = delegate?.textView?(self, shouldChangeTextIn: NSMakeRange(0, textBeforeChange.count), replacementText: newValue ?? "") ?? true
                
                if !shouldChangeText {
                    // 不应该改变文字，所以连 super 都不调用，直接结束方法
                    return
                }
                
                // 应该改变文字，则调用 super 来改变文字，然后主动调用 textViewDidChange:
                super.text = newValue
                
                delegate?.textViewDidChange?(self)
                
                NotificationCenter.default.post(name: UITextView.textDidChangeNotification, object: self)
            } else {
                super.text = newValue
                
                // 如果不需要主动接管事件，则只要触发内部的监听即可，不用调用 delegate 系列方法
                handleTextChanged(self)
            }
        }
    }
    
    /// 重写 attributedText 的 setter 方法
    open override var attributedText: NSAttributedString! {
        get {
            return super.attributedText
        }
        set {
            let textBeforeChange = self.attributedText.string
            let textDifferent = isCurrentTextDifferentOfText(newValue.string)
            
            // 如果前后文字没变化，则什么都不做
            if !textDifferent {
                super.attributedText = newValue
                return
            }
            
            // 前后文字发生变化，则要根据是否主动接管 delegate 来决定是否要询问 delegate
            if shouldResponseToProgrammaticallyTextChanges {
                let shouldChangeText = delegate?.textView?(self, shouldChangeTextIn: NSMakeRange(0, textBeforeChange.count), replacementText: newValue.string) ?? true
                
                if !shouldChangeText {
                    // 不应该改变文字，所以连 super 都不调用，直接结束方法
                    return
                }
                
                // 应该改变文字，则调用 super 来改变文字，然后主动调用 textViewDidChange:
                super.attributedText = newValue
                
                delegate?.textViewDidChange?(self)
                
                NotificationCenter.default.post(name: UITextView.textDidChangeNotification, object: self)
            } else {
                super.attributedText = newValue
                
                // 如果不需要主动接管事件，则只要触发内部的监听即可，不用调用 delegate 系列方法
                handleTextChanged(self)
            }
        }
    }
    
    /// 重写 typingAttributes 的 setter 方法
    open override var typingAttributes: [NSAttributedString.Key: Any] {
        get {
            return super.typingAttributes
        }
        set {
            super.typingAttributes = newValue
            updatePlaceholderStyle()
        }
    }
    
    /// 重写 font
    open override var font: UIFont? {
        didSet {
            updatePlaceholderStyle()
        }
    }
    
    /// 重写 textColor
    open override var textColor: UIColor? {
        didSet {
            updatePlaceholderStyle()
        }
    }
    
    /// 重写 textAlignment
    open override var textAlignment: NSTextAlignment {
        didSet {
            updatePlaceholderStyle()
        }
    }
    
    /// 重写 textContainerInset
    open override var textContainerInset: UIEdgeInsets {
        didSet {
            
            if #available(iOS 11, *) {
                // do thing
            } else {
                // iOS 11 以下修改 textContainerInset 的时候无法自动触发 layoutSubview，导致 placeholderLabel 无法更新布局
                setNeedsLayout()
            }
        }
    }
    
    /// 重写 delegate
    open override var delegate: UITextViewDelegate? {
        get {
            return super.delegate
        }
        set {
            if newValue as? NSObject != self {
                originalDelegate = newValue as? XBTextViewDelegate
            } else {
                originalDelegate = nil
            }
            if newValue != nil {
                super.delegate = self
            } else {
                super.delegate = nil
            }
        }
    }
    
    /// 重新绘制
    /// - Parameter rect: rect
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        updatePlaceholderLabelHidden()
    }
    
    /// 重新布局
    open override func layoutSubviews() {
        super.layoutSubviews()
        if placeholder?.count ?? 0 > 0 {
            
            let labelMargins = merge(merge(textContainerInset, placeholderMargins), kSystemTextViewFixTextInsets)
            let limitWidth = bounds.width - (contentInset.left + contentInset.right) - (labelMargins.left + labelMargins.right)
            let limitHeight = bounds.height - (contentInset.top + contentInset.bottom) - (labelMargins.top + labelMargins.bottom)
            var labelSize = placeholderLabel.sizeThatFits(CGSize(width: limitWidth, height: limitHeight))
            labelSize.height = min(labelSize.height, limitHeight)
            placeholderLabel.frame = CGRect(x: labelMargins.left, y: labelMargins.top, width: limitWidth, height: labelSize.height)
        }
    }
}

/// MARK - private func
extension XBTextView {
    
    @objc
    private func handleTextChanged(_ sender: AnyObject) {
        
        // 输入字符的时候，placeholder隐藏
        if placeholder?.count ?? 0 > 0 {
            updatePlaceholderLabelHidden()
        }
        
        var textView: XBTextView?
        
        if sender is Notification {
            let object = (sender as! Notification).object
            if object is XBTextView {
                textView = object as? XBTextView
            }
        } else if sender is XBTextView {
            textView = sender as? XBTextView
        }
        
        if textView != nil {
            // 计算高度
            if autoResizable {
                let resultHeight = textView!.sizeThatFits(CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)).height
                
                // 通知delegate去更新textView的高度
                textView?.originalDelegate?.textView?(self, newHeightAfterTextChanged: resultHeight)
            }
            
            // textView 尚未被展示到界面上时，此时过早进行光标调整会计算错误
            if textView?.window == nil {
                return
            }
        }
    }
    
    /// 更新占位符是否显示隐藏
    private func updatePlaceholderLabelHidden() {
        
        if text.count == 0 && placeholder?.count ?? 0 > 0 {
            placeholderLabel.alpha = 1
        } else {
            placeholderLabel.alpha = 0 // 用alpha来让placeholder隐藏，从而尽量避免因为显隐 placeholder 导致 layout
        }
    }
    
    /// 合并UIEdgeInsets
    /// - Parameters:
    ///   - edge1: formEdge
    ///   - edge2: toEdge
    private func merge(_ edge1: UIEdgeInsets, _ edge2: UIEdgeInsets) -> UIEdgeInsets {
        
        var edge = edge1
        edge.top += edge2.top
        edge.bottom += edge2.bottom
        edge.left += edge2.left
        edge.right += edge2.right
        return edge
    }
    
    /// 当前文本与文本不同
    /// - Parameter text: 文本
    private func isCurrentTextDifferentOfText(_ text: String?) -> Bool {
        
        let textBeforeChange = self.text // UITextView 如果文字为空，self.text 永远返回 @"" 而不是 nil（即便你设置为 nil 后立即 get 出来也是）
        if textBeforeChange == text || (textBeforeChange?.count == 0 && text == nil) {
            return false
        } else {
            return true
        }
    }
    
    /// 更新PlaceholderStyle
    private func updatePlaceholderStyle() {
        let placeholder = self.placeholder
        self.placeholder = placeholder // 触发文字样式的更新
    }
}

/// MARK - UITextViewDelegate
extension XBTextView: UITextViewDelegate {
    
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if text == "\n" {
            let shouldReturn = originalDelegate?.textViewShouldReturn?(self) ?? false
            if shouldReturn {
                return false
            }
        }
        
        if maximumTextLength < UInt.max {
            
            // 如果是中文输入法正在输入拼音的过程中（markedTextRange 不为 nil），是不应该限制字数的（例如输入“huang”这5个字符，其实只是为了输入“黄”这一个字符），所以在 shouldChange 这里不会限制，而是放在 didChange 那里限制。
            if textView.markedTextRange != nil {
                return true
            }
            
            let isDeleting = range.length > 0 && text.count <= 0
            if isDeleting {
                return true
            }
            
            let rangeLength = textView.text.substring(with: range).count
            let textWillOutofMaximumTextLength = textView.text.count - rangeLength +
                text.count > maximumTextLength
            if textWillOutofMaximumTextLength {
                
                // 当输入的文本达到最大长度限制后，此时继续点击 return 按钮（相当于尝试插入“\n”），就会认为总文字长度已经超过最大长度限制，所以此次 return 按钮的点击被拦截，外界无法感知到有这个 return 事件发生，所以这里为这种情况做了特殊保护
                if textView.text.count - rangeLength == maximumTextLength && text == "\n" {
                    originalDelegate?.textView?(self, didPreventTextChangeInRange: range, replacementText: text)
                    return false
                }
                
                // 将要插入的文字裁剪成多长，就可以让它插入了
                let substringLength = Int(maximumTextLength) - textView.text.count + rangeLength
                if substringLength > 0 && text.count > substringLength {
                    let characterSequencesRange = (text as NSString).rangeOfComposedCharacterSequences(for: NSMakeRange(0, substringLength))
                    let allowedText = (text as NSString).substring(with: characterSequencesRange)
                    if allowedText.count <= substringLength {
                        textView.text = (textView.text as NSString).replacingCharacters(in: range, with: allowedText)
                        let location = range.location + Int(substringLength)
                        textView.selectedRange = NSMakeRange(location, 0)
                        if !shouldResponseToProgrammaticallyTextChanges {
                            originalDelegate?.textViewDidChange!(textView)
                        }
                    }
                }
                
                originalDelegate?.textView?(self, didPreventTextChangeInRange: range, replacementText: text)
                return false
            }
            
        }
        return true
    }
    
    
    public func textViewDidChange(_ textView: UITextView) {
        
        // 1、iOS 10 以下的版本，从中文输入法的候选词里选词输入，是不会走到 textView:shouldChangeTextInRange:replacementText: 的，所以要在这里截断文字
        // 2、如果是中文输入法正在输入拼音的过程中（markedTextRange 不为 nil），是不应该限制字数的（例如输入“huang”这5个字符，其实只是为了输入“黄”这一个字符），所以在 shouldChange 那边不会限制，而是放在 didChange 这里限制。
        guard textView.markedTextRange == nil else {
            return
        }
        
        if (textView.text as NSString).length > maximumTextLength {
            textView.text = (textView.text as NSString).substring(to: Int(maximumTextLength))
            // 如果是在这里被截断，是无法得知截断前光标所处的位置及要输入的文本的，所以只能将当前的 selectedRange 传过去，而 replacementText 为 nil
            originalDelegate?.textView?(self, didPreventTextChangeInRange: textView.selectedRange, replacementText: nil)
        }
        
        guard let regexString = formatterType.regexString else {
            return
        }
        
        let predicate = NSPredicate(format: "SELF MATCHES %@", regexString)
        if !(predicate.evaluate(with: text) || text.count <= 0) {
            textView.text = currentString
        } else {
            currentString = textView.text
        }
        
        if shouldResponseToProgrammaticallyTextChanges {
            return
        }
        
        originalDelegate?.textViewDidChange?(textView)
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        originalDelegate?.textViewDidBeginEditing?(textView)
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        originalDelegate?.textViewDidEndEditing?(textView)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        originalDelegate?.scrollViewDidScroll?(scrollView)
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        originalDelegate?.scrollViewDidZoom?(scrollView)
    }
}
