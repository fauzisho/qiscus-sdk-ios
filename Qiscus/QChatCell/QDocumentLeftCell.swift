//
//  QDocumentLeftCell.swift
//  Qiscus
//
//  Created by asharijuang on 05/09/18.
//

import UIKit
import QiscusUI
import QiscusCore

class QDocumentLeftCell: UIBaseChatCell {
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbTime: UILabel!
    @IBOutlet weak var balloonView: UIImageView!
    @IBOutlet weak var fileContainer: UIView!
    @IBOutlet weak var fileIcon: UIImageView!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var fileTypeLabel: UILabel!
    
    @IBOutlet weak var ivStatus: UIImageView!
    
    var fileName: String = ""
    var url: String = ""
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        fileIcon.image = Qiscus.image(named: "ic_file")?.withRenderingMode(.alwaysTemplate)
        fileIcon.contentMode = .scaleAspectFit
        fileIcon.tintColor = QiscusColorConfiguration.sharedInstance.leftBaloonColor
        
        let imgTouchEvent = UITapGestureRecognizer(target: self, action: #selector(QDocumentLeftCell.documentDidTap))
        self.fileContainer.addGestureRecognizer(imgTouchEvent)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func documentDidTap() {
        let preview = ChatPreviewDocVC()
        preview.fileName = fileName
        preview.url = url
        preview.roomName = "Document Preview"
        let backButton = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        self.currentViewController()?.navigationItem.backBarButtonItem = backButton
        self.currentViewController()?.navigationController?.pushViewController(preview, animated: true)

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
        
        self.lbName.text = message.username
        self.lbTime.text = self.hour(date: message.date())
        
        let ext = getExt(message: message)
        
        if ext == "doc" || ext == "docx" || ext == "ppt" || ext == "pptx" || ext == "xls" || ext == "xlsx" || ext == "txt" {
            fileTypeLabel.text = "\(ext.uppercased()) File"
        }else{
            fileTypeLabel.text = "Unknown File"
        }
        
        
    }
    
    func setupBalon(){
        self.balloonView.image = self.getBallon()
        self.balloonView.tintColor = QiscusColorConfiguration.sharedInstance.leftBaloonColor
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
    
    func getExt(message: CommentModel) -> String{
        let json = message.payload
        guard let payload = message.payload else {
            return "unknow"
        }
        let fileURL = payload["url"] as? String
        self.url = fileURL!
        var filename = message.fileName(text: fileURL!)
        
        if filename.contains("-"){
            let nameArr = filename.split(separator: "-")
            var i = 0
            for comp in nameArr {
                switch i {
                case 0 : filename = "" ; break
                case 1 : filename = "\(String(comp))"
                default: filename = "\(filename)-\(comp)"
                }
                i += 1
            }
        }
        
        self.fileName = filename
        
        self.fileNameLabel.text = filename
        
        var ext = "unknow"
        if filename.range(of: ".") != nil{
            let fileNameArr = filename.split(separator: ".")
            ext = String(fileNameArr.last!).lowercased()
        }
        
        return ext
    }
    
    func currentViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        
        if let nav = base as? UINavigationController {
            return currentViewController(base: nav.visibleViewController)
        }
        
        if let tab = base as? UITabBarController {
            let moreNavigationController = tab.moreNavigationController
            
            if let top = moreNavigationController.topViewController, top.view.window != nil {
                return currentViewController(base: top)
            } else if let selected = tab.selectedViewController {
                return currentViewController(base: selected)
            }
        }
        
        if let presented = base?.presentedViewController {
            return currentViewController(base: presented)
        }
        
        return base
    }
    
}