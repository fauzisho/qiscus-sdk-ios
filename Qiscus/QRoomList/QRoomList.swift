//
//  ListChatViewController.swift
//  example
//
//  Created by Qiscus on 30/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import UIKit
import QiscusUI
import QiscusCore

open class QRoomList: UIChatListViewController {
    var roomData : [QRoom] = [QRoom]()
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Chat List"
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let room = self.rooms[indexPath.row]
        self.chat(withRoom: room)
    }
    
    open func chat(withRoom room: RoomModel){
        let target = QiscusChatVC()
        target.room = room
        self.navigationController?.pushViewController(target, animated: true)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        //QiscusCore.delegate = self
    }
}

extension QRoomList : QiscusCoreDelegate {
    public func onRoom(_ room: RoomModel, gotNewComment comment: CommentModel) {
        Qiscus.listChatDelegate?.onRoom(room as! QRoom, gotNewComment: comment as! QComment)
    }

    public func onRoom(_ room: RoomModel, didChangeComment comment: CommentModel, changeStatus status: CommentStatus) {
       
        Qiscus.listChatDelegate?.onRoom(room as! QRoom, didChangeComment: comment as! QComment, changeStatus: status)
    }

    public func onRoom(_ room: RoomModel, thisParticipant user: MemberModel, isTyping typing: Bool) {
        
        Qiscus.listChatDelegate?.onRoom(room as! QRoom, thisParticipant: user as! QMember, isTyping: typing)
    }

    public func onChange(user: MemberModel, isOnline online: Bool, at time: Date) {
       Qiscus.listChatDelegate?.onChange(user: user as! QMember, isOnline: online, at: time)
    }

    public func gotNew(room: RoomModel) {
        
        Qiscus.listChatDelegate?.gotNew(room: room as! QRoom)
    }

    public func remove(room: RoomModel) {
        
        Qiscus.listChatDelegate?.remove(room: room as! QRoom)
    }

}
