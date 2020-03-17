//
//  SFAppUpgradeViewModel.swift
//  Merchant
//
//  Created by Shiyu Shao on 2020/3/4.
//  Copyright © 2020 Beijing SF Intra-city Technology Co., Ltd. All rights reserved.
//

import UIKit
import SFFoundation

struct SFAppUpgradeViewModel {
    
    /// 创建视图数据
    /// - Parameter model: 业务数据
    public func createNode(model: SFAppUpgraderModel) -> SFAppUpgradeNode {
        let node = SFAppUpgradeNode(model: model)
        return node
    }
}

/// 试图数据
struct SFAppUpgradeNode {
    /// 升级类型枚举
    enum upgradeType {
        /// 强制升级
        case force
        /// 非强制升级
        case unForce
        /// 灰测
        case testFlight
    }
    var model: SFAppUpgraderModel?
    /// 升级类型
    var type: upgradeType?
    /// 标题
    var title: String?
    /// 版本号
    var version: String?
    /// 升级内容
    var content: String?
    /// 升级按钮文案
    var upgradeButtonTitle: String?
    /// 是否显示“暂不升级”按钮
    var isShowCancelButton: Bool?
    
    init(model: SFAppUpgraderModel) {
        self.model = model
        if model.type == "3" {
            type = .testFlight
            upgradeButtonTitle = "立即体验"
            isShowCancelButton  = true
        } else {
            if model.is_force == "1" {
                type = .force
                upgradeButtonTitle = "立即升级"
                isShowCancelButton  = false
            } else {
                type = .unForce
                upgradeButtonTitle = "立即升级"
                isShowCancelButton  = true
            }
        }
        title = model.title
        version = model.version
        content = checkStringLineBreak(str: ToStr(model.content))
    }
    
    private func checkStringLineBreak(str: String) -> String {
        return str.replacingOccurrences(of: "<br>", with: "\n")
    }
}
