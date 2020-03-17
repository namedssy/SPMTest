//
//  SFAppUpgrader.swift
//  SFAppUpgrader
//
//  Created by 孔六五 on 2018/10/26.
//  Copyright © 2018 Beijing SF Intra-city Technology Co., Ltd. All rights reserved.
//

import SFFoundation
import NXDesign
/**
 升级方式 每次app切换到前台会执行一次升级检测流程
 - enum:
    - limitStrategy: 限制策略方式；
        - Parameters:
            - netInterval: 访问服务端版本信息的最小间隔时间
            - alertInterval: 非强制升级时，alert弹框弹起的最小间隔时间
            - testFlightAlertInterval: TestFlight升级时，alert弹窗弹起的最小间隔
 */
public enum SFAppUpgraderType {
    case limitStrategy(netInterval: TimeInterval, alertInterval: TimeInterval, testFlightAlertInterval: TimeInterval)
}

private let kSFAppUpgraderLastNetKey = "kSFAppUpgraderLastNetKey"
private let kSFAppUpgraderLastAleatKey = "kSFAppUpgraderLastAleatKey"
private let kSFAppUpgraderTestFlightLastAlertKey = "appUpgraderTestFlightLastAlertKey"

class SFAppUpgraderConfig {
    /// 操作系统版本
    var osv: String?
    /// 设备唯一ID
    var cuid: String?
    /// 设备型号
    var model: String?
    /// 手机网络类型
    var networkType: String?
}

public struct SFAppUpgraderError: Error {
    var code: Int
    var description: String
    init(code: Int, description: String) {
        self.code = code
        self.description = description
    }
}

public class SFAppUpgrader {
        
    /// 业务方向app标识
    private var productId: String?
    /// appstoreid
    private var appStoreId: String?
    private var passPlatform: String?
    private var limitNetInterval: TimeInterval  = 0
    private var limitShowAlertInterval: TimeInterval = 0
    private var limitShowTestFlightAlertInterval: TimeInterval = 0
    private var alert: SFAlertView?
    private var upgradeView: SFAppUpgradeView?
    private var passUid: String?
    private var viewModel = SFAppUpgradeViewModel()
    /// 是否已经启动升级检测
    private var isStartUp: Bool = false
    /// icon图片
    private var iconImage: UIImage?
    public static let shared = SFAppUpgrader()
    public var upgradeModel: SFAppUpgraderModel?
    /// 自定义升级处理方法，业务方给改参数赋值后，sdk不再处理升级逻辑(SFAppUpgraderError为nil时，SFAppUpgraderModel也可能为nil)
    public var customHandleAction: ((SFAppUpgraderError?, SFAppUpgraderModel?) -> ())?
    public var cancelBtnTitle: String = "取消"
    public var downLoadBtnTitle: String = "去下载"
    
