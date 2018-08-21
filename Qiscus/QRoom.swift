//
//  QRoom.swift
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
}

@objc public enum QRoomType:Int{
    case single
    case group
}

public class QRoom: RoomModel {
    public var lastCommentMessage: QComment{
        get{
            return lastComment as! QComment
        }
    }
    
    public var roomName : String{
        get{
            return name
        }
    }
    
    public var roomType : QRoomType{
        get{
            if chatType != "single" {
                return QRoomType.group
            }else{
                return QRoomType.single
            }
            
        }
    }
    
    public var avatarURL : String {
        get{
            return avatarUrl
        }
    }
    
    //Todo Need to be implement from qiscus core
    public func loadAvatar(onSuccess:  @escaping (UIImage)->Void, onError:  @escaping (String)->Void){
        
    }
    
    /// Need get data from localdatabase
    ///
    /// - Returns: [QRoom]
    public class func all() -> [QRoom]?{
        
        return nil
    }
    
    public class func getRoom(withId: String, completion: @escaping (QRoom?, String?) -> Void) {
        QiscusCore.shared.getRoom(withID: withId) { (qRoom,error) in
            if let qRoomData = qRoom {
                 completion(qRoom as! QRoom,nil)
            }else{
                completion(nil,error?.message)
            }
        }
    }
    
    //will return rooms, totalRoom, currentPage, limit
    public class func roomList(withLimit limit:Int = 100, page:Int? = nil, showParticipant:Bool = true, onSuccess:@escaping (([QRoom],Int)->Void), onFailed: @escaping ((String)->Void)){
        
        QiscusCore.shared.getAllRoom(limit: limit, page: page) { (qRoom, metaData, error) in
            if let qRoomData = qRoom {
                if(metaData != nil){
                    onSuccess(qRoomData as! [QRoom],(metaData?.totalRoom)!)
                }else{
                    onSuccess(qRoomData as! [QRoom], qRoomData.count)
                }
            }else{
                onFailed((error?.message)!)
            }
        }
    }
    
    public class func getAllRoom(withLimit limit:Int = 100, page:Int? = nil, onSuccess:@escaping (([QRoom],Int)->Void), onFailed: @escaping ((String)->Void)){
        QiscusCore.shared.getAllRoom(limit: limit, page: page) { (qRoom, metaData, error) in
            if let qRoomData = qRoom {
                if(metaData != nil){
                    onSuccess(qRoomData as! [QRoom],(metaData?.totalRoom)!)
                }else{
                     onSuccess(qRoomData as! [QRoom], qRoomData.count)
                }
            }else{
                onFailed((error?.message)!)
            }
        }
    }
    
    public class func getUnreadCount(completion: @escaping (Int) -> Void){
        QiscusCore.shared.getAllRoom() { (qRoom,meta,error) in
            var countUnread = 0
            if let qRoomData = qRoom {
                for room in qRoomData.enumerated() {
                    countUnread = countUnread + room.element.unreadCount
                }
            }
            
            completion(countUnread)
        }
    }
    
    public func update(withID: String, roomName:String? = nil, roomAvatarURL:String? = nil, roomOptions:String? = nil, onSuccess:@escaping ((_ room: QRoom)->Void),onError:@escaping ((_ error: String)->Void)){
        QiscusCore.shared.updateRoom(withID: withID, name: roomName, avatarURL: URL(string: roomAvatarURL!), options: roomOptions) { (qRoom, error) in
            if let qRoomData = qRoom {
                onSuccess(qRoom as! QRoom)
            }else{
                onError((error?.message)!)
            }
           
        }
    }
    
    public func newComment(text:String, payload:JSON? = nil,type:QCommentType = .text, data:Data? = nil, image:UIImage? = nil, filename:String = "", filePath:URL? = nil )->QComment{
        // create object comment
        let message = QComment()
        message.message = text
        message.type = .text
        message.status = "sending"
        if let user = QiscusCore.getProfile() {
            message.email = user.email
        }
        
        return message
    }
    
    public func newCustomComment(type:String, payload:String, text:String? = nil )->QComment{
        let comment = QComment()
        let payloadData = JSON(parseJSON: payload)
        var contentString = "\"\""
        if payloadData == JSON.null{
            contentString = "\"\(payload)\""
        }else{
            contentString = "\(payloadData)"
        }
        let payload = "{ \"type\": \"\(type)\", \"content\": \(contentString)}"
        if text == nil {
            comment.text = "message type \(type)"
        }else{
            comment.text = text!
        }
//
//        comment.uniqueId = uniqueID
//        comment.id = 0
//        comment.roomId = self.id
//
//        comment.createdAt = Double(Date().timeIntervalSince1970)
//        comment.senderEmail = QiscusMe.sharedInstance.email
//        comment.senderName = QiscusMe.sharedInstance.userName
//        comment.statusRaw = QCommentStatus.sending.rawValue
//        comment.typeRaw = type
//        comment.data = payload
//
        return comment
    }
    
    //TODO NEED TO BE IMPLEMENT with param type and payload
    public func post(comment:QComment, type:String? = nil, payload:JSON? = nil){
        QiscusCore.shared.sendMessage(roomID: self.id, comment: comment) { (message, error) in
            if comment != nil {
                comment.status = "deliverd"
            }else {
                comment.status = "failed"
            }
            comment.onChange(comment)
        }
    }
    
