//
//  CustomChatInput.swift
//  Example
//
//  Created by Qiscus on 04/09/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import UIKit
import QiscusUI
import QiscusCore
import SwiftyJSON

protocol CustomChatInputDelegate {
    func sendAttachment()
    func sendMessage(message: CommentModel)
}

class CustomChatInput: UIChatInput {
    
    @IBOutlet weak var heightView: NSLayoutConstraint!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var attachButton: UIButton!
    
    @IBOutlet weak var heightTextViewCons: NSLayoutConstraint!
    @IBOutlet weak var textView: UITextView!
    var delegate : CustomChatInputDelegate? = nil
    var replyData:CommentModel?
    
    override func commonInit(nib: UINib) {
        let nib = UINib(nibName: "CustomChatInput", bundle: Qiscus.bundle)
        super.commonInit(nib: nib)
        textView.delegate = self
        textView.text = QiscusTextConfiguration.sharedInstance.textPlaceholder
        textView.textColor = UIColor.lightGray
        textView.font = Qiscus.sharedInstance.styleConfiguration.chatFont
        
    }
    
    @IBAction func clickSend(_ sender: Any) {
        guard let text = self.textView.text else {return}
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && text != QiscusTextConfiguration.sharedInstance.textPlaceholder {
            var payload:JSON? = nil
            let comment = CommentModel()
            if(replyData != nil){
                var senderName = replyData?.username
                comment.type = "reply"
                comment.message = text
                comment.payload = [
                    "replied_comment_sender_email"       : replyData?.userEmail,
                    "replied_comment_id" : Int((replyData?.id)!),
                    "text"      : text,
                    "replied_comment_message"   : replyData?.message,
                    "replied_comment_sender_username" : senderName,
                    "replied_comment_payload" : replyData?.payload,
                    "replied_comment_type" : replyData?.type
                ]
                self.replyData = nil
            }else{
               
                comment.type = "text"
                comment.message = text
                
            }
            self.delegate?.sendMessage(message: comment)
        }
        
        self.textView.text = ""
        textView.textColor = UIColor.lightGray
    }
    
    @IBAction func clickAttachment(_ sender: Any) {
        self.delegate?.sendAttachment()
    }
}

extension CustomChatInput : UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if(textView.text == QiscusTextConfiguration.sharedInstance.textPlaceholder){
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if(textView.text.isEmpty){
            textView.text = QiscusTextConfiguration.sharedInstance.textPlaceholder
            textView.textColor = UIColor.lightGray
        }
        self.typing(false)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.typing(true)
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSize.init(width: fixedWidth, height: CGFloat(MAXFLOAT)))
        if (newSize.height >= 40 && newSize.height <= 100) {
            self.heightTextViewCons.constant = newSize.height
            self.heightView.constant = newSize.height + 10.0
            
        }
        if (newSize.height >= 100) { self.textView.isScrollEnabled = true }
    }
    
}
