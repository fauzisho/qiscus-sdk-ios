//
//  QiscusAssetsConfiguration.swift
//  Example
//
//  Created by Ahmad Athaullah on 5/9/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit


public class QiscusAssetsConfiguration: NSObject {
    static var shared = QiscusAssetsConfiguration()
    
    @objc public var emptyChat:UIImage = Qiscus.image(named: "empty-chat")!.withRenderingMode(.alwaysTemplate)
    
    // MARK: - Chat balloon
    @objc public var leftBallonLast:UIImage? = Qiscus.image(named: "text_balloon_last_l")
    @objc public var leftBallonNormal:UIImage? = Qiscus.image(named: "text_balloon_left")
    @objc public var rightBallonLast:UIImage? = Qiscus.image(named: "text_balloon_last_r")
    @objc public var rightBallonNormal:UIImage? = Qiscus.image(named: "text_balloon_right")
}
