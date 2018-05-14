//
//  BaseChatCell.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 09/05/18.
//

import Foundation

class BaseChatCell: UITableViewCell {
    var firstInSection: Bool = false
    var comment: CommentModel! {
        didSet {
            bindDataToView()
        }
    }
    
    var indexPath: IndexPath!
    
    func bindDataToView() {
        
    }
}
