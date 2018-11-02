//
//  RoomModel.swift
//  Qiscus
//
//  Created by Qiscus on 07/08/18.
//

import Foundation
import QiscusCore
import UIKit
import SwiftyJSON

@objc public enum QiscusFileType:Int{
    case image
    case video
    case audio
    case file
    case document
    case pdf
}

extension RoomModel {
    public var lastCommentMessage: CommentModel{
        get{
            return lastComment as! CommentModel
        }
    }
    
    public var roomName : String{
        get{
            return name
        }
    }
    
    public var avatarURL : String {
        get{
            return (avatarUrl?.absoluteString)!
        }
    }
    
    /// getAllRooms from local db
    ///
    /// - Returns: will return RoomModel
    public class func all() -> [RoomModel]?{
        let rooms = QiscusCore.database.room.all() as! [RoomModel]
        return rooms
        
    }
    
    public class func getRoom(withId: String,onSuccess: @escaping (RoomModel, [CommentModel]) -> Void, onError: @escaping (String) -> Void) {
        
        QiscusCore.shared.getRoom(withID: withId, onSuccess: { (roomModel, commentModel) in
            onSuccess(roomModel,commentModel)
        }) { (error) in
            onError(error.message)
        }
    }
    
    /// get allroom
    ///
    /// - Parameters:
    ///   - withLimit: limit is optional, default limit is 100
    ///   - page: page is optional, default page is 1
    ///   - onSuccess: will return RoomModels and totalRooms
    ///   - onFailed: will return error message
    public class func roomList(withLimit limit:Int = 100, page:Int? = 1, showParticipant:Bool = true, onSuccess:@escaping (([RoomModel],Int)->Void), onFailed: @escaping ((String)->Void)){
        
        QiscusCore.shared.getAllRoom(limit: limit, page: page, onSuccess: { (RoomModelData, metaData) in
            if(metaData != nil){
                onSuccess(RoomModelData as! [RoomModel],(metaData?.totalRoom)!)
            }else{
                onSuccess(RoomModelData as! [RoomModel], RoomModelData.count)
            }
        }) { (error) in
            onFailed(error.message)
        }
    }
    
    /// getAllRoom
    ///
    /// - Parameters:
    ///   - limit: default limit 100
    ///   - page: default page 1
    ///   - onSuccess: will return RoomModel object, total room, currentPage
    ///   - onFailed: will return error message
    public class func getAllRoom(withLimit limit:Int? = 100, page:Int? = 1, onSuccess:@escaping (([RoomModel],Int,Int)->Void), onFailed: @escaping ((String)->Void)){
        
        QiscusCore.shared.getAllRoom(onSuccess: { (roomsModel, meta) in
            onSuccess(roomsModel,(meta?.totalRoom)!, (meta?.currentPage)!)
        }) { (error) in
            onFailed(error.message)
        }
        
    }
    
    
    /// getUnreadCount from service
    ///
    /// - Parameter completion: will return unreadCount
    public class func getUnreadCount(completion: @escaping (Int) -> Void){
        QiscusCore.shared.unreadCount { (unread, error) in
            if error == nil {
                completion(unread)
            }else{
                if let errorMessage = error{
                    completion(0)
                }
            }
        }
    }
    
    /// getUnreadCount from local db
    ///
    /// - Parameter completion: will return unreadCount
    public class func getLocalUnreadCount(completion: @escaping (Int) -> Void){
        let RoomModels = QiscusCore.database.room.all()
        var countUnread = 0
        for room in RoomModels.enumerated() {
            countUnread = countUnread + room.element.unreadCount
        }
        
