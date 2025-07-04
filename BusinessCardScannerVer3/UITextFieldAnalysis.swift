import UIKit

/// UITextField 內部結構分析工具
/// 用於測量和了解 UITextField 的文字基線位置和內部間距
class UITextFieldAnalyzer {
    
    static func analyzeTextField() {
        let textField = UITextField()
        textField.frame = CGRect(x: 0, y: 0, width: 200, height: 48)
        textField.text = "Sample Text"
        textField.font = UIFont.systemFont(ofSize: 17) // iOS 預設字體大小
        
        print("=== UITextField 分析 ===")
        print("Frame height: \(textField.frame.height)")
        print("Content vertical alignment: \(textField.contentVerticalAlignment.rawValue)")
        print("Border style: \(textField.borderStyle.rawValue)")
        
        // 需要先將 textField 加入視圖層級才能獲得準確的佈局信息
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.addSubview(textField)
        textField.layoutIfNeeded()
        
        // 分析文字矩形
        let textRect = textField.textRect(forBounds: textField.bounds)
        print("\n文字矩形 (textRect):")
        print("- Origin: \(textRect.origin)")
        print("- Size: \(textRect.size)")
        print("- 距離頂部: \(textRect.origin.y)")
        print("- 距離底部: \(textField.frame.height - textRect.maxY)")
        
        // 分析編輯矩形
        let editingRect = textField.editingRect(forBounds: textField.bounds)
        print("\n編輯矩形 (editingRect):")
        print("- Origin: \(editingRect.origin)")
        print("- Size: \(editingRect.size)")
        
        // 分析佔位符矩形
        let placeholderRect = textField.placeholderRect(forBounds: textField.bounds)
        print("\n佔位符矩形 (placeholderRect):")
        print("- Origin: \(placeholderRect.origin)")
        print("- Size: \(placeholderRect.size)")
        
        // 分析字體度量
        if let font = textField.font {
            print("\n字體度量:")
            print("- Font size: \(font.pointSize)")
            print("- Line height: \(font.lineHeight)")
            print("- Ascender: \(font.ascender)")
            print("- Descender: \(font.descender)")
            print("- Cap height: \(font.capHeight)")
            print("- X-height: \(font.xHeight)")
            print("- Leading: \(font.leading)")
            
            // 計算基線位置
            let baselineFromTop = textRect.origin.y + font.ascender
            let baselineFromBottom = textField.frame.height - baselineFromTop
            print("\n基線位置:")
            print("- 從頂部到基線: \(baselineFromTop)")
            print("- 從底部到基線: \(baselineFromBottom)")
        }
        
        // 測試不同的 contentVerticalAlignment
        print("\n=== 不同 contentVerticalAlignment 的影響 ===")
        let alignments: [(UIControl.ContentVerticalAlignment, String)] = [
            (.center, "center"),
            (.top, "top"),
            (.bottom, "bottom"),
            (.fill, "fill")
        ]
        
        for (alignment, name) in alignments {
            textField.contentVerticalAlignment = alignment
            let rect = textField.textRect(forBounds: textField.bounds)
            print("\n\(name) alignment:")
            print("- Text rect origin.y: \(rect.origin.y)")
            print("- Text rect height: \(rect.height)")
            print("- 距離底部: \(textField.frame.height - rect.maxY)")
        }
        
        // 測試不同邊框樣式的影響
        print("\n=== 不同 borderStyle 的影響 ===")
        let borderStyles: [(UITextField.BorderStyle, String)] = [
            (.none, "none"),
            (.line, "line"),
            (.bezel, "bezel"),
            (.roundedRect, "roundedRect")
        ]
        
        textField.contentVerticalAlignment = .center // 恢復預設
        
        for (style, name) in borderStyles {
            textField.borderStyle = style
            let rect = textField.textRect(forBounds: textField.bounds)
            print("\n\(name) border style:")
            print("- Text rect: \(rect)")
            print("- 內邊距 top: \(rect.origin.y)")
            print("- 內邊距 bottom: \(textField.frame.height - rect.maxY)")
        }
    }
    
    /// 創建視覺化比較視圖
    static func createComparisonView() -> UIView {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        containerView.backgroundColor = .systemBackground
        
        // UITextField
        let textField = UITextField(frame: CGRect(x: 20, y: 20, width: 260, height: 48))
        textField.text = "UITextField Sample"
        textField.font = UIFont.systemFont(ofSize: 17)
        textField.borderStyle = .none
        textField.backgroundColor = UIColor.systemGray6
        
        // 添加底線到 UITextField
        let textFieldUnderline = UIView()
        textFieldUnderline.backgroundColor = .systemGray3
        textField.addSubview(textFieldUnderline)
        textFieldUnderline.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textFieldUnderline.leadingAnchor.constraint(equalTo: textField.leadingAnchor),
            textFieldUnderline.trailingAnchor.constraint(equalTo: textField.trailingAnchor),
            textFieldUnderline.bottomAnchor.constraint(equalTo: textField.bottomAnchor),
            textFieldUnderline.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        // UITextView（模擬 ThemedTextView）
        let textView = UITextView(frame: CGRect(x: 20, y: 88, width: 260, height: 48))
        textView.text = "UITextView Sample"
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.backgroundColor = UIColor.systemGray6
        textView.textContainerInset = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: -5) // 移除預設內邊距
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = false
        
        // 添加底線到 UITextView
        let textViewUnderline = UIView()
        textViewUnderline.backgroundColor = .systemGray3
        textView.addSubview(textViewUnderline)
        textViewUnderline.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textViewUnderline.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            textViewUnderline.trailingAnchor.constraint(equalTo: textView.trailingAnchor),
            textViewUnderline.bottomAnchor.constraint(equalTo: textView.bottomAnchor),
            textViewUnderline.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        containerView.addSubview(textField)
        containerView.addSubview(textView)
        
        // 添加標籤
        let textFieldLabel = UILabel(frame: CGRect(x: 20, y: 0, width: 100, height: 20))
        textFieldLabel.text = "UITextField"
        textFieldLabel.font = UIFont.systemFont(ofSize: 12)
        
        let textViewLabel = UILabel(frame: CGRect(x: 20, y: 68, width: 100, height: 20))
        textViewLabel.text = "UITextView"
        textViewLabel.font = UIFont.systemFont(ofSize: 12)
        
        containerView.addSubview(textFieldLabel)
        containerView.addSubview(textViewLabel)
        
        return containerView
    }
}

// 使用範例：
// UITextFieldAnalyzer.analyzeTextField()
// let comparisonView = UITextFieldAnalyzer.createComparisonView()