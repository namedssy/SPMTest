//
//  SFAppUpgradeView.swift
//  Merchant
//
//  Created by Shiyu Shao on 2020/3/2.
//  Copyright © 2020 Beijing SF Intra-city Technology Co., Ltd. All rights reserved.
//

import UIKit
import NXDesign

class SFAppUpgradeView: UIView, NXAlertable {
    
    /// 点击升级按钮回调
    public var upgradeBlock: (() -> Void)?
    /// 点击取消按钮回调
    public var cancelBlock: (() -> Void)?
    /// 视图数据
    private var node: SFAppUpgradeNode
    
    /// 顶部图片
    private lazy var topImageView: UIImageView = {
        let topImageView = UIImageView()
        topImageView.translatesAutoresizingMaskIntoConstraints = false
        topImageView.image = UIImage(named: "img_picture")
        return topImageView
    }()
    /// 标题
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = .hex("#000000")
        titleLabel.font = .sfMediumBoldFont(size: 20)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()
    /// 版本背景
    private lazy var versionView: UIView = {
        let versionView = UIView()
        versionView.backgroundColor = .hex("#222222")
        versionView.layer.cornerRadius = 3
        versionView.layer.masksToBounds = true
        versionView.translatesAutoresizingMaskIntoConstraints = false
        return versionView
    }()
    /// 版本文案
    private lazy var versionLabel: UILabel = {
        let versionLabel = UILabel()
        versionLabel.textColor = .white
        versionLabel.font = .sfMediumBoldFont(size: 11)
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        return versionLabel
    }()
    /// 内容滑动视图
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    /// 内容文案
    private lazy var contentLabel: UILabel = {
        let contentLabel = UILabel()
        contentLabel.textColor = .hex("#666666")
        contentLabel.font = .sfFont(size: 14)
        contentLabel.numberOfLines = 0
        contentLabel.preferredMaxLayoutWidth = 225
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        return contentLabel
    }()
    /// 升级按钮
    private lazy var upgradeButton: UIButton = {
        let upgradeButton = UIButton(type: .custom)
        upgradeButton.setTitleColor(.white, for: .normal)
        upgradeButton.titleLabel?.font = .sfMediumBoldFont(size: 16)
        upgradeButton.layer.cornerRadius = 2
        upgradeButton.layer.masksToBounds = true
        upgradeButton.translatesAutoresizingMaskIntoConstraints = false
        upgradeButton.addTarget(self, action: #selector(upgradeButtonClick), for: .touchUpInside)
        return upgradeButton
    }()
    /// 取消按钮
    private lazy var cancelButton: UIButton = {
        let cancelButton = UIButton(type: .custom)
        cancelButton.setTitle("暂不升级", for: .normal)
        cancelButton.setTitleColor(.hex("#999999"), for: .normal)
        cancelButton.titleLabel?.font = .sfFont(size: 14)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelButtonClick), for: .touchUpInside)
        return cancelButton
    }()
    /// 内容底下的渐变遮罩
    private lazy var gradientView: UIView = {
        let gradientView = UIView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        return gradientView
    }()
    
    /// 初始化方法
    /// - Parameter node: 视图数据
    init(node: SFAppUpgradeNode) {
        self.node = node
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = 10
        layer.masksToBounds = true
        //设置数据
        setupNode()
        //初始化子控件
        initSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard case let window?? = UIApplication.shared.delegate?.window else { return }
        center = CGPoint(x: window.frame.midX, y: window.frame.height * 0.44)
        upgradeButton.addGradient(colors: [.hex("#FF7901"), .hex("#F11412")], direction: .leftToRight, locations: nil)
        gradientView.addGradient(colors: [UIColor.white.withAlphaComponent(0), UIColor.white], direction: .topToBottom, locations: nil)
    }
    
    // MARK: - UI
    
    /// 初始化子控件
    private func initSubviews() {
        self.translatesAutoresizingMaskIntoConstraints = false
        let height = (contentLabel.text?.height(font: .sfFont(size: 14), maxWidth: 285 - 60) ?? 0) + 10
        //顶部图片
        addSubview(topImageView)
        let topImageViewTop = NSLayoutConstraint(item: topImageView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
        let topImageViewLeading = NSLayoutConstraint(item: topImageView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0)
        let topImageViewTrailing = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: topImageView, attribute: .trailing, multiplier: 1, constant: 0)
        let topImageViewHeight = NSLayoutConstraint(item: topImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 100)
        let topImageViewWidth = NSLayoutConstraint(item: topImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 285)
        NSLayoutConstraint.activate([topImageViewTop, topImageViewLeading, topImageViewTrailing, topImageViewHeight, topImageViewWidth])
        //标题
        addSubview(titleLabel)
        let titleLabelTop = NSLayoutConstraint(item: titleLabel, attribute: .top, relatedBy: .equal, toItem: topImageView, attribute: .bottom, multiplier: 1, constant: 25)
        let titleLabelLeading = NSLayoutConstraint(item: titleLabel, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 30)
        NSLayoutConstraint.activate([titleLabelTop, titleLabelLeading])
        //版本号背景
        addSubview(versionView)
        let versionViewCenterY = NSLayoutConstraint(item: versionView, attribute: .centerY, relatedBy: .equal, toItem: titleLabel, attribute: .centerY, multiplier: 1, constant: 0)
        let versionViewLeading = NSLayoutConstraint(item: versionView, attribute: .leading, relatedBy: .equal, toItem: titleLabel, attribute: .trailing, multiplier: 1, constant: 5)
        NSLayoutConstraint.activate([versionViewCenterY, versionViewLeading])
        //版本号
        addSubview(versionLabel)
        let versionLabelTop = NSLayoutConstraint(item: versionLabel, attribute: .top, relatedBy: .equal, toItem: versionView, attribute: .top, multiplier: 1, constant: 0.5)
        let versionLabelBottom =  NSLayoutConstraint(item: versionLabel, attribute: .bottom, relatedBy: .equal, toItem: versionView, attribute: .bottom, multiplier: 1, constant: -0.5)
        let versionLabelLeading = NSLayoutConstraint(item: versionLabel, attribute: .leading, relatedBy: .equal, toItem: versionView, attribute: .leading, multiplier: 1, constant: 4)
        let versionLabelTrailing = NSLayoutConstraint(item: versionLabel, attribute: .trailing, relatedBy: .equal, toItem: versionView, attribute: .trailing, multiplier: 1, constant: -4)
        NSLayoutConstraint.activate([versionLabelTop, versionLabelBottom, versionLabelLeading, versionLabelTrailing])
        //内容滑动视图
        addSubview(scrollView)
        let scrollViewTop = NSLayoutConstraint(item: scrollView, attribute: .top, relatedBy: .equal, toItem: titleLabel, attribute: .bottom, multiplier: 1, constant: 10)
        let scorllViewLeading = NSLayoutConstraint(item: scrollView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 30)
        let scrollViewTrailing = NSLayoutConstraint(item: scrollView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -30)
        var scrollViewHeight: NSLayoutConstraint?
        if height > 140 {
            scrollViewHeight = NSLayoutConstraint(item: scrollView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 140)
            NSLayoutConstraint.activate([scrollViewTop, scorllViewLeading, scrollViewTrailing, scrollViewHeight!])
            //内容底下的渐变遮罩
            addSubview(gradientView)
            let gradientViewBottom = NSLayoutConstraint(item: gradientView, attribute: .bottom, relatedBy: .equal, toItem: scrollView, attribute: .bottom, multiplier: 1, constant: 0)
            let gradientViewLeading = NSLayoutConstraint(item: gradientView, attribute: .leading, relatedBy: .equal, toItem: scrollView, attribute: .leading, multiplier: 1, constant: 0)
            let gradientViewTrailing = NSLayoutConstraint(item: gradientView, attribute: .trailing, relatedBy: .equal, toItem: scrollView, attribute: .trailing, multiplier: 1, constant: 0)
            let gradientViewHeight = NSLayoutConstraint(item: gradientView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 15)
            NSLayoutConstraint.activate([gradientViewBottom, gradientViewLeading, gradientViewTrailing, gradientViewHeight])
        } else {
            scrollViewHeight = NSLayoutConstraint(item: scrollView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: height)
            NSLayoutConstraint.activate([scrollViewTop, scorllViewLeading, scrollViewTrailing, scrollViewHeight!])
        }
        //内容
        scrollView.addSubview(contentLabel)
        let contentLabelTop = NSLayoutConstraint(item: contentLabel, attribute: .top, relatedBy: .equal, toItem: scrollView, attribute: .top, multiplier: 1, constant: 0)
        let contentLabelLeading = NSLayoutConstraint(item: contentLabel, attribute: .leading, relatedBy: .equal, toItem: scrollView, attribute: .leading, multiplier: 1, constant: 0)
        let contentLabelTrailing = NSLayoutConstraint(item: contentLabel, attribute: .trailing, relatedBy: .equal, toItem: scrollView, attribute: .trailing, multiplier: 1, constant: 0)
        let contentLabelBottom = NSLayoutConstraint(item: contentLabel, attribute: .bottom, relatedBy: .equal, toItem: scrollView, attribute: .bottom, multiplier: 1, constant: -10)
        NSLayoutConstraint.activate([contentLabelTop, contentLabelLeading, contentLabelTrailing, contentLabelBottom])
        //升级按钮
        addSubview(upgradeButton)
        let upgradeButtonTop = NSLayoutConstraint(item: upgradeButton, attribute: .top, relatedBy: .equal, toItem: scrollView, attribute: .bottom, multiplier: 1, constant: 20)
        let upgradeButtonLeading = NSLayoutConstraint(item: upgradeButton, attribute: .leading, relatedBy: .equal, toItem: scrollView, attribute: .leading, multiplier: 1, constant: 0)
        let upgradeButtonTrailing = NSLayoutConstraint(item: upgradeButton, attribute: .trailing, relatedBy: .equal, toItem: scrollView, attribute: .trailing, multiplier: 1, constant: 0)
        let upgradeButtonHeight = NSLayoutConstraint(item: upgradeButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 36)
        NSLayoutConstraint.activate([upgradeButtonTop, upgradeButtonLeading, upgradeButtonTrailing, upgradeButtonHeight])
        var bottom: NSLayoutConstraint?
        if node.isShowCancelButton ?? false {
            //取消按钮
            addSubview(cancelButton)
            let cancelButtonTop = NSLayoutConstraint(item: cancelButton, attribute: .top, relatedBy: .equal, toItem: upgradeButton, attribute: .bottom, multiplier: 1, constant: 15)
            let cancelButtonCenterX = NSLayoutConstraint(item: cancelButton, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
            let cancelButtonHeight = NSLayoutConstraint(item: cancelButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 20)
            bottom = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: cancelButton, attribute: .bottom, multiplier: 1, constant: 15)
            NSLayoutConstraint.activate([cancelButtonTop, cancelButtonCenterX, bottom!, cancelButtonHeight])
        } else {
            bottom = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: upgradeButton, attribute: .bottom, multiplier: 1, constant: 20)
            NSLayoutConstraint.activate([bottom!])
        }
    }
}

