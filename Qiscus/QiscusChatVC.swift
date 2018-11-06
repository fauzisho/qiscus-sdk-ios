//
//  QiscusChatVC.swift
//  Qiscus
//
//  Created by Qiscus on 07/08/18.
//

import UIKit
import QiscusUI
import QiscusCore
import SwiftyJSON
import ContactsUI
import Photos
import MobileCoreServices
    
struct UserNameColor {
    var userEmail            : String    = ""
    var color               : UIColor = UIColor.lightGray
}

public protocol QiscusChatVCCellDelegate{
    func chatVC(viewController:QiscusChatVC, didTapLinkButtonWithURL url:URL )
    
//    func didTapCell(viewController:QiscusChatVC, withData data: CommentModel)
//    func didTouchLink(viewController:QiscusChatVC, onCell cell: UIBaseChatCell)
    func didTapPostbackButton(viewController:QiscusChatVC, withData data: JSON)
    func didTapAccountLinking(viewController:QiscusChatVC, withData data: JSON)
//    func didTapSaveContact(viewController:QiscusChatVC, withData data:CommentModel)
//    func didShare(viewController:QiscusChatVC, comment: CommentModel)
//    func didForward(viewController:QiscusChatVC, comment: CommentModel)
//    func didReply(viewController:QiscusChatVC, comment:CommentModel)
//    func getInfo(viewController:QiscusChatVC, comment:CommentModel)
//    func didTapFile(viewController:QiscusChatVC, comment: CommentModel)
}

public protocol QiscusChatVCConfigDelegate{
//    func chatVCConfigDelegate(usingSoftDeleteOn viewController:QiscusChatVC)->Bool
//    func chatVCConfigDelegate(deletedMessageTextFor viewController:QiscusChatVC, selfMessage isSelf:Bool)->String
//    func chatVCConfigDelegate(enableReplyMenuItem viewController:QiscusChatVC, forComment comment: CommentModel)->Bool
//    func chatVCConfigDelegate(enableForwardMenuItem viewController:QiscusChatVC, forComment comment: CommentModel)->Bool
//    func chatVCConfigDelegate(enableResendMenuItem viewController:QiscusChatVC, forComment comment: CommentModel)->Bool
//    func chatVCConfigDelegate(enableDeleteMenuItem viewController:QiscusChatVC, forComment comment: CommentModel)->Bool
//    func chatVCConfigDelegate(enableDeleteForMeMenuItem viewController:QiscusChatVC, forComment comment: CommentModel)->Bool
//    func chatVCConfigDelegate(enableShareMenuItem viewController:QiscusChatVC, forComment comment: CommentModel)->Bool
//    func chatVCConfigDelegate(enableInfoMenuItem viewController:QiscusChatVC, forComment comment: CommentModel)->Bool
//    
//    func chatVCConfigDelegate(usingNavigationSubtitleTyping viewController:QiscusChatVC)->Bool
//    func chatVCConfigDelegate(usingTypingCell viewController:QiscusChatVC)->Bool
    
}

public protocol QiscusChatVCDelegate{
    // MARK : Review this
    func chatVC(enableForwardAction viewController:QiscusChatVC)->Bool
    func chatVC(enableInfoAction viewController:QiscusChatVC)->Bool
    func chatVC(overrideBackAction viewController:QiscusChatVC)->Bool
    //
    func chatVC(backAction viewController:QiscusChatVC, room:RoomModel?, data:Any?)
    func chatVC(titleAction viewController:QiscusChatVC, room:RoomModel?, data:Any?)
    func chatVC(viewController:QiscusChatVC, onForwardComment comment:CommentModel, data:Any?)
    func chatVC(viewController:QiscusChatVC, infoActionComment comment:CommentModel,data:Any?)
    
    func chatVC(onViewDidLoad viewController:QiscusChatVC)
    func chatVC(viewController:QiscusChatVC, willAppear animated:Bool)
    func chatVC(viewController:QiscusChatVC, willDisappear animated:Bool)
    func chatVC(didTapAttachment actionSheet: UIAlertController, viewController: QiscusChatVC, onRoom: RoomModel?)
    
    func chatVC(viewController:QiscusChatVC, willPostComment comment:CommentModel, room:RoomModel?, data:Any?)->CommentModel?
    
    func chatVC(viewController:QiscusChatVC, didFailLoadRoom error:String)
}

public class QiscusChatVC: UIChatViewController {
    //TODO NEED TO BE IMPLEMENT
    public var delegate:QiscusChatVCDelegate?
    public var configDelegate:QiscusChatVCConfigDelegate?
    public var cellDelegate:QiscusChatVCCellDelegate?
    public var isPresence:Bool = false
    public var chatDistinctId:String?
    public var chatData:String?
    public var chatMessage:String?
    
    public var archived:Bool = QiscusUIConfiguration.sharedInstance.readOnly
    public var chatNewRoomUsers:[String] = [String]()
    public var chatTitle:String?
    public var chatSubtitle:String?
    public var chatAvatarURL : String?
    public var chatUser:String?
    public var data:Any?
    public var chatRoomId:String?
    //public var chatTarget:CommentModel?
    var didFindLocation = true
    let locationManager = CLLocationManager()
    var presentingLoading = false
    var inputBar = CustomChatInput()
    
    var latestNavbarTint = UINavigationBar.appearance().tintColor
    internal var currentNavbarTint = UINavigationBar.appearance().tintColor
    //static let currentNavbarTint = UINavigationBar.appearance().tintColor
    let picker = UIImagePickerController()
    var UTIs:[String]{
        get{
            return ["public.jpeg", "public.png","com.compuserve.gif","public.text", "public.archive", "com.microsoft.word.doc", "com.microsoft.excel.xls", "com.microsoft.powerpoint.​ppt", "com.adobe.pdf","public.mpeg-4"]
        }
    }
    

