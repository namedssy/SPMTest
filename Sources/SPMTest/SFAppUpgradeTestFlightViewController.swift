//
//  SFAppUpgradeTestFlightViewController.swift
//  Merchant
//
//  Created by Shiyu Shao on 2020/3/5.
//  Copyright © 2020 Beijing SF Intra-city Technology Co., Ltd. All rights reserved.
//

import UIKit
import NXDesign
import SFFoundation

class SFAppUpgradeTestFlightViewController: NXViewController, StoryboardLoadable {
    static var fileInfo: StoryboardFileInfo = .init(name: "TestFlight", identifier: "TestFlight", bundle: Bundle(for: SFAppUpgradeTestFlightViewController.self))
    
    public var model: SFAppUpgraderModel?
    @IBOutlet weak var appIconImageView: UIImageView!
    @IBOutlet weak var appNameLabel: UILabel!
    var iconImage: UIImage?
    var isHaveNavigation = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.nxNavigationBar.titleLabel.text = "获取尝鲜版"
        self.nxNavigationBar.shadowHidden = true
        if isHaveNavigation == false {
            nxNavigationBar.showCloseBarButton = true
            nxNavigationBar.closeBarButtonBlock = {[weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
        }
        appNameLabel.text = Device.appName
        appIconImageView.image = iconImage
    }
}

// MARK: - Action

extension SFAppUpgradeTestFlightViewController {
    
    /// 点击下载TestFlight按钮
    @IBAction func testFlightDownloadButtonClick(_ sender: Any) {
        if SFAppUpgrader.shared.checkTestFlight() {
            NXToast.show(text: "已安装")
        } else {
            SFAppUpgrader.shared.downloadTestFlightApp()
        }
    }
    
    /// 点击下载app按钮
    @IBAction func appDownloadButtonClick(_ sender: Any) {
        if SFAppUpgrader.shared.checkTestFlight() {
            SFAppUpgrader.shared.downloadApp(urlString: model?.testFlightURL)
        } else {
            NXToast.show(text: "请先安装TestFlight")
        }
    }
}
