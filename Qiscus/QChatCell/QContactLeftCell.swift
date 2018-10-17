//
//  QContactLeftCell.swift
//  Qiscus
//
//  Created by asharijuang on 06/09/18.
//

import UIKit
import QiscusUI
import QiscusCore
import SwiftyJSON

class QContactLeftCell: UIBaseChatCell {
    
    @IBOutlet weak var lbNameCons: NSLayoutConstraint!
    @IBOutlet weak var nameContact: UILabel!
    @IBOutlet weak var noTelp: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var ivBaloon: UIImageView!
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbTime: UILabel!
    @IBOutlet weak var ivStatus: UIImageView!
    @IBOutlet weak var viewLine: UIView!
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
        self.viewLine.backgroundColor = QiscusColorConfiguration.sharedInstance.leftBaloonColor
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
        self.status(message: message)
        
        self.lbTime.text = message.hour()
        let data = message.payload
        let payloadJSON = JSON(data)
        self.nameContact.text = payloadJSON["name"].stringValue
        self.noTelp.text = payloadJSON["value"].stringValue
        
        if(isPublic == true){
            self.lbName.text = message.username
            self.lbName.textColor = Qiscus.style.color.randomColorLabelName.randomItem()
            lbNameCons.constant = 21
        }else{
            self.lbName.text = ""
            lbNameCons.constant = 0
        }
        
    }
    
    func setupBalon(){
        self.ivBaloon.image = self.getBallon()
        self.ivBaloon.tintColor = QiscusColorConfiguration.sharedInstance.leftBaloonColor
    }
    
    @IBAction func saveContact(_ sender: Any) {
        QiscusNotification.publishDidTapSaveContact(message: self.comment!)
    }
    
    func status(message: CommentModel){
        
        switch message.status {
        case .deleted:
            ivStatus.image = Qiscus.image(named: "ic_deleted")?.withRenderingMode(.alwaysTemplate)
            break
        case .sending, .pending:
            lbTime.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            ivStatus.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            lbTime.text = QiscusTextConfiguration.sharedInstance.sendingText
            ivStatus.image = Qiscus.image(named: "ic_info_time")?.withRenderingMode(.alwaysTemplate)
            break
        case .sent:
            lbTime.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            ivStatus.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            ivStatus.image = Qiscus.image(named: "ic_sending")?.withRenderingMode(.alwaysTemplate)
            break
        case .delivered:
            lbTime.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            ivStatus.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            ivStatus.image = Qiscus.image(named: "ic_read")?.withRenderingMode(.alwaysTemplate)
            break
        case .read:
            lbTime.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            ivStatus.tintColor = Qiscus.style.color.readMessageColor
            ivStatus.image = Qiscus.image(named: "ic_read")?.withRenderingMode(.alwaysTemplate)
            break
        case . failed:
            lbTime.textColor = QiscusColorConfiguration.sharedInstance.failToSendColor
            lbTime.text = QiscusTextConfiguration.sharedInstance.failedText
            ivStatus.image = Qiscus.image(named: "ic_warning")?.withRenderingMode(.alwaysTemplate)
            ivStatus.tintColor = QiscusColorConfiguration.sharedInstance.failToSendColor
            break
        }
    }
    
    
}