    @objc func back() {
        self.isPresence = false
        view.endEditing(true)
        if let delegate = self.delegate{
            if delegate.chatVC(overrideBackAction: self){
                delegate.chatVC(backAction: self, room: self.room as! RoomModel, data: data)
            }else{
                let _ = self.navigationController?.popViewController(animated: true)
            }
        }else{
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    var replyData:CommentModel? = nil {
        didSet{
            inputBar.replyData = replyData
        }
    }
    
    @objc public func showLoading(_ text:String = "Loading"){
        if !self.presentingLoading {
            self.presentingLoading = true
            self.showQiscusLoading(withText: text, isBlocking: true)
        }
    }
    @objc public func dismissLoading(){
        self.presentingLoading = false
        self.dismissQiscusLoading()
    }

    public override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        if let delegate = self.delegate{
            delegate.chatVC(viewController: self, willAppear: animated)
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let delegate = self.delegate{
            delegate.chatVC(viewController: self, willDisappear: animated)
        }
    }
    
    public override func viewDidLoad() {
        self.chatDelegate = self
        // Set delegate before super
        super.viewDidLoad()
        if (room == nil){
            if let roomid = chatRoomId  {
                // loading
                //self.showLoading()
                QiscusCore.shared.getRoom(withID: roomid, onSuccess: { (roomModel, _) in
                    //self.dismissLoading()
                    self.room = roomModel
                    self.setupNavigationTitle()
                }) { (error) in
                    //self.dismissLoading()
                    Qiscus.printLog(text: "error load room \(String(describing: error.message))")
                }
            }
        }
        
        self.setupUI()
        NotificationCenter.default.addObserver(self, selector:#selector(willEnterFromForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        if let delegate = self.delegate{
            delegate.chatVC(onViewDidLoad: self)
        }
        
        if let room = self.room{
            if room.participants?.count != 0 {
                if let participants = room.participants {
                    for participant in participants.enumerated(){
                        if Qiscus.shared.usersColor.count == 0{
                            var data = UserNameColor()
                            data.userEmail = participant.element.email
                            data.color = Qiscus.style.color.randomColorLabelName.randomItem()!
                            Qiscus.shared.usersColor.append(data)
                        }else{
                            let user = Qiscus.shared.usersColor.filter( { return $0.userEmail == participant.element.email } )
                            
                            if(user.count == 0){
                                var data = UserNameColor()
                                data.userEmail = participant.element.email
                                data.color = Qiscus.style.color.randomColorLabelName.randomItem()!
                                Qiscus.shared.usersColor.append(data)
                            }
                        }
                    }
                }
                
                
            }
            
        }
    }
    
    @objc func willEnterFromForeground(){
        self.tabBarController?.tabBar.isHidden = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupUI(){
         self.setupBackgroundChat()
         self.registerCell()
         self.setupNavigationTitle()
         self.setupNotification()
         self.setupChatInput()
        
    }
    
    func setupBackgroundChat(){
        self.setBackground(with: Qiscus.style.assets.backgroundChat!)
    }
    
    func setupChatInput(){
        picker.delegate = self
    }
    
    func setupNotification(){
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(QiscusChatVC.didSaveContact(_:)), name: QiscusNotification.DID_TAP_SAVE_CONTACT, object: nil)
        center.addObserver(self, selector: #selector(QiscusChatVC.didClickReply(_:)), name: QiscusNotification.DID_TAP_MENU_REPLY, object: nil)
        center.addObserver(self, selector: #selector(QiscusChatVC.didClickShare(_:)), name: QiscusNotification.DID_TAP_MENU_SHARE, object: nil)
        center.addObserver(self, selector: #selector(QiscusChatVC.didClickInfo(_:)), name: QiscusNotification.DID_TAP_MENU_INFO, object: nil)
        center.addObserver(self, selector: #selector(QiscusChatVC.didClickForward(_:)), name: QiscusNotification.DID_TAP_MENU_FORWARD, object: nil)
        
    }
    
    @objc private func didClickReply(_ notification: Notification){
        if let userInfo = notification.userInfo {
            let comment = userInfo["comment"] as! CommentModel
            
            self.replyData = comment
            if Qiscus.shared.usersColor.count != 0{
                for user in Qiscus.shared.usersColor.enumerated(){
                    if(self.replyData?.userEmail == user.element.userEmail){
                        self.inputBar.colorName = user.element.color
                    }
                }
            }
            self.inputBar.showPreviewReply()
            
        }
    }
    
    @objc private func didSaveContact(_ notification: Notification){
        if let userInfo = notification.userInfo {
            let comment = userInfo["comment"] as! CommentModel
            let payload = JSON(comment.payload)
            let contactValue = payload["value"].stringValue
            
            let con = CNMutableContact()
            con.givenName = payload["name"].stringValue
            if contactValue.contains("@"){
                let email = CNLabeledValue(label: CNLabelHome, value: contactValue as NSString)
                con.emailAddresses.append(email)
            }else{
                let phone = CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: contactValue))
                con.phoneNumbers.append(phone)
            }
            
            let unkvc = CNContactViewController.init(forNewContact: con)
            unkvc.message = "New Contact"
            unkvc.contactStore = CNContactStore()
            unkvc.delegate = self
            unkvc.allowsActions = false
            self.navigationController?.navigationBar.backgroundColor =  Qiscus.shared.styleConfiguration.color.topColor
            self.navigationController?.pushViewController(unkvc, animated: true)
        }
    }
    
    @objc private func didClickInfo(_ notification: Notification){
        if let userInfo = notification.userInfo {
            let comment = userInfo["comment"] as! CommentModel
            if let delegate = self.delegate{
                delegate.chatVC(viewController: self, infoActionComment: comment, data: data)
            }
        }
    }
    
    @objc private func didClickForward(_ notification: Notification){
        if let userInfo = notification.userInfo {
            let comment = userInfo["comment"] as! CommentModel
            if let delegate = self.delegate{
                delegate.chatVC(viewController: self, onForwardComment: comment, data: data)
            }
        }
    }
    
    @objc private func didClickShare(_ notification: Notification){
        if let userInfo = notification.userInfo {
            let comment = userInfo["comment"] as! CommentModel
            
            switch comment.type {
            case "file_attachment":
                guard let payload = comment.payload else {
                    return
                }
                let fileURL = payload["url"] as? String
                
                if let fileURL = NSURL(string: fileURL!) {
                    let items:[Any] = [fileURL]
                    let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
                    
                    activityViewController.popoverPresentationController?.sourceView = self.view
                    self.present(activityViewController, animated: true, completion: nil)
                }
                break
            case "text":
                let activityViewController = UIActivityViewController(activityItems: [comment.message], applicationActivities: nil)
                
                activityViewController.popoverPresentationController?.sourceView = self.view
                self.present(activityViewController, animated: true, completion: nil)
                break
            default:
                break
            }
            
        }
    }
    
    func registerCell() {
        self.registerClass(nib: UINib(nibName: "QTextRightCell", bundle: Qiscus.bundle), forMessageCellWithReuseIdentifier: "qTextRightCell")
        self.registerClass(nib: UINib(nibName: "QTextLeftCell", bundle: Qiscus.bundle), forMessageCellWithReuseIdentifier: "qTextLeftCell")
        self.registerClass(nib: UINib(nibName: "QImageLeftCell", bundle: Qiscus.bundle), forMessageCellWithReuseIdentifier: "qImageLeftCell")
        self.registerClass(nib: UINib(nibName: "QImageRightCell", bundle: Qiscus.bundle), forMessageCellWithReuseIdentifier: "qImageRightCell")
        self.registerClass(nib: UINib(nibName: "QDocumentLeftCell", bundle: Qiscus.bundle), forMessageCellWithReuseIdentifier: "qDocumentLeftCell")
        self.registerClass(nib: UINib(nibName: "QDocumentRightCell", bundle: Qiscus.bundle), forMessageCellWithReuseIdentifier: "qDocumentRightCell")
        self.registerClass(nib: UINib(nibName: "QSystemCell", bundle: Qiscus.bundle), forMessageCellWithReuseIdentifier: "qSystemCell")
        self.registerClass(nib: UINib(nibName: "QReplyLeftCell", bundle: Qiscus.bundle), forMessageCellWithReuseIdentifier: "qReplyLeftCell")
        self.registerClass(nib: UINib(nibName: "QReplyRightCell", bundle: Qiscus.bundle), forMessageCellWithReuseIdentifier: "qReplyRightCell")
        self.registerClass(nib: UINib(nibName: "QLocationLeftCell", bundle: Qiscus.bundle), forMessageCellWithReuseIdentifier: "qLocationLeftCell")
        self.registerClass(nib: UINib(nibName: "QLocationRightCell", bundle: Qiscus.bundle), forMessageCellWithReuseIdentifier: "qLocationRightCell")
        self.registerClass(nib: UINib(nibName: "QContactLeftCell", bundle: Qiscus.bundle), forMessageCellWithReuseIdentifier: "qContactLeftCell")
        self.registerClass(nib: UINib(nibName: "QContactRightCell", bundle: Qiscus.bundle), forMessageCellWithReuseIdentifier: "qContactRightCell")
        self.registerClass(nib: UINib(nibName: "QAudioLeftCell", bundle: Qiscus.bundle), forMessageCellWithReuseIdentifier: "qAudioLeftCell")
        self.registerClass(nib: UINib(nibName: "QAudioRightCell", bundle: Qiscus.bundle), forMessageCellWithReuseIdentifier: "qAudioRightCell")
        self.registerClass(nib: UINib(nibName: "QPostbackLeftCell", bundle: Qiscus.bundle), forMessageCellWithReuseIdentifier: "postBack")
        self.registerClass(nib: UINib(nibName: "QCarouselCell", bundle: Qiscus.bundle), forMessageCellWithReuseIdentifier: "qCarouselCell")
        
    }
    
    private func setupNavigationTitle(){
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = false
        }
        var totalButton = 1
        if let leftButtons = self.navigationItem.leftBarButtonItems {
            totalButton += leftButtons.count
        }
        if let rightButtons = self.navigationItem.rightBarButtonItems {
            totalButton += rightButtons.count
        }
        
        let backButton = self.backButton(self, action: #selector(self.back))
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationItem.leftBarButtonItems = [backButton]
        
        if chatTitle != nil {
            self.titleLabel.text = chatTitle
        }
        
        if chatSubtitle != nil {
            self.subtitleLabel.text = chatSubtitle
        }
        
        if chatAvatarURL != nil {
            self.roomAvatar.af_setImage(withURL: URL(string: chatAvatarURL!)!)
        }
        
        self.titleLabel.textColor       = Qiscus.style.color.tintColor
        self.subtitleLabel.textColor    = Qiscus.style.color.tintColor
        self.titleLabel.font            = titleLabel.font.withSize(14)
        self.subtitleLabel.font         = subtitleLabel.font.withSize(12)
       
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapFunction))
        titleLabel.isUserInteractionEnabled = true
        titleLabel.addGestureRecognizer(tap)
        
    }
    
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        if let delegate = self.delegate {
            delegate.chatVC(titleAction: self, room: room, data: self.data)
        }
    }
    
    private func backButton(_ target: UIViewController, action: Selector) -> UIBarButtonItem{
        let backIcon = UIImageView()
        backIcon.contentMode = .scaleAspectFit
        
        let image = QiscusUI.image(named: "ic_back")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        backIcon.image = image
        backIcon.tintColor = UINavigationBar.appearance().tintColor
        
        if UIApplication.shared.userInterfaceLayoutDirection == .leftToRight {
            backIcon.frame = CGRect(x: 0,y: 11,width: 13,height: 22)
        }else{
            backIcon.frame = CGRect(x: 22,y: 11,width: 13,height: 22)
        }
        
        let backButton = UIButton(frame:CGRect(x: 0,y: 0,width: 23,height: 44))
        backButton.addSubview(backIcon)
        backButton.addTarget(target, action: action, for: UIControlEvents.touchUpInside)
        return UIBarButtonItem(customView: backButton)
    }
    
    func getType(message: CommentModel) -> QiscusFileType{
        let json = message.payload
        var type = QiscusFileType.file
        guard let payload = message.payload else {
            return type
        }
        let fileURL = payload["url"] as? String
        var filename = CommentModel().fileName(text: fileURL!)
        
        if filename.contains("-"){
            let nameArr = filename.split(separator: "-")
            var i = 0
            for comp in nameArr {
                switch i {
                case 0 : filename = "" ; break
                case 1 : filename = "\(String(comp))"
                default: filename = "\(filename)-\(comp)"
                }
                i += 1
            }
        }
        
        var ext = ""
        if filename.range(of: ".") != nil{
            let fileNameArr = filename.split(separator: ".")
            ext = String(fileNameArr.last!).lowercased()
        }
        
        switch ext {
        case "jpg","jpeg","jpg_","png","png_","gif","gif_", "heic":
            type = QiscusFileType.image
        case "mov","mov_","mp4","mp4_":
            type = QiscusFileType.video
        case "m4a","m4a_","aac","aac_","mp3","mp3_":
            type = QiscusFileType.audio
        case "pdf","pdf_":
            type = QiscusFileType.pdf
        default:
            type = QiscusFileType.file
        }
        
        return type
    }
    
}

extension QiscusChatVC : UIChatView {
    public func uiChat(viewController: UIChatViewController, performAction action: Selector, forRowAt message: CommentModel, withSender sender: Any?) {
        if action == #selector(UIResponderStandardEditActions.copy(_:)) {
            let pasteboard = UIPasteboard.general
            pasteboard.string = message.message
        }
    }
    
