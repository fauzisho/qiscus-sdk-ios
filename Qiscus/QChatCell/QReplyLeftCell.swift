//
//  QReplyLeftCell.swift
//  Qiscus
//
//  Created by asharijuang on 05/09/18.
//

import UIKit
import QiscusUI
import QiscusCore

class QReplyLeftCell: UIBaseChatCell {
    
    @IBOutlet weak var lblNameHeightCons: NSLayoutConstraint!
    @IBOutlet weak var ivCommentImageWidhtCons: NSLayoutConstraint!
    @IBOutlet weak var lbCommentSender: UILabel!
    @IBOutlet weak var tvCommentContent: UITextView!
    @IBOutlet weak var ivCommentImage: UIImageView!
    @IBOutlet weak var lbTime: UILabel!
    @IBOutlet weak var lbContent: UILabel!
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var ivBaloon: UIImageView!
    var menuConfig = enableMenuConfig()
    var isPublic: Bool = false
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.setMenu(forward: menuConfig.forward, info: menuConfig.info)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.setMenu(forward: menuConfig.forward, info: menuConfig.info)
        // Configure the view for the selected state
    }
    
    override func present(message: CommentModel) {
        // parsing payload
        self.bindData(message: message)
        
    }
    
    override func update(message: CommentModel) {
        self.bindData(message: message)
    }
    
    func bindData(message: CommentModel){
        self.setupBalon()
        guard let replyData = message.payload else {
           return
        }
        var text = replyData["replied_comment_message"] as? String
        var replyType = message.replyType(message: text!)
        
        if replyType == .text  {
            switch replyData["replied_comment_type"] as? String {
            case "location":
                replyType = .location
                break
            case "contact_person":
                replyType = .contact
                break
            default:
                break
            }
        }
        var username = replyData["replied_comment_sender_username"] as? String
        let repliedEmail = replyData["replied_comment_sender_email"] as? String
        if repliedEmail == Qiscus.client.email {
            username = "You"
        }
        
        switch replyType {
        case .text:
            self.ivCommentImageWidhtCons.constant = 0
            self.tvCommentContent.text = text
        case .image:
            var filename = message.fileName(text: text!)
            self.tvCommentContent.text = filename
            let url = URL(string: message.getAttachmentURL(message: text!))
            self.ivCommentImage.sd_setShowActivityIndicatorView(true)
            self.ivCommentImage.sd_setIndicatorStyle(.gray)
            self.ivCommentImage.sd_setImage(with: url)
            
        case .video:
            self.tvCommentContent.text = text
        case .audio:
            self.tvCommentContent.text = text
        case .document:
            //pdf
            let url = URL(string: message.getAttachmentURL(message: text!))
            self.ivCommentImage.sd_setShowActivityIndicatorView(true)
            self.ivCommentImage.sd_setIndicatorStyle(.gray)
            self.ivCommentImage.sd_setImage(with: url)
            var filename = message.fileName(text: text!)
            self.tvCommentContent.text = filename
            self.tvCommentContent.text = text
        case .location:
            self.tvCommentContent.text = text
            self.ivCommentImage.image = Qiscus.image(named: "map_ico")
        case .contact:
            self.tvCommentContent.text = text
            self.ivCommentImage.image = Qiscus.image(named: "contact")
        case .file:
            var filename = message.fileName(text: text!)
            self.tvCommentContent.text = filename
            self.ivCommentImage.image = Qiscus.image(named: "ic_file")
        case .other:
            self.tvCommentContent.text = text
            self.ivCommentImageWidhtCons.constant = 0
        }
        
        self.lbCommentSender.text = username
        self.lbContent.text = message.message
        self.lbTime.text = self.hour(date: message.date())
        if(isPublic == true){
            self.lbName.text = message.username
            self.lbName.textColor = Qiscus.style.color.randomColorLabelName.randomItem()
            self.lblNameHeightCons.constant = 21
        }else{
            self.lbName.text = ""
            self.lblNameHeightCons.constant = 0
        }
    }
    
    func setupBalon(){
        self.ivBaloon.image = self.getBallon()
        self.ivBaloon.tintColor = QiscusColorConfiguration.sharedInstance.leftBaloonColor
    }
    
    func hour(date: Date?) -> String {
        guard let date = date else {
            return "-"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone      = TimeZone.current
        let defaultTimeZoneStr = formatter.string(from: date);
        return defaultTimeZoneStr
    }
    
}
