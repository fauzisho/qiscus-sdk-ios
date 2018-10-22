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
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Chat List"
        self.delegate = self
        QiscusUI.delegate = self
        
        self.registerCell(nib: UINib(nibName: "QRoomListDefaultCell", bundle: Qiscus.bundle), forCellWithReuseIdentifier: "defaultCell")
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
    }
}

extension QRoomList: UIChatListViewDelegate {
    public func uiChatList(viewController: UIChatListViewController, cellForRoom room: RoomModel) -> String? {
        let cell = "defaultCell"
        
        return cell
    }
}

extension QRoomList : UIChatDelegate {
    public func onRoom(update room: RoomModel) {
        QiscusNotification.publish(roomChange: room)
    }
    
    public func onRoom(_ room: RoomModel, gotNewComment comment: CommentModel) {
        QiscusNotification.publish(gotNewComment: comment, room: room)
        QiscusNotification.publish(roomOrder: true)
    }
    
    public func onRoom(_ room: RoomModel, didChangeComment comment: CommentModel, changeStatus status: CommentStatus) {
        QiscusNotification.publish(messageStatus: comment, status: status, room: room)
        
        if(status == .deleted){
            QiscusNotification.publish(commentDeleteOnRoom: room, comment: comment, status: status)
        }
    }
    
    public func onRoom(_ room: RoomModel, thisParticipant user: MemberModel, isTyping typing: Bool) {
        QiscusNotification.publish(userTyping: user, room: room, typing: typing)
    }
    
    public func onChange(user: MemberModel, isOnline online: Bool, at time: Date) {
        QiscusNotification.publish(userPresence: user, isOnline: online, at: time)
    }
    
    public func gotNew(room: RoomModel) {
        QiscusNotification.publish(gotNewRoom: room)
    }
    
    public func remove(room: RoomModel) {
        QiscusNotification.publish(roomDeleted: room.id)
    }
}