    public func uiChat(viewController: UIChatViewController, canPerformAction action: Selector, forRowAtmessage: CommentModel, withSender sender: Any?) -> Bool {
        switch action.description {
        case "copy:":
            return true
        case "reply:":
            return true
        case "forward:":
            return true
        case "share:":
            return true
        case "info:":
            return true
        case "deleteComment:":
            return true
        case "deleteCommentForMe:":
            return true
        default:
            return false
        }
    }
    
    public func uiChat(viewController: UIChatViewController, cellForMessage message: CommentModel) -> UIBaseChatCell? {
        var colorName:UIColor = UIColor.lightGray
        if Qiscus.shared.usersColor.count != 0{
                let user = Qiscus.shared.usersColor.filter( { return $0.userEmail == message.userEmail } )
                if(user.count != 0){
                    colorName = (user.first?.color)!
                }
        }
        
        var menuConfig = enableMenuConfig()
        if let isEnable = delegate?.chatVC(enableInfoAction: self) {
            menuConfig.info = isEnable
        }
        
        if let isEnable = delegate?.chatVC(enableForwardAction: self) {
            menuConfig.forward = isEnable
        }
        
        if message.type == "text" {
            if (message.isMyComment() == true){
                let cell =  self.reusableCell(withIdentifier: "qTextRightCell", for: message) as! QTextRightCell
                cell.menuConfig = menuConfig
                return cell
            }else{
                let cell = self.reusableCell(withIdentifier: "qTextLeftCell", for: message) as! QTextLeftCell
                if self.room?.type == .group {
                    cell.colorName = colorName
                    cell.isPublic = true
                }else {
                    cell.isPublic = false
                }
                return cell
            }
        }else if message.type == "file_attachment" {
            let type = self.getType(message: message)
            switch type {
            case .image:
                if (message.isMyComment() == true){
                    let cell =  self.reusableCell(withIdentifier: "qImageRightCell", for: message) as! QImageRightCell
                    cell.menuConfig = menuConfig
                    return cell
                }else{
                    let cell = self.reusableCell(withIdentifier: "qImageLeftCell", for: message) as! QImageLeftCell
                        cell.menuConfig = menuConfig
                    if self.room?.type == .group {
                        cell.isPublic = true
                        cell.colorName = colorName
                    }else {
                        cell.isPublic = false
                    }
                    
                    return cell
                }
            case .video:
                if (message.isMyComment() == true){
                    let cell =  self.reusableCell(withIdentifier: "qDocumentRightCell", for: message) as! QDocumentRightCell
                    cell.menuConfig = menuConfig
                    return cell
                }else{
                    let cell = self.reusableCell(withIdentifier: "qDocumentLeftCell", for: message) as! QDocumentLeftCell
                    cell.menuConfig = menuConfig
                    if self.room?.type == .group {
                        cell.colorName = colorName
                        cell.isPublic = true
                    }else {
                        cell.isPublic = false
                    }
                    return cell
                }
            case .audio:
                if (message.isMyComment() == true){
                    let cell = self.reusableCell(withIdentifier: "qAudioRightCell", for: message) as! QAudioRightCell
                    cell.menuConfig = menuConfig
                    return cell
                }else{
                    let cell = self.reusableCell(withIdentifier: "qAudioLeftCell", for: message) as! QAudioLeftCell
                    cell.menuConfig = menuConfig
                    if self.room?.type == .group {
                        cell.colorName = colorName
                        cell.isPublic = true
                    }else {
                        cell.isPublic = false
                    }
                    return cell
                }
            case .pdf:
                if (message.isMyComment() == true){
                    let cell =  self.reusableCell(withIdentifier: "qDocumentRightCell", for: message) as! QDocumentRightCell
                    cell.menuConfig = menuConfig
                    return cell
                }else{
                    let cell = self.reusableCell(withIdentifier: "qDocumentLeftCell", for: message) as! QDocumentLeftCell
                    if self.room?.type == .group {
                        cell.colorName = colorName
                        cell.isPublic = true
                    }else {
                        cell.isPublic = false
                    }
                    cell.menuConfig = menuConfig
                    return cell
                }
            case .document:
                if (message.isMyComment() == true){
                    let cell = self.reusableCell(withIdentifier: "qDocumentRightCell", for: message) as! QDocumentRightCell
                    cell.menuConfig = menuConfig
                    return cell
                }else{
                    let cell = self.reusableCell(withIdentifier: "qDocumentLeftCell", for: message) as! QDocumentLeftCell
                    if self.room?.type == .group {
                        cell.colorName = colorName
                        cell.isPublic = true
                    }else {
                        cell.isPublic = false
                    }
                    cell.menuConfig = menuConfig
                    return cell
                }
            default:
                if (message.isMyComment() == true){
                    let cell = self.reusableCell(withIdentifier: "qDocumentRightCell", for: message) as! QDocumentRightCell
                    cell.menuConfig = menuConfig
                    return cell
                }else{
                    let cell = self.reusableCell(withIdentifier: "qDocumentLeftCell", for: message) as! QDocumentLeftCell
                    if self.room?.type == .group {
                        cell.colorName = colorName
                        cell.isPublic = true
                    }else {
                        cell.isPublic = false
                    }
                    cell.menuConfig = menuConfig
                    return cell
                }
            }
        }else if message.type == "system_event" {
            return self.reusableCell(withIdentifier: "qSystemCell", for: message) as! QSystemCell
        }else if message.type == "reply" {
            if (message.isMyComment() == true){
                let cell = self.reusableCell(withIdentifier: "qReplyRightCell", for: message) as! QReplyRightCell
                cell.menuConfig = menuConfig
                cell.delegateChat = self
                return cell
            }else{
                let cell = self.reusableCell(withIdentifier: "qReplyLeftCell", for: message) as! QReplyLeftCell
                if self.room?.type == .group {
                    cell.isPublic = true
                    cell.colorName = colorName
                }else {
                    cell.isPublic = false
                }
                cell.delegateChat = self
                cell.menuConfig = menuConfig
                return cell
            }
            
        }else if message.type == "location" {
            if (message.isMyComment() == true){
                let cell =  self.reusableCell(withIdentifier: "qLocationRightCell", for: message) as! QLocationRightCell
                cell.menuConfig = menuConfig
                return cell
            }else{
                let cell = self.reusableCell(withIdentifier: "qLocationLeftCell", for: message) as! QLocationLeftCell
                cell.menuConfig = menuConfig
                cell.colorName = colorName
                return cell
            }
        }else if message.type == "contact_person" {
            if (message.isMyComment() == true){
                let cell =  self.reusableCell(withIdentifier: "qContactRightCell", for: message) as! QContactRightCell
                cell.menuConfig = menuConfig
                return cell
            }else{
                let cell = self.reusableCell(withIdentifier: "qContactLeftCell", for: message) as! QContactLeftCell
                cell.menuConfig = menuConfig
                if self.room?.type == .group {
                    cell.isPublic = true
                    cell.colorName = colorName
                }else {
                    cell.isPublic = false
                }
                return cell
            }
        }else if message.type == "account_linking" {
            let cell = self.reusableCell(withIdentifier: "postBack", for: message) as! QPostbackLeftCell
            cell.delegateChat = self
            return cell
        }else if message.type == "buttons" {
            let cell = self.reusableCell(withIdentifier: "postBack", for: message) as! QPostbackLeftCell
            cell.delegateChat = self
            return cell
        }else if message.type == "button_postback_response" {
            let cell =  self.reusableCell(withIdentifier: "qTextRightCell", for: message) as! QTextRightCell
            cell.menuConfig = menuConfig
            return cell
        }else if message.type == "carousel" ||  message.type == "card" {
            let cell =  self.reusableCell(withIdentifier: "qCarouselCell", for: message) as! QCarouselCell
            cell.delegateChat = self
            return cell
        }else {
            Qiscus.printLog(text: "message.type =\(message.type)")
            return nil
        }
    }
    
