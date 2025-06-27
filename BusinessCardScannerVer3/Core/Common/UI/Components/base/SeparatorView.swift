import UIKit
import SnapKit

/// 分隔線視圖元件
/// 提供統一的分隔線樣式，並能自動適應 UIStackView 和一般 UIView 的佈局
class SeparatorView: ThemedView {
    
    // MARK: - Types
    
    enum Orientation {
        case horizontal
        case vertical
    }
    
    // MARK: - UI Components
    
    /// 內部的線條視圖，這是真正可見的部分
    private let lineView = UIView()
    
    // MARK: - Properties
    
    var orientation: Orientation = .horizontal {
        didSet {
            updateLineViewConstraints()
        }
    }
    
    var thickness: CGFloat = AppTheme.Layout.separatorHeight {
        didSet {
            updateLineViewConstraints()
        }
    }
    
    /// 分隔線顏色
    /// 注意：現在我們設定的是 lineView 的顏色
    var lineColor: UIColor? {
        get { lineView.backgroundColor }
        set { lineView.backgroundColor = newValue }
    }
    
    var insets: UIEdgeInsets = .zero {
        didSet {
            updateLineViewConstraints()
        }
    }
    
    // MARK: - Initialization
    
    convenience init(orientation: Orientation = .horizontal,
                     thickness: CGFloat = AppTheme.Layout.separatorHeight,
                     insets: UIEdgeInsets = .zero) {
        self.init(frame: .zero)
        self.orientation = orientation
        self.thickness = thickness
        self.insets = insets
        
        // 初始化後，手動更新一次約束
        updateLineViewConstraints()
    }
    
    // MARK: - Setup
    
    override func setupView() {
        // 容器本身設為透明
        super.backgroundColor = .clear
        
        // 設定線條的預設顏色
        lineView.backgroundColor = AppTheme.Colors.separator
        addSubview(lineView)
    }
    
    override func setupConstraints() {
        // 約束將在 updateLineViewConstraints 中動態設定
    }
    
    // MARK: - Private Methods
    
    /// 更新內部 lineView 的約束
    /// 這是新的核心邏輯
    private func updateLineViewConstraints() {
        lineView.snp.remakeConstraints { make in
            switch orientation {
            case .horizontal:
                // 線條的高度等於厚度
                make.height.equalTo(thickness)
                // 線條在容器內垂直居中
                make.centerY.equalToSuperview()
                // 線條根據 insets 在水平方向上對齊容器
                make.left.equalToSuperview().inset(insets.left)
                make.right.equalToSuperview().inset(insets.right)
                
            case .vertical:
                // 線條的寬度等於厚度
                make.width.equalTo(thickness)
                // 線條在容器內水平居中
                make.centerX.equalToSuperview()
                // 線條根據 insets 在垂直方向上對齊容器
                make.top.equalToSuperview().inset(insets.top)
                make.bottom.equalToSuperview().inset(insets.bottom)
            }
        }
    }
    
    // MARK: - Override
    
    /// 覆寫內在內容大小
    /// 這個尺寸是給外部容器（如 UIStackView）參考的
    /// 它描述的是外層透明容器的尺寸
    override var intrinsicContentSize: CGSize {
        switch orientation {
        case .horizontal:
            // 水平分隔線，內在高貴為 thickness，寬度無限（由父視圖決定）
            return CGSize(width: UIView.noIntrinsicMetric, height: thickness)
        case .vertical:
            // 垂直分隔線，內在寬度為 thickness，高度無限（由父視圖決定）
            return CGSize(width: thickness, height: UIView.noIntrinsicMetric)
        }
    }
    
    // 為了向下相容或避免混淆，我們將 backgroundColor 的設定轉發給 lineView
    override var backgroundColor: UIColor? {
        get { return lineView.backgroundColor }
        set { lineView.backgroundColor = newValue }
    }
    
    // MARK: - Convenience Factory Methods (維持不變)
    
    static func horizontal(thickness: CGFloat = AppTheme.Layout.separatorHeight,
                          insets: UIEdgeInsets = .zero) -> SeparatorView {
        return SeparatorView(orientation: .horizontal, thickness: thickness, insets: insets)
    }
    
    static func vertical(thickness: CGFloat = AppTheme.Layout.separatorHeight,
                        insets: UIEdgeInsets = .zero) -> SeparatorView {
        return SeparatorView(orientation: .vertical, thickness: thickness, insets: insets)
    }
    
    static func listSeparator(leftInset: CGFloat = AppTheme.Layout.separatorLeftInset) -> SeparatorView {
        return horizontal(insets: UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: 0))
    }
    
    static func fullWidth() -> SeparatorView {
        return horizontal()
    }
}