    //TODO NEED TO BE IMPLEMENT newFileComment
    public func newFileComment(type: QiscusFileType, filename:String = "", caption:String = "", data:Data? = nil, thumbImage:UIImage? = nil)->QComment{
        let comment = QComment()
        let fileNameArr = filename.split(separator: ".")
        let fileExt = String(fileNameArr.last!).lowercased()
        
        var fileName = filename.lowercased()
        if fileName == "asset.jpg" || fileName == "asset.png" {
            fileName = "\(comment.uniqueTempId).\(fileExt)"
        }
        
        let payload = "{\"url\":\"\(fileName)\", \"caption\": \"\(caption)\"}"
        
        //comment.roomId = self.id
        
        //        comment.text = "[file]\(fileName) [/file]"
        //        comment.createdAt = Double(Date().timeIntervalSince1970)
        //        comment.senderEmail = QiscusMe.sharedInstance.email
        //        comment.senderName = QiscusMe.sharedInstance.userName
        //        comment.statusRaw = QCommentStatus.sending.rawValue
        //        comment.isUploading = true
        //        comment.progress = 0
        //        comment.data = payload
        //
        //        let file = QFile()
        //        file.id = uniqueID
        //        file.roomId = self.id
        //        file.url = fileName
        //        file.senderEmail = QiscusMe.sharedInstance.email
        //
        //
        //        if let mime = QiscusFileHelper.mimeTypes["\(fileExt)"] {
        //            file.mimeType = mime
        //        }
        //
        switch type {
        case .audio:
            //            comment.typeRaw = QCommentType.audio.name()
            //            file.localPath = QFile.saveFile(data!, fileName: fileName)
            break
        case .image:
            let image = UIImage(data: data!)
            let gif = (fileExt == "gif" || fileExt == "gif_")
            let jpeg = (fileExt == "jpg" || fileExt == "jpg_")
            let png = (fileExt == "png" || fileExt == "png_")
            
            var thumb = UIImage()
            var thumbData:Data?
            //            if !gif {
            //                thumb = QFile.createThumbImage(image!)
            //                if jpeg {
            //                    thumbData = UIImageJPEGRepresentation(thumb, 1)
            //                    file.localThumbPath = QFile.saveFile(thumbData!, fileName: "thumb-\(fileName)")
            //                }else if png {
            //                    thumbData = UIImagePNGRepresentation(thumb)
            //                    file.localThumbPath = QFile.saveFile(thumbData!, fileName: "thumb-\(fileName)")
            //                }
            //            }else{
            //                file.localThumbPath = QFile.saveFile(data!, fileName: "thumb-\(fileName)")
            //            }
            //
            //            comment.typeRaw = QCommentType.image.name()
            //            file.localPath = QFile.saveFile(data!, fileName: fileName)
            break
        case .video:
            //            var fileNameOnly = String(fileNameArr.first!).lowercased()
            //            var i = 0
            //            for namePart in fileNameArr{
            //                if i > 0 && i < (fileNameArr.count - 1){
            //                    fileNameOnly += ".\(String(namePart).lowercased())"
            //                }
            //                i += 1
            //            }
            //            let thumbData = UIImagePNGRepresentation(thumbImage!)
            //            file.localThumbPath = QFile.saveFile(thumbData!, fileName: "thumb-\(fileNameOnly).png")
            //            comment.typeRaw = QCommentType.video.name()
            //            file.localPath = QFile.saveFile(data!, fileName: fileName)
            break
        default:
            //            file.localPath = QFile.saveFile(data!, fileName: fileName)
            //            comment.typeRaw = QCommentType.file.name()
            break
        }
        
        
        return comment
    }
    
    /// Load Comment by room
    ///
    /// - Parameters:
    ///   - id: Room ID
    ///   - limit: by default set 20, min 0 and max 100
    ///   - completion: Response new Qiscus Array of Comment Object and error if exist.
    public func loadComments(roomID id: String, limit: Int? = 20, completion: @escaping ([QComment]?, String?) -> Void) {
        // Load message by default 20
        QiscusCore.shared.loadComments(roomID: id, limit: limit) { (qComments, error) in
            if let qCommentsData = qComments{
                completion(qCommentsData as! [QComment], nil)
            }else{
                completion(nil, error?.message)
            }
        }
    }
    
    public func loadMore(roomID: String, lastCommentID: Int, limit: Int, onSuccess:@escaping ([QComment],Bool)->Void, onError:@escaping (String)->Void){
        QiscusCore.shared.loadMore(roomID: roomID, lastCommentID: lastCommentID, limit: limit) { (qComments, error) in
            if let qCommentsData = qComments{
                var hasMoreMessages : Bool = true
                if qCommentsData.count == 0 {
                    hasMoreMessages = false
                }
                onSuccess(qCommentsData as! [QComment], hasMoreMessages)
            }else{
                onError((error?.message)!)
            }
        }
    }
    
    //TODO NEED TO BE IMPLEMENT FROM SDKCore
    public func downloadMedia(onComment comment:QComment, thumbImageRef: UIImage? = nil, isAudioFile: Bool = false, onSuccess: ((QComment)->Void)? = nil, onError:((String)->Void)? = nil, onProgress:((Double)->Void)? = nil){
       
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
}


