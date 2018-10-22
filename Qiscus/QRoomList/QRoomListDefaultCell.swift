//
//  UIChatListViewCell.swift
//  QiscusUI
//
//  Created by Qiscus on 30/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import UIKit
import QiscusCore
import AlamofireImage
import QiscusUI
import SwiftyJSON
import SDWebImage

class QRoomListDefaultCell: BaseChatListCell {
    @IBOutlet weak var viewBadge: UIView!
    @IBOutlet weak var imageViewPinRoom: UIImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelLastMessage: UILabel!
    @IBOutlet weak var imageViewRoom: UIImageView!
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var labelBadge: UILabel!
    
    var lastMessageCreateAt:String{
        get{
            guard let comment = data?.lastComment else { return "" }
            let createAt = comment.unixTimestamp
            if createAt == 0 {
                return ""
            }else{
                var result = ""
                let date = Date(timeIntervalSince1970: Double(createAt))
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "d/MM"
                let dateString = dateFormatter.string(from: date)
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "h:mm a"
                let timeString = timeFormatter.string(from: date)
                
                if date.isToday{
                    result = "\(timeString)"
                }
                else if date.isYesterday{
                    result = "Yesterday"
                }else{
                    result = "\(dateString)"
                }
                
                return result
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        imageViewRoom.layer.cornerRadius = imageViewRoom.frame.height/2
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override func setupUI() {
        if let data = data {
            self.labelName.text = data.name
            self.labelDate.text = lastMessageCreateAt
            
            if let avatar = data.avatarUrl {
                self.imageViewRoom.af_setImage(withURL: avatar)
            }
            if(data.unreadCount == 0){
                self.hiddenBadge()
            }else{
                self.showBadge()
                self.labelBadge.text = "\(data.unreadCount)"
            }
            
            var message = ""
            guard let lastComment = data.lastComment else { return }
            if lastComment.message.range(of:"[file]") != nil {
                guard let payload = lastComment.payload else { return }
                let json = JSON(payload)
                print("json ini =\(json)")
                let caption = json["caption"].string ?? ""
                if  !caption.isEmpty {
                    message = caption
                }else{
                    message = "Send Attachment"
                }
                
            }else{
                message = lastComment.message
            }
            
            if(data.type != .single){
                self.labelLastMessage.text  =  "\(lastComment.username): \(message)"
            }else{
                self.labelLastMessage.text  = message
            }
        }
    }
    
    public func hiddenBadge(){
        self.viewBadge.isHidden     = true
        self.labelBadge.isHidden    = true
    }
    
    public func showBadge(){
        self.viewBadge.isHidden     = false
        self.labelBadge.isHidden    = false
    }
    
}
