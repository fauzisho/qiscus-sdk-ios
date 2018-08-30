//
//  QComment.swift
//  Alamofire
//
//  Created by asharijuang on 07/08/18.
//

import Foundation
import QiscusCore
import SwiftyJSON

@objc public enum QCommentType:Int {
    case text
    case image
    case video
    case audio
    case file
    case postback
    case account
    case reply
    case system
    case card
    case contact
    case location
    case custom
    case document
    case carousel
    
    static let all = [text.name(), image.name(), video.name(), audio.name(),file.name(),postback.name(),account.name(), reply.name(), system.name(), card.name(), contact.name(), location.name(), custom.name()]
    
    func name() -> String{
        switch self {
        case .text      : return "text"
        case .image     : return "image"
        case .video     : return "video"
        case .audio     : return "audio"
        case .file      : return "file"
        case .postback  : return "postback"
        case .account   : return "account"
        case .reply     : return "reply"
        case .system    : return "system"
        case .card      : return "card"
        case .contact   : return "contact_person"
        case .location  : return "location"
        case .custom    : return "custom"
        case .document  : return "document"
        case .carousel  : return "carousel"
        }
    }
    init(name:String) {
        switch name {
        case "text","button_postback_response"     : self = .text ; break
        case "image"            : self = .image ; break
        case "video"            : self = .video ; break
        case "audio"            : self = .audio ; break
        case "file"             : self = .file ; break
        case "postback"         : self = .postback ; break
        case "account"          : self = .account ; break
        case "reply"            : self = .reply ; break
        case "system"           : self = .system ; break
        case "card"             : self = .card ; break
        case "contact_person"   : self = .contact ; break
        case "location"         : self = .location; break
        case "document"         : self = .document; break
        case "carousel"         : self = .carousel; break
        default                 : self = .custom ; break
        }
    }
}

public class QComment: CommentModel {
//    public var createdAt : Int{
//        get{
//            return unixTimestamp
//        }
//        set{
//            unixTimestamp = newValue
//        }
//    }
//
    
    //need room name from QComment
    public var roomName : String{
        get{
            return roomName
        }
        
        set{
            roomName = newValue
        }
    }
    
    //need payload string from QComment
    public var payloadData : String{
        get{
            return "payload still harcode"
        }
        
        set{
            //payloadData = newValue
        }
    }
    
    //need extras string from QComment
    public var extrasData : String {
        get{
            return "extras still harcode"
        }
        
        set{
           // extrasData = newValue
        }
    }
    
    public var typeMessage: QCommentType{
        get{
            return QCommentType(rawValue: type.hashValue)!
        }
        
    }
    
    public var date: String {
        get {
            let date = Date(timeIntervalSince1970: TimeInterval(self.unixTimestamp))
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMMM yyyy"
            let dateString = dateFormatter.string(from: date)
            
            return dateString
        }
    }
    
    //Todo search comment from local
    internal class func comments(searchQuery: String, onSuccess:@escaping (([QComment])->Void), onFailed: @escaping ((String)->Void)){
        let comments = QiscusCore.dataStore.getComments().filter({ (comment) -> Bool in
            return comment.message.lowercased().contains(searchQuery.lowercased())
        })
        
        if(comments.count == 0){
            onFailed("Comment not found")
        }else{
            onSuccess(comments as! [QComment])
        }
    }
    
    /// will post pending message when internet connection is available
    internal class func resendPendingMessage(){
        let comments = QiscusCore.dataStore.getComments().filter({ (comment) in comment.status.rawValue.lowercased() == "failed".lowercased() ||  comment.status.rawValue.lowercased() == "pending".lowercased() })
        
        for comment in comments {
            QRoom.getRoom(withId: comment.roomId) { (qRoomData, error) in
                if let qRoom = qRoomData {
                    qRoomData?.post(comment: comment as! QComment)
                }
            }
        }
    }
    
    public func encodeDictionary()->[AnyHashable : Any]{
        var data = [AnyHashable : Any]()
        
        data["qiscus_commentdata"] = true
        data["qiscus_uniqueId"] = self.uniqueTempId
        data["qiscus_id"] = self.id
        data["qiscus_roomId"] = self.roomId
        data["qiscus_beforeId"] = self.commentBeforeId
        data["qiscus_text"] = self.message
        data["qiscus_createdAt"] = self.unixTimestamp
        data["qiscus_senderEmail"] = self.userEmail
        data["qiscus_senderName"] = self.username
        data["qiscus_statusRaw"] = self.status
        data["qiscus_typeRaw"] = self.type
        data["qiscus_data"] = self.payloadData
        
        return data
    }
    
    public class QCommentInfo: NSObject {
        public var comment:QComment?
        public var deliveredUser = [QParticipant]()
        public var readUser = [QParticipant]()
        public var undeliveredUser = [QParticipant]()
    }
    
    //TODO Need To be implement
    public var statusInfo:QCommentInfo? {
        get{
//            if let room = QRoom.room(withId: self.roomId) {
//                let commentInfo = QCommentInfo()
//                commentInfo.comment = self
//                commentInfo.deliveredUser = [QParticipant]()
//                commentInfo.readUser = [QParticipant]()
//                commentInfo.undeliveredUser = [QParticipant]()
//                for participant in room.participants {
//                    if participant.email != Qiscus.client.email{
//                        if participant.lastReadCommentId >= self.id {
//                            commentInfo.readUser.append(participant)
//                        }else if participant.lastDeliveredCommentId >= self.id{
//                            commentInfo.deliveredUser.append(participant)
//                        }else{
//                            commentInfo.undeliveredUser.append(participant)
//                        }
//                    }
//                }
//                return commentInfo
//            }
            return nil
        }
    }
    
    
    /// forward to other roomId
    ///
    /// - Parameters:
    ///   - roomId: roomId
    ///   - onSuccess: will return success
    ///   - onError: will return error message
    public func forward(toRoomWithId roomId: String, onSuccess:@escaping ()->Void, onError:@escaping (String)->Void){
        QiscusCore.shared.sendMessage(roomID: roomId, comment: self) { (qCommentData, error) in
            if let qComment = qCommentData {
                onSuccess()
            }else{
                if let errorMessage = error {
                    onError(errorMessage.message)
                }
            }
        }
        
    }
    
    /// Delete message by id
    ///
    /// - Parameters:
    ///   - uniqueID: comment unique id
    ///   - type: forMe or ForEveryone
    ///   - completion: Response Comments your deleted
    public func deleteMessage(uniqueIDs id: [String], type: DeleteType, onSuccess:@escaping ([QComment])->Void, onError:@escaping (String)->Void) {
       
        QiscusCore.shared.deleteMessage(uniqueIDs: id, type: type) { (qComments, error) in
            if let qCommentsData = qComments{
                onSuccess(qCommentsData as! [QComment])
            }else{
                if let errorMessage = error {
                    onError(errorMessage.message)
                }
            }
        }
    }
    
}
