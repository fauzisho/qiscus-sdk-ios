//
//  QiscusNotification.swift
//  Example
//
//  Created by Ahmad Athaullah on 9/12/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import QiscusCore

public class QiscusNotification: NSObject {
    
    static let shared = QiscusNotification()
    let nc = NotificationCenter.default
    var roomOrderTimer:Timer?
    
    private static var typingTimer = [String:Timer]()
    
    public static let MESSAGE_STATUS = NSNotification.Name("qiscus_messageStatus")
    public static let USER_PRESENCE = NSNotification.Name("quscys_userPresence")
    public static let USER_AVATAR_CHANGE = NSNotification.Name("qiscus_userAvatarChange")
    public static let USER_NAME_CHANGE = NSNotification.Name("qiscus_userNameChange")
    public static let GOT_NEW_ROOM = NSNotification.Name("qiscus_gotNewRoom")
    public static let GOT_NEW_COMMENT = NSNotification.Name("qiscus_gotNewComment")
    public static let ROOM_DELETED = NSNotification.Name("qiscus_roomDeleted")
    public static let ROOM_ORDER_MAY_CHANGE = NSNotification.Name("qiscus_romOrderChange")
    public static let FINISHED_CLEAR_MESSAGES = NSNotification.Name("qiscus_finishedClearMessages")
    public static let FINISHED_SYNC_ROOMLIST = NSNotification.Name("qiscus_finishedSyncRoomList")
    public static let START_CLOUD_SYNC = NSNotification.Name("qiscus_startCloudSync")
    public static let FINISHED_CLOUD_SYNC = NSNotification.Name("qiscus_finishedCloudSync")
    public static let ERROR_CLOUD_SYNC = NSNotification.Name("qiscus_finishedCloudSync")
    public static let DID_TAP_SAVE_CONTACT = NSNotification.Name("qiscus_didTapSaveContact")
    
    override private init(){
        super.init()
    }
    // MARK: Notification Name With Specific Data
    public class func USER_TYPING(onRoom roomId: String) -> NSNotification.Name {
        return NSNotification.Name("qiscus_userTyping_\(roomId)")
    }
    public class func ROOM_CHANGE(onRoom roomId: String) -> NSNotification.Name {
        return NSNotification.Name("qiscus_roomChange_\(roomId)")
    }
    public class func ROOM_CLEARMESSAGES(onRoom roomId: String) -> NSNotification.Name {
        return NSNotification.Name("qiscus_clearMessages_\(roomId)")
    }
    public class func COMMENT_DELETE(onRoom roomId: String) -> NSNotification.Name {
        return NSNotification.Name("qiscus_commentDelete_\(roomId)")
    }
//    public class func DID_TAP_SAVE_CONTACT(message : CommentModel) -> NSNotification.Name {
//        return NSNotification.Name("qiscus_didTapSaveContact\(message)")
//    }
    
    
    public class func publishDidTapSaveContact(message : CommentModel){
        let notification = QiscusNotification.shared
        notification.publishDidTapSaveContact(message: message)
    }
    
    private func publishDidTapSaveContact(message:CommentModel){
        let userInfo = ["comment" : message]
        self.nc.post(name: QiscusNotification.DID_TAP_SAVE_CONTACT, object: nil, userInfo: userInfo)
    }

    
}