    public func uiChat(viewController: UIChatViewController, didSelectMessage message: CommentModel) {
        //
    }
    
    public func uiChat(viewController: UIChatViewController, firstMessage message: CommentModel, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    public func uiChat(input InViewController: UIChatViewController) -> UIChatInput? {
        let sendImage = Qiscus.image(named: "send")?.withRenderingMode(.alwaysTemplate)
        let attachmentImage = Qiscus.image(named: "share_attachment")?.withRenderingMode(.alwaysTemplate)
        let cancel = Qiscus.image(named: "ar_cancel")?.withRenderingMode(.alwaysTemplate)
        inputBar.sendButton.setImage(sendImage, for: .normal)
        inputBar.attachButton.setImage(attachmentImage, for: .normal)
        inputBar.cancelReplyPreviewButton.setImage(cancel, for: .normal)
        
        inputBar.sendButton.tintColor = Qiscus.shared.styleConfiguration.color.topColor
        inputBar.attachButton.tintColor = Qiscus.shared.styleConfiguration.color.topColor
         inputBar.cancelReplyPreviewButton.tintColor = Qiscus.shared.styleConfiguration.color.topColor
        inputBar.delegate = self
        inputBar.hidePreviewReply()
        return inputBar
    }
    
}

extension QiscusChatVC: CNContactViewControllerDelegate{
    public func contactViewController(_ viewController: CNContactViewController, shouldPerformDefaultActionFor property: CNContactProperty) -> Bool {
        return true
    }
    
