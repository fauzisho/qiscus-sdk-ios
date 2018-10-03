//
//  QUIBaseChatCell.swift
//  Pods
//
//  Created by asharijuang on 24/09/18.
//

import Foundation
import QiscusCore
import QiscusUI

extension UIBaseChatCell {
    
    open func setMenu() {
        
        let reply = UIMenuItem(title: "Reply", action: #selector(reply(_:)))
        let forward = UIMenuItem(title: "Forward", action: #selector(forward(_:)))
        let share = UIMenuItem(title: "Share", action: #selector(share(_:)))
        let info = UIMenuItem(title: "Info", action: #selector(info(_:)))
        let delete = UIMenuItem(title: "Delete", action: #selector(deleteComment(_:)))
        let deleteForMe = UIMenuItem(title: "Delete For Me", action: #selector(deleteCommentForMe(_:)))
        
        if let myComment = self.comment?.isMyComment() {
            if(myComment){
                UIMenuController.shared.menuItems = [reply,info,share,forward,delete,deleteForMe]
            }else{
                UIMenuController.shared.menuItems = [reply,share,forward,deleteForMe]
            }
            
            UIMenuController.shared.update()
        }
        
        
        
    }
    
    @objc open func reply(_ send:AnyObject){
        QiscusNotification.publishDidClickReply(message: self.comment!)
    }
    
    @objc open func forward(_ send:AnyObject){
        //QiscusNotification.publishDidClickReply(message: self.comment!)
    }
    
    @objc open func share(_ send:AnyObject){
        QiscusNotification.publishDidClickShare(message: self.comment!)
    }
    
    @objc open func deleteComment(_ send:AnyObject){
        var uniqueIDs = [String]()
        let uniqueID = self.comment!.uniqId
        uniqueIDs.append(uniqueID)
        QiscusCore.shared.deleteMessage(uniqueIDs: uniqueIDs, type: .forEveryone, onSuccess: { (commentsModel) in
            Qiscus.printLog(text: "success delete comment for everyone")
        }) { (error) in
            Qiscus.printLog(text: "failed delete comment for everyone")
        }
    
    }
    
    @objc open func deleteCommentForMe(_ send:AnyObject){
        var uniqueIDs = [String]()
        let uniqueID = self.comment!.uniqId
        uniqueIDs.append(uniqueID)
        
        QiscusCore.shared.deleteMessage(uniqueIDs: uniqueIDs, type: DeleteType.forMe, onSuccess: { (commentsModel) in
             Qiscus.printLog(text: "success delete comment for me")
        }) { (error) in
             Qiscus.printLog(text: "failed delete comment for me \(error.message)")
        }
    }
    
    @objc open func info(_ send:AnyObject){
        //QiscusNotification.publishDidClickReply(message: self.comment!)
    }
}


