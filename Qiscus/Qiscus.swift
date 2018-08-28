//
//  Qiscus.swift
//
//  Created by Ahmad Athaullah on 7/17/16.
//  Copyright © 2016 qiscus. All rights reserved.
//

import Foundation
import QiscusCore
import QiscusUI
import SwiftyJSON

@objc public protocol QiscusDiagnosticDelegate {
    @objc func qiscusDiagnostic(sendLog log:String)
}

public protocol QiscusConfigDelegate {
    func qiscusFailToConnect(_ withMessage:String)
    func qiscusConnected()
    
    func qiscus(gotSilentNotification comment:QComment, userInfo:[AnyHashable:Any])
    func qiscus(didConnect succes:Bool, error:String?)
    func qiscus(didRegisterPushNotification success:Bool, deviceToken:String, error:String?)
    func qiscus(didUnregisterPushNotification success:Bool, error:String?)
    func qiscus(didTapLocalNotification comment:QComment, userInfo:[AnyHashable : Any]?)
    
    func qiscusStartSyncing()
    func qiscus(finishSync success:Bool, error:String?)
}

public protocol QiscusRoomDelegate {
    func gotNewComment(_ comments:QComment)
    func didFinishLoadRoom(onRoom room: QRoom)
    func didFailLoadRoom(withError error:String)
    func didFinishUpdateRoom(onRoom room:QRoom)
    func didFailUpdateRoom(withError error:String)
}

public protocol QiscusListRoomDelegate {
    func onRoom(_ room: QRoom, gotNewComment comment: QComment)
    func onRoom(_ room: QRoom, didChangeComment comment: QComment, changeStatus status: CommentStatus)
    func onRoom(_ room: QRoom, thisParticipant user: QMember, isTyping typing: Bool)
    func onChange(user: QMember, isOnline online: Bool, at time: Date)
    func gotNew(room: QRoom)
    func remove(room: QRoom)
}

var QiscusBackgroundThread = DispatchQueue(label: "com.qiscus.background", attributes: .concurrent)

public class Qiscus {
    
    public static let sharedInstance = Qiscus()
    static let qiscusVersionNumber:String = "2.9.1"
    var reachability:QReachability?
    var configDelegate : QiscusConfigDelegate? = nil
    public static var listChatDelegate:QiscusListRoomDelegate?
    static var qiscusDeviceToken: String = ""
    var notificationAction:((QiscusChatVC)->Void)? = nil
    var disableLocalization: Bool = false
    var isPushed:Bool = false
    /// cached qiscusChatVC : viewController that already opened will be chached here
    public var chatViews = [String:QiscusChatVC]()
    /**
     Active Qiscus Print log, by default is disable/false
     */
    public static var showDebugPrint : Bool {
        get{
            return QiscusCore.enableDebugPrint
        }
        set{
            QiscusCore.enableDebugPrint = newValue
        }
    }
    
    /**
     Save qiscus log.
     */
    // TODO : when active save log, make sure file size under 1/3Mb.
    @available(*, deprecated, message: "no longer available for public ...")
    static var saveLog:Bool = false
    