    /// 注册方法
    /// - Parameters:
    ///   - USS: USS
    ///   - Stoken: Stoken
    ///   - passPlatform: 登录pass
    ///   - productAppid: 业务端的app标识,发版平台创建app时填入的appkey
    ///   - appstoreAppId: 如果是非企业包(即appstore)，该参数需要传
    ///   - iconImage: icon
    ///   - type: 升级策略方式
    public class func registerApp(USS: String, Stoken: String, passPlatform: String, productAppid: String, appstoreAppId: String?, iconImage: UIImage?, type: SFAppUpgraderType = .limitStrategy(netInterval: 250, alertInterval: 7200, testFlightAlertInterval: 7200)) {
        SFAppUpgrader.shared.productId = productAppid
        SFAppUpgrader.shared.appStoreId = appstoreAppId
        SFAppUpgrader.shared.passPlatform = passPlatform
        SFAppUpgrader.shared.upgradeStrategy(type: type)
        SFAppUpgrader.shared.iconImage = iconImage
        CookieUtil.updateCookie(domain: UpgradeHost(), path: "/", version: "0", name: "STOKEN", value: Stoken)
        CookieUtil.updateCookie(domain: UpgradeHost(), path: "/", version: "0", name: "USS", value: USS)
    }
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        upgradeModel = SFAppUpgraderModel.loadUpgradeCacheModel()
    }
    
    /**
     启动自动检测逻辑
     调用该方法后会直接进行一次升级检测，并且之后程序在后台切前台都会进行升级检测逻辑
     注：如果检测的时候没有达到网络访问的时间间隔，直接跳出检测，不会触发请求。
     */
    public class func startUp() {
        SFAppUpgrader.shared.isStartUp = true
        SFAppUpgrader.shared.checkCanUpgrade()
    }
    
    /**
     主动调起一次升级检测
     - Parameters:
        - unNeedUpgraderText: 不需要升级时的toast提示文案（如果传callBack了忽略该字段）
        - callBack: 回调方法， 不传的话以注册时设置的方式处理升级逻辑(SFAppUpgraderError为nil时，SFAppUpgraderModel也可能为nil)
     */
    public func launchUpgrader(unNeedUpgraderText: String = "当前已是最新版本", callBack: ((SFAppUpgraderError?, SFAppUpgraderModel?) -> ())?) {
        inlineUpgrader(autoInvoke: false, unNeedUpgraderText: unNeedUpgraderText, callBack: callBack)
    }
    
    /// 下载testFilght版本
    public func testFlightDownload() {
        if SFAppUpgrader.shared.checkTestFlight() {
            SFAppUpgrader.shared.downloadApp(urlString: upgradeModel?.testFlightURL)
        } else {
            if let testFlightViewController = SFAppUpgradeTestFlightViewController.loadFromNib() {
                testFlightViewController.iconImage = iconImage
                upgradeView?.dismiss()
                if let nav = UIApplication.shared.delegate?.window??.rootViewController?.navigationController {
                    nav.pushViewController(testFlightViewController, animated: true)
                } else {
                    testFlightViewController.isHaveNavigation = false
                    UIApplication.shared.delegate?.window??.rootViewController?.present(testFlightViewController, animated: true, completion: nil)
                }
            }
        }
    }
    
    private func inlineUpgrader(autoInvoke: Bool = true, unNeedUpgraderText: String = "当前已是最新版本", callBack: ((SFAppUpgraderError?, SFAppUpgraderModel?) -> ())?) {
        if SFAppUpgrader.networkReachable == false {
            #if DEBUG
            debugPrint("网络访问异常，请稍后重试")
            #endif
            let err = SFAppUpgraderError.init(code: -1, description: "网络访问异常，请稍后重试")
            handleErrorResultCallBack(autoInvoke: autoInvoke, error: err, callBack: callBack)
            return
        }
        let param = SFGetAppUpdateInfoParameters(productId: productId ?? "", passUid: ToStr(passUid), passPlatform:ToStr(passPlatform) ,configModel: getConfigModel())
        let taskParams = SFUpgraderURLRequestTask.Parameters.init(postParameters: param)
        SFUpgraderURLRequestTask.asyncExecute(taskParams) {[weak self] (task) in
            guard let aself = self else {
                let err = SFAppUpgraderError.init(code: -2, description: "系统出错")
                if let backBlock = callBack {
                    backBlock(err, nil)
                    return
                }
                
                if autoInvoke == false {
                    SFToast.show(withText: err.description)
                }
                return
            }
            
            guard task.error == nil else {
                #if DEBUG
                debugPrint(task.error?.description ?? "网络访问失败")
                #endif
                let err = SFAppUpgraderError.init(code: task.error?.code ?? -1, description: ToStr(task.error?.description))
                aself.handleErrorResultCallBack(error: err, callBack: callBack)
                return
            }
            
            let model = task.result?.data
            aself.upgradeModel = model
            SFAppUpgraderModel.updateUpgradeCacheModel(aself.upgradeModel)
            
            var alreadyHandle = false
            
            if let backBlock = callBack {
                backBlock(nil, aself.upgradeModel)
                alreadyHandle = true
            } else {
                if let customBlock = aself.customHandleAction {
                    customBlock(nil, aself.upgradeModel)
                    alreadyHandle = true
                }
            }
            
            if alreadyHandle == false  {
                aself.checkShowAlertView(autoInvoke: autoInvoke, unNeedUpgraderText: unNeedUpgraderText)
                if model == nil, autoInvoke == false {
                    SFToast.show(withText: unNeedUpgraderText)
                }
            }
            
            if autoInvoke {
                let defaults = UserDefaults.standard
                let nowDate = Date().timeIntervalSince1970
                defaults.set(nowDate, forKey: kSFAppUpgraderLastNetKey)
            }
        }
    }
    
    private func handleErrorResultCallBack(autoInvoke: Bool = true, error: SFAppUpgraderError, callBack: ((SFAppUpgraderError?, SFAppUpgraderModel?) -> ())?) {
        
        if let backBlock = callBack {
            backBlock(error, nil)
            return
        }
        
        if let customBlock = self.customHandleAction {
            customBlock(error, nil)
            return
        }
        
        if autoInvoke == false {
            SFToast.show(withText: error.description )
        }
    }
    
    private func upgradeStrategy(type: SFAppUpgraderType) {
        switch type {
        case .limitStrategy(let netInterval, let alertInterval, let testFlightAlertInterval):
            limitNetInterval = netInterval
            limitShowAlertInterval = alertInterval
            limitShowTestFlightAlertInterval = testFlightAlertInterval
        }
    }
    
    private func checkCanUpgrade() {
        guard isStartUp == true else { return }
        if limitNetInterval == 0 {
            inlineUpgrader(callBack: nil)
        } else {
            /// 如果当前数据是强制升级 并且数据版本号大于当前app版本号，则需要忽略网络时间限制
            if let model = upgradeModel, let serverVer = model.version, model.is_force == "1" {
                if let dic = Bundle.main.infoDictionary, let ver = dic["CFBundleShortVersionString"] as? String {
                    if ver.compare(serverVer, options: .numeric, range: nil, locale: nil) == ComparisonResult.orderedAscending {
                        inlineUpgrader(callBack: nil)
                        return
                    }
                }
                checkTimeAlreadyNetwork()
            } else {
                checkTimeAlreadyNetwork()
            }
        }
    }
        
    private func checkTimeAlreadyNetwork() {
        let defaults = UserDefaults.standard
        if let time = defaults.object(forKey: kSFAppUpgraderLastNetKey) as? Double {
            let nowDate = Date().timeIntervalSince1970
            if nowDate - time > limitNetInterval {
                inlineUpgrader(callBack: nil)
            }
        } else {
            inlineUpgrader(callBack: nil)
        }
    }

    private func checkShowAlertView(autoInvoke: Bool, unNeedUpgraderText: String?) {
        if let model = upgradeModel, let serverVer = model.version {
            if let dic = Bundle.main.infoDictionary, let ver = dic["CFBundleShortVersionString"] as? String {
                if ver.compare(serverVer, options: .numeric, range: nil, locale: nil) == ComparisonResult.orderedAscending {
                    if model.is_force == "1" {
                        showAlert(autoInvoke: autoInvoke, defaultsKey: nil)
                    } else {
                        var defaultsKey = ""
                        var limit: TimeInterval = 0
                        if model.type == "3" {
                            limit = limitShowTestFlightAlertInterval
                            defaultsKey = kSFAppUpgraderTestFlightLastAlertKey
                        } else {
                            limit = limitShowAlertInterval
                            defaultsKey = kSFAppUpgraderLastAleatKey
                        }
                        if autoInvoke {
                            let defaults = UserDefaults.standard
                            let nowDate = Date().timeIntervalSince1970
                            
                            if let time = defaults.object(forKey: defaultsKey) as? Double {
                                if nowDate - time > limitShowTestFlightAlertInterval {
                                    showAlert(autoInvoke: autoInvoke, defaultsKey: defaultsKey)
                                }
                            } else {
                                showAlert(autoInvoke: autoInvoke, defaultsKey: defaultsKey)
                            }
                        } else {
                            showAlert(autoInvoke: autoInvoke, defaultsKey: defaultsKey)
                        }
                    }
                } else {
                    if autoInvoke == false {
                        SFToast.show(withText: unNeedUpgraderText)
                    }
                }
            }
        }
    }
    
    private func showAlert(autoInvoke: Bool, defaultsKey: String?) {
        if let model = upgradeModel {
            if autoInvoke, let defaultsKey = defaultsKey {
                let defaults = UserDefaults.standard
                let nowDate = Date().timeIntervalSince1970
                defaults.set(nowDate, forKey: defaultsKey)
            }
            upgradeView?.dismiss()
            upgradeView = SFAppUpgradeView(node: viewModel.createNode(model: model))
            upgradeView?.show()
            upgradeView?.upgradeBlock = {[weak self] in
                self?.toDownLoadApp()
            }
        }
    }
    
    private func toDownLoadApp() {
        if let model = upgradeModel {
            
            if model.type == "3" { //testFlight
                upgradeView?.dismiss()
                testFlightDownload()
                return
            }
            
            if model.is_force == "1" { //强制升级
                if model.pro_type == "1" { //企业包
                    if let urlStr = model.url, let url = URL.init(string: urlStr) {
                        UIApplication.shared.openURL(url)
                        exit(0)
                    }
                } else { //非企业包
                    if let appid = appStoreId, appid.count > 0 {
                        let urlstr = "https://itunes.apple.com/cn/app/id\(appid)?mt=8"
                        if let url = URL.init(string: urlstr)  {
                            UIApplication.shared.openURL(url)
                        }
                    }
                }
            } else if model.is_force == "2" { //非强制升级
                upgradeView?.dismiss()
                if model.pro_type == "1" { //企业包
                    if let urlStr = model.url, let url = URL.init(string: urlStr) {
                        UIApplication.shared.openURL(url)
                    }
                } else { //非企业包
                    if let appid = appStoreId, appid.count > 0 {
                        let urlstr = "https://itunes.apple.com/cn/app/id\(appid)?mt=8"
                        if let url = URL.init(string: urlstr)  {
                            UIApplication.shared.openURL(url)
                        }
                    }
                }
            }
        }
    }
    
    private func getConfigModel() -> SFAppUpgraderConfig {
        let model = SFAppUpgraderConfig()
        model.cuid = Device.cuid
        model.osv = Device.osv
        model.networkType = Device.networkType
        model.model = Device.model
        return model
    }
    
    @objc private func applicationDidBecomeActive() {
        checkCanUpgrade()
    }
    
    /// 检查本地是否安装TestFlight
    public func checkTestFlight() -> Bool {
        if let url = URL(string: "itms-beta://"), UIApplication.shared.canOpenURL(url) {
            return true
        }
        return false
    }
    
    /// 前往TestFlight下载APP
    /// - Parameter urlString: 下载地址
    public func downloadApp(urlString: String?) {
        if let urlString = urlString, let downloadUrl = URL(string: urlString.replacingOccurrences(of: "https", with: "itms-beta")) {
            UIApplication.shared.openURL(downloadUrl)
        }
    }
    
    /// 下载TestFlightApp
    public func downloadTestFlightApp() {
        if let testFlightUrl = URL(string: "https://itunes.apple.com/cn/app/testflight/id899247664?mt=8") {
            UIApplication.shared.openURL(testFlightUrl)
        }
    }
}

extension SFAppUpgrader {
    static var networkReachable: Bool { return SF.networkReachable }
}
