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

protocol CustomChatInputDelegate {
    func sendAttachment()
}

class CustomChatInput: UIChatInput {
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var attachButton: UIButton!
    @IBOutlet weak var textField: UITextField!
    var delegate : CustomChatInputDelegate? = nil
    
    override func commonInit(nib: UINib) {
        let nib = UINib(nibName: "CustomChatInput", bundle: Qiscus.bundle)
        super.commonInit(nib: nib)
        textField.delegate = self
    }
    
    @IBAction func clickSend(_ sender: Any) {
        guard let text = self.textField.text else {return}
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let comment = CommentModel()
            comment.type = "text"
            comment.message = text
            self.send(message: comment)
        }
        self.textField.text = ""
    }
    
    @IBAction func clickAttachment(_ sender: Any) {
        self.delegate?.sendAttachment()
    }
}

extension CustomChatInput : UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.typing(true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.typing(false)
    }
}
