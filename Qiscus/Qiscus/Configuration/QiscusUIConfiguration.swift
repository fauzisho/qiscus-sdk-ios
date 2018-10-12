//
//  QiscusUIConfiguration.swift
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 8/18/16.
//  Copyright © 2016 Ahmad Athaullah. All rights reserved.
//

import UIKit


/// Qiscus ui style configuration
open class QiscusUIConfiguration: NSObject {
    static var sharedInstance = QiscusUIConfiguration()
    
    @objc open var color = QiscusColorConfiguration.sharedInstance
    @objc open var copyright = QiscusTextConfiguration.sharedInstance
    @objc public var assets = QiscusAssetsConfiguration.shared
    
    @objc open var chatFont = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body){
        didSet{
            if chatFont.pointSize != UIFont.preferredFont(forTextStyle: UIFontTextStyle.body).pointSize{
                if chatFont.fontName != UIFont.preferredFont(forTextStyle: UIFontTextStyle.body).fontName {
                    rewriteChatFont = true
                }
            }
        }
    }
    
    @objc public var rewriteChatFont = false
    
    
    /// To set read only or not, Default value : false
    @objc open var readOnly = false
    
    @objc static var chatTextMaxWidth:CGFloat = 0.7 * QiscusHelper.screenWidth()
    open var topicId:Int = 0
    open var chatUsers:[String] = [String]()
    @objc open var baseColor:UIColor{
        get{
            return self.color.topColor
        }
    }
    fileprivate override init() {}
    
    /// Class function to set default style
   @objc open func defaultStyle(){
        let defaultUIStyle = QiscusUIConfiguration()
        QiscusUIConfiguration.sharedInstance = defaultUIStyle
    }
}