    public func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        viewController.navigationController?.popViewController(animated: true)
    }
}

extension QiscusChatVC : CustomChatInputDelegate {
    func sendMessage(message: CommentModel) {
        var postedComment = message
        if let delegate = self.delegate{
            if let comment = delegate.chatVC(viewController: self, willPostComment: message, room: self.room, data: self.data){
                postedComment = comment
            }
        }
        
        self.send(message: postedComment, onSuccess: { (comment) in
            //success
        }) { (error) in
            //error
        }
    }
    
    func sendAttachment() {
        let optionMenu = UIAlertController()
        if Qiscus.shared.cameraUpload {
            let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.uploadFromCamera()
            })
            optionMenu.addAction(cameraAction)
        }
       
        if Qiscus.shared.galeryUpload {
            let galleryAction = UIAlertAction(title: "Photo & Video Library", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.uploadImage()
            })
            optionMenu.addAction(galleryAction)
        }
        if Qiscus.sharedInstance.iCloudUpload {
            let docAction = UIAlertAction(title: "Document", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.iCloudOpen()
            })
            optionMenu.addAction(docAction)
        }
        
        if Qiscus.shared.contactShare {
            let contactAction = UIAlertAction(title: "Contact", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.getContact()
            })
            optionMenu.addAction(contactAction)
        }
       
        if Qiscus.shared.locationShare {
            let locationAction = UIAlertAction(title: "Location", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.getLocation()
            })
            optionMenu.addAction(locationAction)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            
        })
        
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func iCloudOpen(){
        if Qiscus.sharedInstance.connected{
            if #available(iOS 11.0, *) {
                self.latestNavbarTint = self.currentNavbarTint
                UINavigationBar.appearance().tintColor = UIColor.blue
            }
            
            let documentPicker = UIDocumentPickerViewController(documentTypes: self.UTIs, in: UIDocumentPickerMode.import)
            documentPicker.delegate = self
            documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
            self.present(documentPicker, animated: true, completion: nil)
        }else{
            self.showNoConnectionToast()
        }
    }
    
    func uploadImage(){
        view.endEditing(true)
        if Qiscus.sharedInstance.connected{
            let photoPermissions = PHPhotoLibrary.authorizationStatus()
            
            if(photoPermissions == PHAuthorizationStatus.authorized){
                self.goToGaleryPicker()
            }else if(photoPermissions == PHAuthorizationStatus.notDetermined){
                PHPhotoLibrary.requestAuthorization({(status:PHAuthorizationStatus) in
                    switch status{
                    case .authorized:
                        self.goToGaleryPicker()
                        break
                    case .denied:
                        self.showPhotoAccessAlert()
                        break
                    default:
                        self.showPhotoAccessAlert()
                        break
                    }
                })
            }else{
                self.showPhotoAccessAlert()
            }
        }else{
            self.showNoConnectionToast()
        }
    }
    
    func goToGaleryPicker(){
        DispatchQueue.main.async(execute: {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.allowsEditing = false
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            picker.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
            self.present(picker, animated: true, completion: nil)
        })
    }
    
    func uploadFromCamera(){
        view.endEditing(true)
        if Qiscus.sharedInstance.connected{
            if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) ==  AVAuthorizationStatus.authorized
            {
                DispatchQueue.main.async(execute: {
                    let picker = UIImagePickerController()
                    picker.delegate = self
                    picker.allowsEditing = false
                    picker.mediaTypes = [(kUTTypeImage as String),(kUTTypeMovie as String)]
                    
                    picker.sourceType = UIImagePickerControllerSourceType.camera
                    self.present(picker, animated: true, completion: nil)
                })
            }else{
                AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted :Bool) -> Void in
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        if granted {
                            PHPhotoLibrary.requestAuthorization({(status:PHAuthorizationStatus) in
                                switch status{
                                case .authorized:
                                    let picker = UIImagePickerController()
                                    picker.delegate = self
                                    picker.allowsEditing = false
                                    picker.mediaTypes = [(kUTTypeImage as String),(kUTTypeMovie as String)]
                                    
                                    picker.sourceType = UIImagePickerControllerSourceType.camera
                                    self.present(picker, animated: true, completion: nil)
                                    break
                                case .denied:
                                    self.showPhotoAccessAlert()
                                    break
                                default:
                                    self.showPhotoAccessAlert()
                                    break
                                }
                            })
                        }else{
                            DispatchQueue.main.async(execute: {
                                self.showCameraAccessAlert()
                            })
                        }
                    }else{
                        //no camera
                    }
                    
                })
            }
        }else{
            self.showNoConnectionToast()
        }
    }
    
    private func getContact() {
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = self
        contactPicker.displayedPropertyKeys =
            [CNContactGivenNameKey
                , CNContactPhoneNumbersKey]
        self.present(contactPicker, animated: true, completion: nil)
    }
    
    private func getLocation() {
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways, .authorizedWhenInUse:
                self.showLoading("Loading...")
                
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                self.didFindLocation = false
                self.locationManager.startUpdatingLocation()
                break
            case .denied:
                self.showLocationAccessAlert()
                break
            case .restricted:
                self.showLocationAccessAlert()
                break
            case .notDetermined:
                self.showLocationAccessAlert()
                break
            }
        }else{
            self.showLocationAccessAlert()
        }
    }
    
    
    public func postReceivedFile(fileUrl: URL) {
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(readingItemAt: fileUrl, options: NSFileCoordinator.ReadingOptions.forUploading, error: nil) { (dataURL) in
            do{
                var data:Data = try Data(contentsOf: dataURL, options: NSData.ReadingOptions.mappedIfSafe)
                let mediaSize = Double(data.count) / 1024.0
                
                if mediaSize > Qiscus.maxUploadSizeInKB {
                    self.showFileTooBigAlert()
                    return
                }
                
                var fileName = dataURL.lastPathComponent.replacingOccurrences(of: "%20", with: "_")
                fileName = fileName.replacingOccurrences(of: " ", with: "_")
                
                var popupText = QiscusTextConfiguration.sharedInstance.confirmationImageUploadText
                var fileType = QiscusFileType.image
                var thumb:UIImage? = nil
                let fileNameArr = (fileName as String).split(separator: ".")
                let ext = String(fileNameArr.last!).lowercased()
                
                let gif = (ext == "gif" || ext == "gif_")
                let video = (ext == "mp4" || ext == "mp4_" || ext == "mov" || ext == "mov_")
                let isImage = (ext == "jpg" || ext == "jpg_" || ext == "tif" || ext == "heic" || ext == "png" || ext == "png_")
                let isPDF = (ext == "pdf" || ext == "pdf_")
                var usePopup = false
                
                if isImage{
                    var i = 0
                    for n in fileNameArr{
                        if i == 0 {
                            fileName = String(n)
                        }else if i == fileNameArr.count - 1 {
                            fileName = "\(fileName).jpg"
                        }else{
                            fileName = "\(fileName).\(String(n))"
                        }
                        i += 1
                    }
                    let image = UIImage(data: data)!
                    let imageSize = image.size
                    var bigPart = CGFloat(0)
                    if(imageSize.width > imageSize.height){
                        bigPart = imageSize.width
                    }else{
                        bigPart = imageSize.height
                    }
                    
                    var compressVal = CGFloat(1)
                    if(bigPart > 2000){
                        compressVal = 2000 / bigPart
                    }
                    data = UIImageJPEGRepresentation(image, compressVal)!
                    thumb = UIImage(data: data)
                }else if isPDF{
                    usePopup = true
                    popupText = "Are you sure to send this document?"
                    fileType = QiscusFileType.document
                    if let provider = CGDataProvider(data: data as NSData) {
                        if let pdfDoc = CGPDFDocument(provider) {
                            if let pdfPage:CGPDFPage = pdfDoc.page(at: 1) {
                                var pageRect:CGRect = pdfPage.getBoxRect(.mediaBox)
                                pageRect.size = CGSize(width:pageRect.size.width, height:pageRect.size.height)
                                UIGraphicsBeginImageContext(pageRect.size)
                                if let context:CGContext = UIGraphicsGetCurrentContext(){
                                    context.saveGState()
                                    context.translateBy(x: 0.0, y: pageRect.size.height)
                                    context.scaleBy(x: 1.0, y: -1.0)
                                    context.concatenate(pdfPage.getDrawingTransform(.mediaBox, rect: pageRect, rotate: 0, preserveAspectRatio: true))
                                    context.drawPDFPage(pdfPage)
                                    context.restoreGState()
                                    if let pdfImage:UIImage = UIGraphicsGetImageFromCurrentImageContext() {
                                        thumb = pdfImage
                                    }
                                }
                                UIGraphicsEndImageContext()
                            }
                        }
                    }
                }
                else if gif{
                    let image = UIImage(data: data)!
                    thumb = image
                    let asset = PHAsset.fetchAssets(withALAssetURLs: [dataURL], options: nil)
                    if let phAsset = asset.firstObject {
                        let option = PHImageRequestOptions()
                        option.isSynchronous = true
                        option.isNetworkAccessAllowed = true
                        PHImageManager.default().requestImageData(for: phAsset, options: option) {
                            (gifData, dataURI, orientation, info) -> Void in
                            data = gifData!
                        }
                    }
                    popupText = "Are you sure to send this image?"
                    usePopup = true
                }else if video {
                    fileType = .video
                    
                    let assetMedia = AVURLAsset(url: dataURL)
                    let thumbGenerator = AVAssetImageGenerator(asset: assetMedia)
                    thumbGenerator.appliesPreferredTrackTransform = true
                    
                    let thumbTime = CMTimeMakeWithSeconds(0, 30)
                    let maxSize = CGSize(width: QiscusHelper.screenWidth(), height: QiscusHelper.screenWidth())
                    thumbGenerator.maximumSize = maxSize
                    
                    do{
                        let thumbRef = try thumbGenerator.copyCGImage(at: thumbTime, actualTime: nil)
                        thumb = UIImage(cgImage: thumbRef)
                        popupText = "Are you sure to send this video?"
                    }catch{
                        Qiscus.printLog(text: "error creating thumb image")
                    }
                    usePopup = true
                }else{
                    usePopup = true
                    let textFirst = QiscusTextConfiguration.sharedInstance.confirmationFileUploadText
                    let textMiddle = "\(fileName as String)"
                    let textLast = QiscusTextConfiguration.sharedInstance.questionMark
                    popupText = "\(textFirst) \(textMiddle) \(textLast)"
                    fileType = QiscusFileType.file
                }
                
                if usePopup {
                    QPopUpView.showAlert(withTarget: self, image: thumb, message:popupText, isVideoImage: video,
                                         doneAction: {
                                            QiscusCore.shared.upload(data: data, filename: fileName, onSuccess: { (file) in
                                                let message = CommentModel()
                                                message.type = "file_attachment"
                                                message.payload = [
                                                    "url"       : file.url.absoluteString,
                                                    "file_name" : file.name,
                                                    "size"      : file.size,
                                                    "caption"   : ""
                                                ]
                                                message.message = "Send Attachment"
                                                self.send(message: message, onSuccess: { (comment) in
                                                    //success
                                                }, onError: { (error) in
                                                    //error
                                                })
                                            }, onError: { (error) in
                                                //
                                            }) { (progress) in
                                                Qiscus.printLog(text: "upload progress: \(progress)")
                                            }
                    },
                                         cancelAction: {
                                            
                    }
                    )
                }else{
//                    let uploader = QiscusUploaderVC(nibName: "QiscusUploaderVC", bundle: Qiscus.bundle)
//                    uploader.chatView = self
//                    uploader.data = data
//                    uploader.fileName = fileName
//                    uploader.room = self.chatRoom
//                    self.navigationController?.pushViewController(uploader, animated: true)
                    
                    QiscusCore.shared.upload(data: data, filename: fileName, onSuccess: { (file) in
                        let message = CommentModel()
                        message.type = "file_attachment"
                        message.payload = [
                            "url"       : file.url.absoluteString,
                            "file_name" : file.name,
                            "size"      : file.size,
                            "caption"   : ""
                        ]
                        message.message = "Send Attachment"
                        self.send(message: message, onSuccess: { (comment) in
                            //success
                        }, onError: { (error) in
                            //error
                        })
                    }, onError: { (error) in
                        //
                    }) { (progress) in
                        Qiscus.printLog(text: "upload progress: \(progress)")
                    }
                }
                
            }catch _{
                //finish loading
                //self.dismissLoading()
            }
        }
    }
    
    
    //Alert
    func goToIPhoneSetting(){
        UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    func showLocationAccessAlert(){
        DispatchQueue.main.async{autoreleasepool{
            let text = QiscusTextConfiguration.sharedInstance.locationAccessAlertText
            let cancelTxt = QiscusTextConfiguration.sharedInstance.alertCancelText
            let settingTxt = QiscusTextConfiguration.sharedInstance.alertSettingText
            QPopUpView.showAlert(withTarget: self, message: text, firstActionTitle: settingTxt, secondActionTitle: cancelTxt,
                                 doneAction: {
                                    self.goToIPhoneSetting()
            },
                                 cancelAction: {}
            )
            }}
    }
    func showPhotoAccessAlert(){
        DispatchQueue.main.async(execute: {
            let text = QiscusTextConfiguration.sharedInstance.galeryAccessAlertText
            let cancelTxt = QiscusTextConfiguration.sharedInstance.alertCancelText
            let settingTxt = QiscusTextConfiguration.sharedInstance.alertSettingText
            QPopUpView.showAlert(withTarget: self, message: text, firstActionTitle: settingTxt, secondActionTitle: cancelTxt,
                                 doneAction: {
                                    self.goToIPhoneSetting()
            },
                                 cancelAction: {}
            )
        })
    }
    func showCameraAccessAlert(){
        DispatchQueue.main.async(execute: {
            let text = QiscusTextConfiguration.sharedInstance.cameraAccessAlertText
            let cancelTxt = QiscusTextConfiguration.sharedInstance.alertCancelText
            let settingTxt = QiscusTextConfiguration.sharedInstance.alertSettingText
            QPopUpView.showAlert(withTarget: self, message: text, firstActionTitle: settingTxt, secondActionTitle: cancelTxt,
                                 doneAction: {
                                    self.goToIPhoneSetting()
            },
                                 cancelAction: {}
            )
        })
    }
    
    func showNoConnectionToast(){
        QToasterSwift.toast(target: self, text: QiscusTextConfiguration.sharedInstance.noConnectionText, backgroundColor: UIColor(red: 0.9, green: 0,blue: 0,alpha: 0.8), textColor: UIColor.white)
    }
}