// MARK: - Data

extension SFAppUpgradeView {
    
    /// 设置数据
    private func setupNode() {
        //标题
        titleLabel.text = node.title
        //版本号
        versionLabel.text = node.version
        //内容
        contentLabel.text = node.content
        //升级按钮文案
        upgradeButton.setTitle(node.upgradeButtonTitle, for: .normal)
    }
}

// MARK: - Action

extension SFAppUpgradeView {
    
    /// 升级按钮点击方法
    @objc private func upgradeButtonClick() {
        upgradeBlock?()
    }
    
    /// 取消按钮点击方法
    @objc private func cancelButtonClick() {
        cancelBlock?()
        dismiss()
    }
}

private enum SFFontName: String {
    case chiRegular = "PingFangSC-Regular"
    case chiSemiBold = "PingFangSC-Semibold"
    case chiMediumBold = "PingFangSC-Medium"
}

private extension UIFont {
    static func sfFont(size: CGFloat) -> UIFont {
        return internalFont(name: SFFontName.chiRegular.rawValue, size: size)
    }
    
    static func sfMediumBoldFont(size: CGFloat) -> UIFont {
        return internalFont(name: SFFontName.chiMediumBold.rawValue, size: size)
    }
    
    static func sfBoldFont(size: CGFloat) -> UIFont {
        return internalFont(name: SFFontName.chiSemiBold.rawValue, size: size)
    }
    
    private static func internalFont(name: String, size: CGFloat) -> UIFont {
        if let font = UIFont(name: name, size: size) {
            return font
        }
        return UIFont.systemFont(ofSize: size)
    }
}

