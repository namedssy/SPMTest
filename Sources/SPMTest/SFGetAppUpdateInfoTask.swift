//
//  SFGetAppUpdateInfoTask.swift
//  SFAppUpgrader
//
//  Created by 孔六五 on 2018/10/29.
//  Copyright © 2018 Beijing SF Intra-city Technology Co., Ltd. All rights reserved.
//

import SFFoundation

func UpgradeHost() -> String {
        var hostString = ""
        #if DEV_NETWORK
            hostString = "http://10.210.40.18:8091"
        #else
            hostString = "https://goic.sf-express.com"
        #endif
    
        return hostString
}

public struct SFAppUpgraderModel: SFCacheable {
    public static var cacheName: String = "SFAppUpgraderCache"
    /// 标题
    public var title: String?
    /// 文案
    public var content: String?
    /// 版本号
    public var version: String?
    /// 1为强制升级；2为非强制升级
    public var is_force: String?
    /// 企业版下载地址
    public var url: String?
    /// 包大小
    public var size: String?
    /// 1 全量发布  2 灰度发布 3为灰测
    public var type: String?
    /// 灰测包URL
    public var testFlightURL: String?
    /// 1为企业版，2为非企业版
    public var pro_type: String?
    
    private static var upgraderDiskPath: String {
        return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "SFAppUpgraderCache"
    }
    
    public static func loadUpgradeCacheModel() -> SFAppUpgraderModel? {
        return SFAppUpgraderModel.loadFromDisk(.document)
    }

    public static func updateUpgradeCacheModel(_ cacheModel: SFAppUpgraderModel?) {
        SFAppUpgraderModel.updateDiskCache(cacheModel, .document)
    }
}

struct SFUpgraderRequestResult<DataType: Decodable>: Decodable {
    var errno: Int
    var errmsg: String
    var data: DataType?
    /// server time
    var serverTime: Double?
}

struct SFGetAppUpdateInfoParameters: Codable {
    /// app名称，例如knight
    var name: String?
    /// iOS 或者 android
    var platform: String = "2"
    /// 用户id
    var pass_uid: String?
    /// 当前版本号
    var version: String?
    /// 操作系统版本
    var osv: String?
    /// 设备型号
    var model: String?
    /// 手机网络类型
    var networkType: String?
    var cuid: String?
    /// 登录pass 来源
    var pass_platform: String?
    
    init(productId: String,passUid: String, passPlatform: String, configModel: SFAppUpgraderConfig) {
        name = productId
        cuid = configModel.cuid
        version = Device.appVersion
        pass_uid = passUid
        osv = configModel.osv
        model = configModel.model
        networkType = configModel.networkType
        pass_platform = passPlatform
    }
}

class RequestTask<P: RequestParameters, R: Decodable>: Task<P, SFUpgraderRequestResult<R>, URLRequestTaskError> {
    func postParameters() -> [String: CustomStringConvertible] {
        var postParameters = [String: CustomStringConvertible]()
        postParameters = postParameters.merging(parameters.postParameters.toDictionary() ?? [:]){(_, new) in new}
        return postParameters
    }

    override func main() throws {
        let params = URLRequestParametersOption.form(url: self.parameters.urlPath(), postParameters: postParameters(), getParameters: nil, headers: nil)
        try URLRequestTask.syncExecute(params, parent: self, completion: { (childTask) in
            if let data = childTask.result?.data {
                try self.result = SFJSONDecoder().decode(ResultType.self, from: data)
                if self.result?.errno != 0 {
                    throw URLRequestTaskError(code: self.result!.errno, description: self.result!.errmsg, userInfo: nil)
                }
            } else {
                throw URLRequestTaskError(code: -1, description: "网络请求失败", userInfo: nil)
            }
        })
    }
}

protocol RequestParameters {
    associatedtype PostParametersType: Encodable
    func urlPath() -> String
    var postParameters: PostParametersType? { get }
}

class SFUpgraderURLRequestTask: RequestTask<SFUpgraderURLRequestTask.Parameters, SFAppUpgraderModel> {
    struct Parameters: RequestParameters {
        func urlPath() -> String {
            return "\(UpgradeHost())/vrms/api/getappupdateinfo"
        }
        var postParameters: SFGetAppUpdateInfoParameters?
    }
}