// Contact Picker
extension QiscusChatVC : CNContactPickerDelegate {
    public func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        let userName:String = contact.givenName
        let surName:String = contact.familyName
        let fullName:String = userName + " " + surName
        //  user phone number
        let userPhoneNumbers:[CNLabeledValue<CNPhoneNumber>] = contact.phoneNumbers
        let firstPhoneNumber:CNPhoneNumber = userPhoneNumbers[0].value
        let primaryPhoneNumberStr:String = firstPhoneNumber.stringValue
        
        // send contact, with qiscus comment type "contact_person" payload must valit
        let message = CommentModel()
        message.type = "contact_person"
        message.payload = [
            "name"  : fullName,
            "value" : primaryPhoneNumberStr,
            "type"  : "phone"
        ]
        message.message = "Send Contact"
        self.send(message: message, onSuccess: { (comment) in
            //success
        }, onError: { (error) in
            //error
        })
    }
}

// MARK: - UIDocumentPickerDelegate
extension QiscusChatVC: UIDocumentPickerDelegate{
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        if #available(iOS 11.0, *) {
            UINavigationBar.appearance().tintColor = self.latestNavbarTint
            self.navigationController?.navigationBar.tintColor = self.latestNavbarTint
        }
        self.postReceivedFile(fileUrl: url)
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        if #available(iOS 11.0, *) {
            UINavigationBar.appearance().tintColor = self.latestNavbarTint
            self.navigationController?.navigationBar.tintColor = self.latestNavbarTint
        }
    }
}

