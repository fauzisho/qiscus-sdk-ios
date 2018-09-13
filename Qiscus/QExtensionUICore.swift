//
//  QBallon.swift
//  Qiscus
//
//  Created by asharijuang on 04/09/18.
//

import Foundation
import QiscusUI
import QiscusCore
import Qiscus
import SwiftyJSON

protocol ChatCellDelegate {
    func didTapCell(withData data: CommentModel)
    func didTouchLink(onCell cell: UIBaseChatCell)
    func didTapPostbackButton(withData data: JSON)
    func didTapAccountLinking(withData data: JSON)
    func didTapSaveContact(withData data:CommentModel)
    func didShare(comment: CommentModel)
    func didForward(comment: CommentModel)
    func didReply(comment:CommentModel)
    func getInfo(comment:CommentModel)
    func didTapFile(comment: CommentModel)
}

extension UIBaseChatCell {
    open func getBallon()->UIImage?{
        var balloonImage:UIImage? = nil
        var edgeInset = UIEdgeInsetsMake(13, 13, 13, 28)
        
        if (self.comment?.isMyComment() == true){
            balloonImage = Qiscus.style.assets.rightBallonLast
        }else{
            edgeInset = UIEdgeInsetsMake(13, 28, 13, 13)
            balloonImage = Qiscus.style.assets.leftBallonLast
        }
        
        return balloonImage?.resizableImage(withCapInsets: edgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
    }
}

extension CommentModel {
    
    open func isMyComment() -> Bool {
        // change this later when user savevd on presisstance storage
        if let user = QiscusCore.getProfile() {
            return userEmail == user.email
        }else {
            return false
        }
    }
    
    open func date() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat    = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.timeZone      = TimeZone(abbreviation: "UTC")
        let date = formatter.date(from: self.timestamp)
        return date
    }
    
    open func hour() -> String {
        guard let date = self.date() else {
            return "-"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone      = TimeZone.current
        let defaultTimeZoneStr = formatter.string(from: date);
        return defaultTimeZoneStr
    }
}