        completion(countUnread)
    }
    
    
    /// update room
    ///
    /// - Parameters:
    ///   - withID: id of room
    ///   - roomName: room of name
    ///   - roomAvatarURL: avatar of room
    ///   - roomOptions: roomOption
    ///   - onSuccess: will return RoomModel model
    ///   - onError: will return error message
    public func update(withID: String, roomName:String? = nil, roomAvatarURL:String? = nil, roomOptions:String? = nil, onSuccess:@escaping ((_ room: RoomModel)->Void),onError:@escaping ((_ error: String)->Void)){
        
        var roomAvatarUrl: URL? = nil
        if(roomAvatarURL != nil){
            roomAvatarUrl = URL(string: roomAvatarURL!)
        }
        
        QiscusCore.shared.updateRoom(withID: withID, name: roomName, avatarURL: roomAvatarUrl, options: roomOptions, onSuccess: { (roomModel) in
             onSuccess(roomModel as! RoomModel)
        }) { (error) in
            onError(error.message)
        }
        
    }
    
    
    /// create NewComment
    ///
    /// - Parameters:
    ///   - text: message comment
    ///   - payload: payload
    ///   - type: CommentModelType, default is text
    /// - Returns: will return CommentModel model
    public func newComment(roomId: String, text:String, payload:JSON? = nil,type:CommentModelType = .text)->CommentModel{
        // create object comment
        let message = CommentModel.init()
        message.message = text
        message.type = type.name()
        if payload != nil {
            message.payload = payload?.dictionary
        }
        return message
    }
    
    
    /// newCutomComment
    ///
    /// - Parameters:
    ///   - type: type
    ///   - payload: payload
    ///   - text: text
    /// - Returns: will return CommentModel model
    public func newCustomComment(type:String, payload:String, text:String? = nil )->CommentModel{
        let comment = CommentModel.init()
        let payloadData = JSON(parseJSON: payload)
        var contentString = "\"\""
        if payloadData == JSON.null{
            contentString = "\"\(payload)\""
        }else{
            contentString = "\(payloadData)"
        }
        let payload = "{ \"type\": \"\(type)\", \"content\": \(contentString)}"
        let payloadJson = JSON(parseJSON: payload)
        comment.payload = payloadJson.dictionary
        comment.type    = type
        if text == nil {
            comment.message = "message type \(type)"
        }else{
            comment.message = text!
        }
        
        return comment
    }
    
    
    /// postComment
    ///
    /// - Parameters:
    ///   - comment: commment model
    ///   - type: type is optional
    ///   - payload: payload is optional
    public func post(comment:CommentModel, type:String? = nil, payload:JSON? = nil){
        comment.payload = payload?.dictionary
        if type != nil && !(type?.isEmpty)! {
            comment.type  = type!
        }
        QiscusCore.shared.sendMessage(roomID: self.id, comment: comment, onSuccess: { (commentModel) in
            comment.onChange(comment)
        }) { (error) in
            comment.onChange(comment)
        }
    }
    
    /// Load Comment by room
    ///
    /// - Parameters:
    ///   - id: Room ID
    ///   - limit: by default set 20, min 0 and max 100
    ///   - completion: Response new Qiscus Array of Comment Object and error if exist.
    public func loadComments(roomID id: String, limit: Int? = 20, onSuccess: @escaping ([CommentModel]) -> Void, onError: @escaping (String) -> Void) {
        // Load message by default 20
        QiscusCore.shared.loadComments(roomID: id, limit: limit, onSuccess: { (commentsModel) in
            onSuccess(commentsModel)
        }) { (error) in
             onError(error.message)
        }
    }
    
    
    /// loadMore Comment
    ///
    /// - Parameters:
    ///   - roomID: roomId
    ///   - lastCommentID: lastCommentId
    ///   - limit: default limit is 20
    ///   - onSuccess: will return array of CommentModel
    ///   - onError: will return error message
    public func loadMore(roomID: String, lastCommentID: Int, limit: Int? = 20, onSuccess:@escaping ([CommentModel],Bool)->Void, onError:@escaping (String)->Void){
        
        QiscusCore.shared.loadMore(roomID: roomID, lastCommentID: lastCommentID, limit: limit, onSuccess: { (commentsModel) in
            var hasMoreMessages : Bool = true
            if commentsModel.count == 0 {
                hasMoreMessages = false
            }
            onSuccess(commentsModel as! [CommentModel], hasMoreMessages)
        }) { (error) in
            onError(error.message)
        }
    }
        
    /// Delete all message in room
    ///
    /// - Parameters:
    ///   - roomID: array of room id
    ///   - completion: Response error if exist
    public func deleteAllMessage(roomID: [String], onSuccess:@escaping ()->Void, onError:@escaping (String?)->Void) {
       
        QiscusCore.shared.deleteAllMessage(roomID: roomID) { (error) in
            if let errorData = error?.message{
                onError(errorData)
            }else{
                onSuccess()
            }
        }
    }
    
    /// publishStartTyping
    ///
    /// - Parameter roomID: roomId
    public func publishStartTyping(roomID: String){
        QiscusCore.shared.isTyping(true, roomID: roomID)
    }
    
    /// publishStopTyping
    ///
    /// - Parameter roomID: roomId
    public func publishStopTyping(roomID: String){
        QiscusCore.shared.isTyping(false, roomID: roomID)
    }
    
    /// publish Status Of Comment // Mark Comment as read
    ///
    /// - Parameters:
    ///   - roomId: roomId
    ///   - commentId: commentID
    public class func publishStatus(roomId:String, commentId:String){
        QiscusCore.shared.updateCommentRead(roomId: roomId, lastCommentReadId: commentId)
    }
    
}