// Image Picker
extension QiscusChatVC : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func showFileTooBigAlert(){
        let alertController = UIAlertController(title: "Fail to upload", message: "File too big", preferredStyle: .alert)
        let galeryActionButton = UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in }
        alertController.addAction(galeryActionButton)
        self.present(alertController, animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let fileType:String = info[UIImagePickerControllerMediaType] as! String
        let time = Double(Date().timeIntervalSince1970)
        let timeToken = UInt64(time * 10000)
        
        if fileType == "public.image"{

            var imageName:String = "\(NSDate().timeIntervalSince1970 * 1000).jpg"
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            var data = UIImagePNGRepresentation(image)
            
            if let imageURL = info[UIImagePickerControllerReferenceURL] as? URL{
                imageName = imageURL.lastPathComponent
                
                let imageNameArr = imageName.split(separator: ".")
                let imageExt:String = String(imageNameArr.last!).lowercased()
                
                let gif:Bool = (imageExt == "gif" || imageExt == "gif_")
                let png:Bool = (imageExt == "png" || imageExt == "png_")
                
                if png{
                    data = UIImagePNGRepresentation(image)!
                }else if gif{
                    let asset = PHAsset.fetchAssets(withALAssetURLs: [imageURL], options: nil)
                    if let phAsset = asset.firstObject {
                        let option = PHImageRequestOptions()
                        option.isSynchronous = true
                        option.isNetworkAccessAllowed = true
                        PHImageManager.default().requestImageData(for: phAsset, options: option) {
                            (gifData, dataURI, orientation, info) -> Void in
                            data = gifData
                        }
                    }
                }else{
                    let result = PHAsset.fetchAssets(withALAssetURLs: [imageURL], options: nil)
                    let asset = result.firstObject
                    imageName = "\((asset?.value(forKey: "filename"))!)"
                    imageName = imageName.replacingOccurrences(of: "HEIC", with: "jpg")
                    let imageSize = image.size
                    var bigPart = CGFloat(0)
                    if(imageSize.width > imageSize.height){
                        bigPart = imageSize.width
                    }else{
                        bigPart = imageSize.height
                    }
                    
                    var compressVal = CGFloat(1)
                    if(bigPart > 2000){
                        compressVal = 2000 / bigPart
                    }
                    
                    data = UIImageJPEGRepresentation(image, compressVal)!
                }
            }else{
                let imageSize = image.size
                var bigPart = CGFloat(0)
                if(imageSize.width > imageSize.height){
                    bigPart = imageSize.width
                }else{
                    bigPart = imageSize.height
                }
                
                var compressVal = CGFloat(1)
                if(bigPart > 2000){
                    compressVal = 2000 / bigPart
                }
                
                data = UIImageJPEGRepresentation(image, compressVal)!
            }
            
            if data != nil {
                let mediaSize = Double(data!.count) / 1024.0
                if mediaSize > Qiscus.maxUploadSizeInKB {
                    picker.dismiss(animated: true, completion: {
                        self.showFileTooBigAlert()
                    })
                    return
                }
                
                dismiss(animated:true, completion: nil)
                
                let uploader = QiscusUploaderVC(nibName: "QiscusUploaderVC", bundle: Qiscus.bundle)
                uploader.chatView = self
                uploader.data = data
                uploader.fileName = imageName
                self.navigationController?.pushViewController(uploader, animated: true)
                picker.dismiss(animated: true, completion: {
                    
                })
                
                
            }
            
        }else if fileType == "public.movie" {
            let mediaURL = info[UIImagePickerControllerMediaURL] as! URL
            let fileName = mediaURL.lastPathComponent
            
            let mediaData = try? Data(contentsOf: mediaURL)
            let mediaSize = Double(mediaData!.count) / 1024.0
            if mediaSize > Qiscus.maxUploadSizeInKB {
                picker.dismiss(animated: true, completion: {
                    self.showFileTooBigAlert()
                })
                return
            }
            //create thumb image
            let assetMedia = AVURLAsset(url: mediaURL)
            let thumbGenerator = AVAssetImageGenerator(asset: assetMedia)
            thumbGenerator.appliesPreferredTrackTransform = true
            
            let thumbTime = CMTimeMakeWithSeconds(0, 30)
            let maxSize = CGSize(width: QiscusHelper.screenWidth(), height: QiscusHelper.screenWidth())
            thumbGenerator.maximumSize = maxSize
            
            picker.dismiss(animated: true, completion: {
                
            })
            do{
                let thumbRef = try thumbGenerator.copyCGImage(at: thumbTime, actualTime: nil)
                let thumbImage = UIImage(cgImage: thumbRef)
                
                QPopUpView.showAlert(withTarget: self, image: thumbImage, message:"Are you sure to send this video?", isVideoImage: true,
                                     doneAction: {
                                        QiscusCore.shared.upload(data: mediaData!, filename: fileName, onSuccess: { (file) in
                                            let message = CommentModel()
                                            message.type = "file_attachment"
                                            message.payload = [
                                                "url"       : file.url.absoluteString,
                                                "file_name" : file.name,
                                                "size"      : file.size,
                                                "caption"   : ""
                                            ]
                                            message.message = "Send Attachment"
                                            self.send(message: message, onSuccess: { (comment) in
                                                //success
                                            }, onError: { (error) in
                                                //error
                                            })
                                        }, onError: { (error) in
                                            //
                                        }) { (progress) in
                                            Qiscus.printLog(text: "upload progress: \(progress)")
                                        }
                },
                                     cancelAction: {
                                        Qiscus.printLog(text: "cancel upload")
                }
                )
            }catch{
                Qiscus.printLog(text: "error creating thumb image")
            }
        }
       
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

extension QiscusChatVC: CLLocationManagerDelegate {
    
    func newLocationComment(latitude:Double, longitude:Double, title:String?=nil, address:String?=nil)->CommentModel{
        let comment = CommentModel()
        var locTitle = title
        var locAddress = ""
        if address != nil {
            locAddress = address!
        }
        if title == nil {
            var newLat = latitude
            var newLong = longitude
            var latString = "N"
            var longString = "E"
            if latitude < 0 {
                latString = "S"
                newLat = 0 - latitude
            }
            if longitude < 0 {
                longString = "W"
                newLong = 0 - longitude
            }
            let intLat = Int(newLat)
            let intLong = Int(newLong)
            let subLat = Int((newLat - Double(intLat)) * 100)
            let subLong = Int((newLong - Double(intLong)) * 100)
            let subSubLat = Int((newLat - Double(intLat) - Double(Double(subLat)/100)) * 10000)
            let subSubLong = Int((newLong - Double(intLong) - Double(Double(subLong)/100)) * 10000)
            let pLat = Int((newLat - Double(intLat) - Double(Double(subLat)/100) - Double(Double(subSubLat)/10000)) * 100000)
            let pLong = Int((newLong - Double(intLong) - Double(Double(subLong)/100) - Double(Double(subSubLong)/10000)) * 100000)
            
            locTitle = "\(intLat)º\(subLat)\'\(subSubLat).\(pLat)\"\(latString) \(intLong)º\(subLong)\'\(subSubLong).\(pLong)\"\(longString)"
        }
        let url = "http://maps.google.com/maps?daddr=\(latitude),\(longitude)"
        
        let payload = "{ \"name\": \"\(locTitle!)\", \"address\": \"\(locAddress)\", \"latitude\": \(latitude), \"longitude\": \(longitude), \"map_url\": \"\(url)\"}"
        
        
        comment.type = "location"
        comment.payload = JSON(parseJSON: payload).dictionaryObject
      
        return comment
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        QiscusBackgroundThread.async {autoreleasepool{
            manager.stopUpdatingLocation()
            if !self.didFindLocation {
                if let currentLocation = manager.location {
                    let geoCoder = CLGeocoder()
                    let latitude = currentLocation.coordinate.latitude
                    let longitude = currentLocation.coordinate.longitude
                    var address:String?
                    var title:String?
                    
                    geoCoder.reverseGeocodeLocation(currentLocation, completionHandler: { (placemarks, error) in
                        if error == nil {
                            let placeArray = placemarks
                            var placeMark: CLPlacemark!
                            placeMark = placeArray?[0]
                            
                            if let addressDictionary = placeMark.addressDictionary{
                                if let addressArray = addressDictionary["FormattedAddressLines"] as? [String] {
                                    address = addressArray.joined(separator: ", ")
                                }
                                title = addressDictionary["Name"] as? String
                                DispatchQueue.main.async { autoreleasepool{
                                    let message = self.newLocationComment(latitude: latitude, longitude: longitude, title: title, address: address)
                                    message.message = "Send Location"
                                    self.send(message: message, onSuccess: { (comment) in
                                        //success
                                    }, onError: { (error) in
                                        //error
                                    })
                                }}
                            }
                        }
                    })
                    
                }
                self.didFindLocation = true
                self.dismissLoading()
            }
            }}
    }
}