    internal class func logFile()->String{
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true)[0] as NSString
        let logPath = documentsPath.appendingPathComponent("Qiscus.log")
        return logPath
    }
    
    /// Setup Qiscus Custom Configuration, default value is QiscusUIConfiguration.sharedInstance
    @available(*, deprecated, message: "no longer available for public ...")
    var styleConfiguration = QiscusUIConfiguration.sharedInstance
    @available(*, deprecated, message: "no longer available for public ...")
    var connected:Bool = false
    /// check qiscus is connected with server or not.
    @objc public var isConnected: Bool {
        get {
            return Qiscus.sharedInstance.connected
        }
    }
    
    public class var shared:Qiscus{
        get{
            return Qiscus.sharedInstance
        }
    }
    
    /// shared instance of QiscusClient
    public static var client : QiscusClient {
        get { return QiscusClient.shared }
    }
    
    /**
     iCloud Config, by default is disable/false. You need to setup icloud capabilities then create container in your developer account.
     */
    public var iCloudUpload = false {
        didSet{
            //TODO Need to implement to SDKUI
        }
    }
    public var cameraUpload = true {
        didSet{
            //TODO Need to implement to SDKUI
        }
    }
    public var galeryUpload = true {
        didSet{
            //TODO Need to implement to SDKUI
        }
    }
    public var contactShare = true {
        didSet{
            //TODO Need to implement to SDKUI
        }
    }
    public var locationShare = true {
        didSet{
            //TODO Need to implement to SDKUI
        }
    }
    
    /**
     Receive all Qiscus Log, then handle logs\s by client.
     
     ```
     func qiscusDiagnostic(sendLog log:String)
     ```
     */
    public var diagnosticDelegate:QiscusDiagnosticDelegate?
    let application = UIApplication.shared
    
    /// Qiscus bundle
    class var bundle:Bundle{
        get{
            let podBundle = Bundle(for: Qiscus.self)
            
            if let bundleURL = podBundle.url(forResource: "Qiscus", withExtension: "bundle") {
                return Bundle(url: bundleURL)!
            }else{
                return podBundle
            }
        }
    }
    
    ///check qiscus user login status
    @objc public class var isLoggedIn:Bool{
        get{
            return QiscusCore.isLogined
        }
    }
    
    /**
     Set App ID, when you are using nonce auth you need to setup App ID before get nounce
     
     - parameter appId: Qiscus App ID, please register or login in http://qiscus.com to find your App ID
     */
    
    public class func setAppId(appId:String){
        QiscusCore.setup(WithAppID: appId)
        QiscusCore.enableDebugPrint = true
    }
    
    /**
     Qiscus Setup with `identity token`, 2nd call method after you call getNounce. Response from you backend then putback in to Qiscus Server
     
     - parameter uidToken: token where you get from get nonce
     - parameter delegate: QiscusConfigDelegate
     
     */
    public class func setup(withUserIdentityToken uidToken:String, delegate: QiscusConfigDelegate? = nil){
        if delegate != nil {
            Qiscus.sharedInstance.configDelegate = delegate
        }
        Qiscus.sharedInstance.setup(withuserIdentityToken: uidToken)
        Qiscus.setupReachability()
        Qiscus.sharedInstance.RealtimeConnect()
    }
    
    func setup(withuserIdentityToken: String){
        QiscusCore.connect(withIdentityToken: withuserIdentityToken) { (qUser, error) in
            if let user = qUser{
                QiscusClient.shared.token = user.token
                QiscusClient.shared.userData.set(user.token, forKey: "qiscus_token")
                self.configDelegate?.qiscusConnected()
                self.configDelegate?.qiscus(didConnect: true, error: nil)
                
            }else{
                self.configDelegate?.qiscusFailToConnect((error?.message)!)
                self.configDelegate?.qiscus(didConnect: false, error: (error?.message)!)
            }
            
        }
    }
    
    
    func RealtimeConnect(){
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidEnterBackground, object: nil)
        
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(Qiscus.applicationDidBecomeActife), name: .UIApplicationDidBecomeActive, object: nil)
        center.addObserver(self, selector: #selector(Qiscus.goToBackgroundMode), name: .UIApplicationDidEnterBackground, object: nil)
        
        if Qiscus.isLoggedIn {
            Qiscus.mqttConnect()
        }
    }
    
    //Todo need to be fix
    @objc func goToBackgroundMode(){
        //        for (_,chatView) in self.chatViews {
        //            if chatView.isPresence {
        //                chatView.goBack()
        //                if let room = chatView.chatRoom {
        //                    room.delegate = nil
        //                }
        //            }
        //        }
        //        Qiscus.shared.stopPublishOnlineStatus()
    }
    
    /// connect mqtt
    ///
    /// - Parameter chatOnly: -
    class func mqttConnect(chatOnly:Bool = false){
        Qiscus.backgroundSync()
    }
    
    /// QiscusUIConfiguration class
    public var style:QiscusUIConfiguration{
        get{
            return Qiscus.sharedInstance.styleConfiguration
        }
    }
    
    /// Get room with room id
    ///
    /// - Parameters:
    ///   - withID: existing roomID from server or local db.
    ///   - completion: Response Qiscus Room Object and error if exist.
    public class func room(withId roomId:String, onSuccess:@escaping ((QRoom)->Void),onError:@escaping ((String)->Void)){
        return QiscusCore.shared.getRoom(withID: roomId, completion: { (qRoom, error) in
            if(qRoom != nil){
                onSuccess(qRoom as! QRoom)
            }else{
                onError((error?.message)!)
            }
        })
    }
    
    /// Get room by channel name
    ///
    /// - Parameters:
    ///   - channel: channel name or channel id
    ///   - completion: Response Qiscus Room Object and error if exist.
    public class func room(withChannel channelName:String, onSuccess:@escaping ((QRoom)->Void),onError:@escaping ((String)->Void)){
        return QiscusCore.shared.getRoom(withChannel: channelName, completion: { (qRoom, error) in
            if(qRoom != nil){
                onSuccess(qRoom as! QRoom)
            }else{
                onError((error?.message)!)
            }
        })
    }
    
    /// Get or create room with participant / create 1 on 1 chat
    ///
    /// - Parameters:
    ///   - withUsers: Qiscus user emaial.
    ///   - completion: Qiscus Room Object and error if exist.
    public class func room(withUserId: String, onSuccess:@escaping ((QRoom)->Void),onError:@escaping ((String)->Void)){
        return QiscusCore.shared.getRoom(withUser: withUserId, completion: { (qRoom, error) in
            if(qRoom != nil){
                onSuccess(qRoom as! QRoom)
            }else{
                onError((error?.message)!)
            }
        })
    }
    
    
    /// open chat wit roomId
    ///
    /// - Parameter withRoomId: roomId
    /// - Returns: will return ViewController chat
    public func chatView(withRoomId: String) -> QiscusChatVC {
        let chatRoom = QiscusChatVC()
        if !Qiscus.sharedInstance.connected {
            Qiscus.setupReachability()
        }
        
        var chatVC = QiscusChatVC()
        
        if let chatView = Qiscus.sharedInstance.chatViews[withRoomId] {
            chatVC = chatView
        }else{
            chatVC.chatRoomId = withRoomId
        }
        return chatVC
    }
    
    /// Get Nonce from SDK server. use when login with JWT
    ///
    /// - Parameter completion: @escaping with Optional(QNonce) and String Optional(error)
    public func getNonce(onSuccess:@escaping ((String)->Void), onFailed:@escaping ((String)->Void), secureURL:Bool = true){
        QiscusCore.getNonce { (nonceData, error) in
            if let nonce = nonceData {
                onSuccess((nonceData?.nonce)!)
            }else{
                if let errorMessage = error {
                    onFailed(errorMessage)
                }
            }
            
        }
    }
    
    /// fetchAllRoom
    ///
    /// - Parameters:
    ///   - limit: default limit 100
    ///   - page: default page 1
    ///   - onSuccess: will return QRoom object and total room
    ///   - onFailed: will return error message
    public class func fetchAllRoom(loadLimit:Int = 0, onSuccess:@escaping (([QRoom])->Void),onError:@escaping ((String)->Void)){
        var page = 1
        var limit = 100
        if loadLimit > 0 {
            limit = loadLimit
        }
        
        QRoom.getAllRoom(withLimit: limit, page: page, onSuccess: { (qRoom, totalRooms) in
            onSuccess(qRoom)
        }) { (error) in
            onError(error)
        }
    }
    
    /// get image assets on qiscus bundle
    ///
    /// - Parameter name: assets name
    /// - Returns: UIImage
    @objc public class func image(named name:String)->UIImage?{
        return UIImage(named: name, in: Qiscus.bundle, compatibleWith: nil)?.localizedImage()
    }
    
    /// subscribe room notification
    public func subscribeAllRoomNotification(){
        //        QiscusBackgroundThread.async { autoreleasepool {
        //            let rooms = QRoom.all()
        //            for room in rooms {
        //                room.subscribeRealtimeStatus()
        //            }
        //            }}
    }
    
    //TODO NEED TO BE IMPLEMENT search Comment
    /// search local message comment
    ///
    /// - Parameter searchQuery: query to search
    /// - Returns: array of QComment obj
    public func searchComment(searchQuery: String) -> [QComment]? {
        return nil
    }
    
    /// search message comment from service
    ///
    /// - Parameter searchQuery: query to search
    /// - Returns: array of QComment obj
    public class func searchCommentService( withQuery text:String, room:QRoom? = nil, fromComment:QComment? = nil, onSuccess:@escaping (([QComment])->Void), onFailed: @escaping ((String)->Void)){
        
    }
    
    /// debug print
    ///
    /// - Parameter text: log message
    public class func printLog(text:String){
        if Qiscus.showDebugPrint{
            let logText = "[Qiscus]: \(text)"
            print(logText)
            DispatchQueue.global().sync{
                if Qiscus.saveLog {
                    let date = Date()
                    let df = DateFormatter()
                    df.dateFormat = "y-MM-dd H:m:ss"
                    let dateTime = df.string(from: date)
                    
                    let logFileText = "[Qiscus - \(dateTime)] : \(text)"
                    let logFilePath = Qiscus.logFile()
                    var dump = ""
                    if FileManager.default.fileExists(atPath: logFilePath) {
                        dump =  try! String(contentsOfFile: logFilePath, encoding: String.Encoding.utf8)
                    }
                    do {
                        // Write to the file
                        try  "\(dump)\n\(logFileText)".write(toFile: logFilePath, atomically: true, encoding: String.Encoding.utf8)
                    } catch let error as NSError {
                        Qiscus.printLog(text: "Failed writing to log file: \(logFilePath), Error: " + error.localizedDescription)
                    }
                }
            }
            Qiscus.sharedInstance.diagnosticDelegate?.qiscusDiagnostic(sendLog: logText)
        }
    }
    
    @objc public class func didReceive(RemoteNotification userInfo:[AnyHashable : Any], completionHandler: @escaping (UIBackgroundFetchResult) -> Void = {_ in}){
        completionHandler(.newData)
        
        if Qiscus.isLoggedIn{
            if userInfo["qiscus_sdk"] != nil {
                let state = Qiscus.sharedInstance.application.applicationState
                if state != .active {
                    Qiscus.sharedInstance.syncProcess()
                    if let payloadData = userInfo["payload"]{
                        let jsonPayload = JSON(arrayLiteral: payloadData)[0]
                        
                        //TODO Need To Be implement in SDKCore
                        //using commentBy Id
                        let tempComment = QComment.tempComment(fromJSON: jsonPayload)
                        
                        if tempComment != nil {
                            Qiscus.sharedInstance.configDelegate?.qiscus(gotSilentNotification: tempComment!, userInfo: userInfo)
                        }
                       
                    }
                }
            }
        }
    }
    
    //Todo call api SyncProses
    public func syncProcess(){
        
    }
    
    //Todo connect to mqtt
    public class func backgroundSync(){
        QiscusCore.connect()
    }
    
    /// register device token to sdk server
    ///
    /// - Parameter token: device token Data
    public class func didRegisterUserNotification(withToken token: Data){
        if Qiscus.isLoggedIn{
            var tokenString: String = ""
            for i in 0..<token.count {
                tokenString += String(format: "%02.2hhx", token[i] as CVarArg)
            }
            
            //call service api to register notification
            QiscusCore.shared.register(deviceToken: tokenString) { (isRegister, erorr) in
                Qiscus.sharedInstance.configDelegate?.qiscus(didRegisterPushNotification: isRegister, deviceToken: tokenString, error: erorr?.message)
            }
        }
    }
    
    
    /// this func to update room
    ///
    /// - Parameters:
    ///   - roomId: roomId
    ///   - roomName: roomName
    ///   - avatar: avatarUrl
    public func updateRoom(roomId: String, roomName: String? = nil, avatar: String? = nil, onSuccess:@escaping ((QRoom)->Void),onError:@escaping ((String)->Void)){
        if(avatar != nil){
            QiscusCore.shared.updateRoom(withID: roomId, name: roomName, avatarURL: URL(string: avatar!), options: nil) { (qRoom, error) in
                if let qRoomData = qRoom {
                    onSuccess(qRoomData as! QRoom)
                }else{
                    if let errorMessage = error {
                        onError(errorMessage.message)
                    }
                }
            }
        }else{
            QiscusCore.shared.updateRoom(withID: roomId, name: roomName, avatarURL: nil, options: nil) { (qRoom, error) in
                if let qRoomData = qRoom {
                    onSuccess(qRoomData as! QRoom)
                }else{
                    if let errorMessage = error {
                        onError(errorMessage.message)
                    }
                }
            }
        }
        
    }
    
    /// didREceive localnotification
    ///
    /// - Parameter notification: UILocalNotification
    public class func didReceiveNotification(notification:UILocalNotification){
        if notification.userInfo != nil {
            //TODO NEED TO BE IMPLEMENT
//            if let comment = QComment.decodeDictionary(data: notification.userInfo!) {
//                var userData:[AnyHashable : Any]? = [AnyHashable : Any]()
//                let qiscusKey:[AnyHashable] = ["qiscus_commentdata","qiscus_uniqueId","qiscus_id","qiscus_roomId","qiscus_beforeId","qiscus_text","qiscus_createdAt","qiscus_senderEmail","qiscus_senderName","qiscus_statusRaw","qiscus_typeRaw","qiscus_data"]
//                for (key,value) in notification.userInfo! {
//                    if !qiscusKey.contains(key) {
//                        userData![key] = value
//                    }
//                }
//                if userData!.count == 0 {
//                    userData = nil
//                }
//                Qiscus.sharedInstance.configDelegate?.qiscus(didTapLocalNotification: comment, userInfo: userData)
//            }
        }
    }
    
    public func didReceive(RemoteNotification userInfo:[AnyHashable : Any], completionHandler: @escaping (UIBackgroundFetchResult) -> Void = {_ in}){
        completionHandler(.newData)
        
        if Qiscus.isLoggedIn{
            if userInfo["qiscus_sdk"] != nil {
                let state = Qiscus.sharedInstance.application.applicationState
                if state != .active {
                    self.syncProcess()
                    if let payloadData = userInfo["payload"]{
                        let jsonPayload = JSON(arrayLiteral: payloadData)[0]
                        let tempComment = QComment.tempComment(fromJSON: jsonPayload)
                        Qiscus.sharedInstance.configDelegate?.qiscus(gotSilentNotification: tempComment!, userInfo: userInfo)
                    }
                }
            }
        }
    }
    
    @objc func applicationDidBecomeActife(){
        Qiscus.setupReachability()
        if Qiscus.isLoggedIn{
            Qiscus.sharedInstance.RealtimeConnect()
        }
        if !Qiscus.sharedInstance.styleConfiguration.rewriteChatFont {
            Qiscus.sharedInstance.styleConfiguration.chatFont = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        }
        if let chatView = QiscusHelper.topViewController() as? QiscusChatVC {
            chatView.isPresence = true
            
        }
        Qiscus.connect()
        Qiscus.sync(cloud: true)
    }
    
    /// do message synchronize
    ///
    /// - Parameter cloud: -
    public class func sync(cloud:Bool = false){
        if Qiscus.isLoggedIn{
            Qiscus.sharedInstance.syncProcess(cloud: cloud)
        }
    }
    
    //Todo need to be implement call api sync
    func syncProcess(first:Bool = true, cloud:Bool = false){
        self.configDelegate?.qiscusStartSyncing()
        self.configDelegate?.qiscus(finishSync: true, error: "")
    }
    
    /// setup reachability for network connection detection
    class func setupReachability(){
        QiscusBackgroundThread.async {autoreleasepool{
            Qiscus.sharedInstance.reachability = QReachability()
            
            if let reachable = Qiscus.sharedInstance.reachability {
                if reachable.isReachable {
                    Qiscus.sharedInstance.connected = true
                    if Qiscus.isLoggedIn {
                        Qiscus.sharedInstance.RealtimeConnect()
                        DispatchQueue.main.async { autoreleasepool{
                            QComment.resendPendingMessage()
                            }}
                    }
                }
            }
            
            Qiscus.sharedInstance.reachability?.whenReachable = { reachability in
                if reachability.isReachableViaWiFi {
                    Qiscus.printLog(text: "connected via wifi")
                } else {
                    Qiscus.printLog(text: "connected via cellular data")
                }
                Qiscus.sharedInstance.connected = true
                if Qiscus.isLoggedIn {
                    Qiscus.sharedInstance.RealtimeConnect()
                    DispatchQueue.main.async { autoreleasepool{
                        QComment.resendPendingMessage()
                        }}
                }
            }
            Qiscus.sharedInstance.reachability?.whenUnreachable = { reachability in
                Qiscus.printLog(text: "disconnected")
                Qiscus.sharedInstance.connected = false
            }
            do {
                try  Qiscus.sharedInstance.reachability?.startNotifier()
            } catch {
                Qiscus.printLog(text: "Unable to start network notifier")
            }
            }}
    }
    
    
    /// connect to mqtt and setup reachability
    ///
    /// - Parameter delegate: QiscusConfigDelegate
    public class func connect(delegate:QiscusConfigDelegate? = nil){
        if !QiscusCore.connect() {
            print("Qiscus Realtime Filed to connect, please try again or relogin")
        }
        Qiscus.sharedInstance.RealtimeConnect()
        if delegate != nil {
            Qiscus.sharedInstance.configDelegate = delegate
        }
        Qiscus.setupReachability()
        Qiscus.sharedInstance.syncProcess()
    }
    
    /// set banner click action
    ///
    /// - Parameter action: do something on @escaping when banner notif did tap
    public func setNotificationAction(onClick action:@escaping ((QiscusChatVC)->Void)){
        Qiscus.sharedInstance.notificationAction = action
    }
    
    /// trigger register notif delegate on appDelegate
    public func registerNotification(){
        let notificationSettings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
        Qiscus.sharedInstance.application.registerUserNotificationSettings(notificationSettings)
        Qiscus.sharedInstance.application.registerForRemoteNotifications()
    }
    
    /**
     Class function to set color chat navigation without gradient
     - parameter color: The **UIColor** as your navigation color.
     - parameter tintColor: The **UIColor** as your tint navigation color.
     */
    public func setNavigationColor(_ color:UIColor, tintColor: UIColor){
        Qiscus.sharedInstance.styleConfiguration.color.topColor = color
        Qiscus.sharedInstance.styleConfiguration.color.bottomColor = color
        Qiscus.sharedInstance.styleConfiguration.color.tintColor = tintColor
        //TODO Need to fix
        //        for (_,chatView) in Qiscus.sharedInstance.chatViews {
        //            chatView.topColor = color
        //            chatView.bottomColor = color
        //            chatView.tintColor = tintColor
        //        }
    }
    
    /**
     Class function to set upload from iCloud active or not
     - parameter active: **Bool** to set active or not.
     */
    public func iCloudUploadActive(_ active:Bool){
        Qiscus.sharedInstance.iCloudUpload = active
    }
    
    
    /// unregister device token from service
    public func unRegisterDevice(){
        QiscusCore.shared.remove(deviceToken: QiscusClient.shared.token) { (unRegister, error) in
            self.configDelegate?.qiscus(didUnregisterPushNotification: unRegister, error: error?.message)
        }
    }
    
    //Todo need to be fix
    /**
     Logout Qiscus and clear all data with this function
     @func clearData()
     */
    public class func clear(){
        QiscusClient.clear()
        QiscusClient.hasRegisteredDeviceToken = false
        Qiscus.shared.unRegisterDevice()
        QiscusCore.logout { (error) in
            
        }
    }
    
    //TODO Need TO Be Implement
    /// register device token to sdk service
    ///
    /// - Parameter deviceToken: device token in string
    public func registerDevice(withToken deviceToken: String){
        Qiscus.qiscusDeviceToken = deviceToken
        Qiscus.client.deviceToken = deviceToken
        
    }
    
    //Todo need to be implement to call api update profile
    /// update qiscus user profile
    ///
    /// - Parameters:
    ///   - username: String username
    ///   - avatarURL: String avatar url
    ///   - onSuccess: @escaping on success update user profile
    ///   - onFailed: @escaping on error update user profile with error message
    public class func updateProfile(username:String? = nil, avatarURL:String? = nil, onSuccess:@escaping (()->Void), onFailed:@escaping ((String)->Void)) {
        
        var userName = ""
        if(userName != nil){
            userName = username!
        }
        if(avatarURL != nil){
            QiscusCore.shared.updateProfile(displayName: userName, avatarUrl: URL(string: avatarURL!)) { (qUser, error) in
                
            }
        }else{
            QiscusCore.shared.updateProfile(displayName: userName, avatarUrl: nil) { (qUser, error) in
                
            }
        }
        
        
    }
    
    /// create banner natification
    ///
    /// - Parameters:
    ///   - comment: QComment
    ///   - alertTitle: banner title
    ///   - alertBody: banner body
    ///   - userInfo: userInfo
    public func createLocalNotification(forComment comment:QComment, alertTitle:String? = nil, alertBody:String? = nil, userInfo:[AnyHashable : Any]? = nil){
        DispatchQueue.main.async {autoreleasepool{

            //TODO NEED TO BE IMPLEMENT
//            let localNotification = UILocalNotification()
//            if let title = alertTitle {
//                localNotification.alertTitle = title
//            }else{
//                localNotification.alertTitle = comment.username
//            }
//            if let body = alertBody {
//                localNotification.alertBody = body
//            }else{
//                localNotification.alertBody = comment.message
//            }
//
//            localNotification.soundName = "default"
//            var userData = [AnyHashable : Any]()
//
//            if userInfo != nil {
//                for (key,value) in userInfo! {
//                    userData[key] = value
//                }
//            }
//
//            let commentInfo = comment.encodeDictionary()
//            for (key,value) in commentInfo {
//                userData[key] = value
//            }
//            localNotification.userInfo = userData
//            localNotification.fireDate = Date().addingTimeInterval(0.4)
//            Qiscus.sharedInstance.application.scheduleLocalNotification(localNotification)
            }}
    }
    
    //Todo call QiscusUI
    /// get QiscusChatVC with array of username
    ///
    /// - Parameters:
    ///   - users: with array of client (username used on Qiscus.setup)
    ///   - readOnly: true => unable to access input view , false => able to access input view
    ///   - title: chat title
    ///   - subtitle: chat subtitle
    ///   - distinctId: -
    ///   - withMessage: predefined text message
    /// - Returns: QiscusChatVC to be presented or pushed
    public class func chatView(withUsers users:[String], readOnly:Bool = false, title:String = "", subtitle:String = "", distinctId:String = "", withMessage:String? = nil)->QiscusChatVC{
        
        let chatVC = QiscusChatVC()
        
        QiscusCore.shared.getRoom(withUser: users.first!) { (qRoom, error) in
            chatVC.room = qRoom
            chatVC.chatUser = users.first!
            if(title != ""){
                chatVC.chatTitle = title
            }
            if(subtitle != ""){
                chatVC.chatSubtitle = subtitle
            }
            chatVC.archived = readOnly
            if(withMessage != nil){
                chatVC.chatMessage = withMessage
            }
            if(withMessage != nil){
                chatVC.chatMessage = withMessage
            }
            if chatVC.isPresence {
                chatVC.back()
            }
            
        }
        return chatVC
    }
    
    /// get QiscusChatVC with room id
    ///
    /// - Parameters:
    ///   - users: array of user id
    ///   - readOnly: true => unable to access input view , false => able to access input view
    ///   - title: chat title
    ///   - subtitle: chat subtitle
    ///   - distinctId: -
    ///   - withMessage: predefined text message
    /// - Returns: QiscusChatVC to be presented or pushed
    public class func createChatView(withUsers users:[String], readOnly:Bool = false, title:String, subtitle:String = "", distinctId:String? = nil, optionalData:String?=nil, withMessage:String? = nil)->QiscusChatVC{
        if !Qiscus.sharedInstance.connected {
            Qiscus.setupReachability()
        }
        
        Qiscus.sharedInstance.isPushed = true
        
        let chatVC = QiscusChatVC()
        QiscusCore.shared.createGroup(withName: title, participants: users, avatarUrl: nil) { (qRoom, error) in
            if distinctId != nil{
                chatVC.chatDistinctId = distinctId!
            }else{
                chatVC.chatDistinctId = ""
            }
            chatVC.chatData         = optionalData
            chatVC.chatMessage      = withMessage
            chatVC.archived         = readOnly
            chatVC.chatNewRoomUsers = users
            chatVC.chatTitle        = title
            if(subtitle != ""){
                chatVC.chatSubtitle = subtitle
            }
            chatVC.room             = qRoom
            if chatVC.isPresence {
                chatVC.back()
            }
        }
        
        return chatVC
        
    }
    
    /// get QiscusChatVC with room id
    ///
    /// - Parameters:
    ///   - roomId: room id
    ///   - readOnly: true => unable to access input view , false => able to access input view
    ///   - title: chat title
    ///   - subtitle: chat subtitle
    ///   - distinctId: -
    ///   - withMessage: predefined text message
    /// - Returns: QiscusChatVC to be presented or pushed
    public class func chatView(withRoomId roomId:String, readOnly:Bool = false, title:String = "", subtitle:String = "", withMessage:String? = nil)->QiscusChatVC{
        if !Qiscus.sharedInstance.connected {
            Qiscus.setupReachability()
        }
        
        var chatVC = QiscusChatVC()
        
        if let chatView = Qiscus.sharedInstance.chatViews[roomId] {
            chatVC = chatView
        }else{
            chatVC.chatRoomId = roomId
        }
        if(title != ""){
            chatVC.chatTitle = title
        }
        if(subtitle != ""){
            chatVC.chatSubtitle = subtitle
        }
        chatVC.archived = readOnly
        if(withMessage != nil){
            chatVC.chatMessage = withMessage
        }
        
        return chatVC
    }
    
    public class func chatView(withRoomUniqueId uniqueId:String, readOnly:Bool = false, title:String = "", avatarUrl:String = "", subtitle:String = "", withMessage:String? = nil)->QiscusChatVC{
        
        let chatVC = QiscusChatVC()
        
        QiscusCore.shared.getRoom(withChannel: uniqueId) { (qRoom, error) in
            if !Qiscus.sharedInstance.connected {
                Qiscus.setupReachability()
            }
            Qiscus.sharedInstance.isPushed = true
            chatVC.room = qRoom
            if(title != ""){
                chatVC.chatTitle = title
            }
            if(subtitle != ""){
                chatVC.chatSubtitle = subtitle
            }
            if(withMessage != nil){
                chatVC.chatMessage = withMessage
            }
            if(avatarUrl != ""){
                chatVC.chatAvatarURL = avatarUrl
            }
            
            chatVC.archived = readOnly
            if chatVC.isPresence {
                chatVC.back()
            }
            
            chatVC.archived = readOnly

        }
        
        return chatVC
    }
    
    //will return qRooms and totalRooms
    public class func roomList(withLimit: Int, page: Int,onSuccess:@escaping (([QRoom],Int)->Void), onFailed: @escaping ((String)->Void)){
        QRoom.getAllRoom(withLimit: withLimit, page: page, onSuccess: { (qRoom, totalRoom) in
            onSuccess(qRoom,totalRoom)
        }) { (error) in
            onFailed(error)
        }
        
    }
    
    @objc public class func getNonce(withAppId appId:String, onSuccess:@escaping ((String)->Void), onFailed:@escaping ((String)->Void), secureURL:Bool = true){
        QiscusCore.setup(WithAppID: appId)
        QiscusCore.getNonce { (nonce, error) in
            if(nonce != nil){
                onSuccess((nonce?.nonce)!)
            }else{
                onFailed(error!)
            }
        }
    }
    
    //Todo need to implement to SDKCore
    @objc public class func setBaseURL(withURL url:String){
        
    }
    
    //Todo need to implement to SDKCore
    @objc public class func setRealtimeServer(withServer server:String, port:Int = 1883, enableSSL:Bool = false){
        
    }
    
    /// Create new Group room
    ///
    /// - Parameters:
    ///   - withName: Name of group
    ///   - participants: arrau of user id/qiscus email
    ///   - completion: Response Qiscus Room Object and error if exist.
    
    
    /// Create new Group room
    ///
    /// - Parameters:
    ///   - usersId: array of user id/qiscus email
    ///   - roomName: name of group
    ///   - avatarURL: avatar url of group
    ///   - onSuccess: response Qiscus Room Object
    ///   - onError: Response Qiscus error message
    public class func newRoom(withUsers usersId:[String], roomName: String, avatarURL:String = "", onSuccess:@escaping ((QRoom)->Void),onError:@escaping ((String)->Void)){
        if roomName.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
            
            if avatarURL.isEmpty {
                QiscusCore.shared.createGroup(withName: roomName, participants: usersId, avatarUrl: nil) { (qRoom, error) in
                    if let qRoomData = qRoom{
                        onSuccess(qRoomData as! QRoom)
                    }else{
                        if let errorMessage = error {
                            onError(errorMessage)
                        }
                    }
                }
            }else{
                QiscusCore.shared.createGroup(withName: roomName, participants: usersId, avatarUrl: URL(string: avatarURL)) { (qRoom, error) in
                    if let qRoomData = qRoom{
                        onSuccess(qRoomData as! QRoom)
                    }else{
                        if let errorMessage = error {
                            onError(errorMessage)
                        }
                    }
                }
            }
        }else{
            onError("room name can not be empty string")
        }
    }
    
    /// Get room with room id
    ///
    /// - Parameters:
    ///   - withID: existing roomID from server or local db.
    ///   - completion: Response Qiscus Room Object and error if exist.
    public class func roomInfo(withId id:String, onSuccess:@escaping ((QRoom)->Void), onError: @escaping ((String)->Void)){
        QiscusCore.shared.getRoom(withID: id) { (qRoom, error) in
            if(qRoom != nil){
                onSuccess(qRoom as! QRoom)
            }else{
                if let errorMessage = error {
                    onError(errorMessage.message)
                }
                
            }
        }
    }
    
    /// Get Room info
    ///
    /// - Parameters:
    ///   - withId: array of room id
    ///   - completion: Response new Qiscus Room Object and error if exist.
    public class func roomsInfo(withIds ids:[String], onSuccess:@escaping (([QRoom])->Void), onError: @escaping ((String)->Void)){
        QiscusCore.shared.getRooms(withId: ids) { (qRooms, error) in
            if(qRooms != nil){
                onSuccess(qRooms as! [QRoom])
            }else{
                if let errorMessage = error {
                    onError(errorMessage.message)
                }
            }
        }
    }
    
    /// Get room by channel name
    ///
    /// - Parameters:
    ///   - channel: channel name or channel id
    ///   - completion: Response Qiscus Room Object and error if exist.
    public class func channelInfo(withName name:String, onSuccess:@escaping ((QRoom)->Void), onError: @escaping ((String)->Void)){
        QiscusCore.shared.getRoom(withChannel: name) { (qRoom, error) in
            if(qRoom != nil){
                onSuccess(qRoom as! QRoom)
            }else{
                onError((error?.message)!)
            }
        }
    }
    
    /// Get Room info
    ///
    /// - Parameters:
    ///   - ids: Unique room id
    ///   - completion: Response new Qiscus Room Object and error if exist.
    public class func channelsInfo(withNames names:[String], onSuccess:@escaping (([QRoom])->Void), onError: @escaping ((String)->Void)){
        QiscusCore.shared.getRooms(withUniqueId: names) { (qRooms, error) in
            if(qRooms != nil){
                onSuccess(qRooms as! [QRoom])
            }else{
                onError((error?.message)!)
            }
        }
    }
    
    /// get all unread count
    ///
    /// - Parameters:
    ///   - onSuccess: success completion with unread count value
    ///   - onError: error completion with error message
    public class func getAllUnreadCount(onSuccess: @escaping ((_ unread: Int) -> Void), onError: @escaping ((_ error: String) -> Void)) {
        QiscusCore.shared.unreadCount { (unread, error) in
            if error == nil {
                onSuccess(unread)
            }else{
                if let errorMessage = error{
                    onError(errorMessage.message)
                }
            }
        }
    }
    
    
    /// add participants to room
    ///
    /// - Parameters:
    ///   - id: room id
    ///   - userIds: array of participant user id registered in qiscus sdk
    ///   - onSuccess: completion when successfully add participant
    ///   - onError: completion when failed add participant
    public class func addParticipant(onRoomId id: String, userEmails: [String], onSuccess:@escaping ([QMember])->Void, onError: @escaping (String)->Void) {
        QiscusCore.shared.addParticipant(userEmails: userEmails, roomId: id) { (qMembers, error) in
            if let qMembersData = qMembers {
                onSuccess(qMembersData as! [QMember])
            }else{
                if let errorMessage = error {
                    onError(errorMessage.message)
                }
            }
        }
    }
    
    
    /// remove participants from room
    ///
    /// - Parameters:
    ///   - id: room id
    ///   - userIds: array of participant user id registered in qiscus sdk
    ///   - onSuccess: completion bool when success delete participant
    ///   - onError: completion when failed delete participant
    public class func removeParticipant(onRoom id: String, userEmails: [String], onSuccess:@escaping (Bool)->Void, onError: @escaping (String)->Void) {
        QiscusCore.shared.removeParticipant(userEmails: userEmails, roomId: id) { (removed, error) in
            if error == nil {
                onSuccess(removed)
            }else{
                if let errorMessage = error {
                    onError(errorMessage.message)
                }
            }
            
        }
    }
    
    
    /// getList Participant
    ///
    /// - Parameters:
    ///   - id: roomId
    ///   - onSuccess: will return array QMember
    ///   - onError: will return error message
    public class func listParticipant(onRoom id: String, onSuccess:@escaping ([QMember])->Void, onError: @escaping (String)->Void){
        QiscusCore.shared.getParticipant(roomId: id) { (qMembersUser, error) in
            if let qMembers = qMembersUser {
                onSuccess(qMembers as! [QMember])
            }else{
                if let errorMessage = error {
                    onError(errorMessage.message)
                }
            }
        }
    }
    
    /// block user
    /// - Parameters:
    ///   - user_email
    public class func blockUser(user_email: String, onSuccess:@escaping(QMember)->Void, onError: @escaping (String)->Void) {
        QiscusCore.shared.blockUser(email: user_email) { (qMember, error) in
            if let qMemberUser = qMember {
                onSuccess(qMemberUser as! QMember)
            }else{
                if let errorMessage = error {
                    onError(errorMessage.message)
                }
            }
        }
    }
    
    /// unblock user
    /// - Parameters:
    ///   - user_email
    public class func unBlockUser(user_email: String, onSuccess:@escaping(QMember)->Void, onError: @escaping (String)->Void) {
        QiscusCore.shared.unblockUser(email: user_email) { (qMember, error) in
            if let qMemberUser = qMember {
                onSuccess(qMemberUser as! QMember)
            }else{
                if let errorMessage = error {
                    onError(errorMessage.message)
                }
            }
        }
    }
    
    /// list of block user
    /// - Parameters:
    ///   - token
    public class func getListBlockUser(page: Int? = 1, limit: Int? = 20, onSuccess:@escaping([QMember])->Void, onError: @escaping (String)->Void){
        QiscusCore.shared.listBlocked(page: page, limit: limit) { (qMembers, error) in
            if let qMemberUser = qMembers {
                onSuccess(qMemberUser as! [QMember])
            }else{
                if let errorMessage = error {
                    onError(errorMessage.message)
                }
            }
        }
    }
 
}
