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
        
        UIMenuController.shared.menuItems = [reply]
        UIMenuController.shared.update()
        
    }
    
    @objc open func reply(_ send:AnyObject){
        QiscusNotification.publishDidClickReply(message: self.comment!)
    }
}


