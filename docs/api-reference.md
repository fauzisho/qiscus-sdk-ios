# IOS SDK API Reference

## Init

### Using App ID

Client side call this function.

```
import Qiscus
import QiscusCore
Qiscus.setup( withAppId: "app_id",
                          userEmail: "youremail.com",
                          userKey: "yourpassword",
                          username: "yourname",
                          avatarURL: "",
                          delegate: nil
            )
```
sample usage in client side using extras like this :
```
var extras: [String: Any] = [
    "key1": "example value 1",
    "key2": "example value 2"
]

Qiscus.setup( withAppId: "sampleapp-65ghcsaysse",
                    userEmail: "abcde1234@qiscus.com",
                    userKey: "abcde1234",
                    username: "steve Kusuma",
                    avatarURL: "",
                    extras : extras,
                    delegate: self
            )
```

### Using custom server

```
import Qiscus

Qiscus.setRealtimeServer(withBaseUrl baseUrl: URL, realtimeServer:String?, port:Int = 1883)
```

## Authentication

### Using `UserID` and `UserKey`

```
import Qiscus

Qiscus.setup( withAppId: "app_id",
                          userEmail: "youremail.com",
                          userKey: "yourpassword",
                          username: "yourname",
                          avatarURL: "",
                          delegate: nil
            )
```

### Using JWT

Client side call this function.

```
import Qiscus

Qiscus.getNonce(withAppId: "APP_ID", onSuccess: { (nonce) in
    print("get nonce here : \(nonce)")
}, onFailed: { (error) in
    print("error : \(error)")
})
```

Verify the Identity Token and call this setup function.

```
import Qiscus

Qiscus.setup(withUserIdentityToken: "IDENTITY_TOKEN")
```

Sample usage.

```
import Qiscus

Qiscus.getNonce(withAppId: YOUR_APP_ID, onSuccess: { (nonce) in
    print("get nonce here : \(nonce)")    
    
    // this is your own service that call your own server
    // you pass your user credential together with nonce from Qiscus server that just being received
    MyHTTPService.callAuth(params: {user: userDetails, nonce: nonce}, onSuccess: { (data) in
    
        // success authenticate to your own server
        // now time to verify the identity token from your server to Qiscus Server
        Qiscus.setup( 
              withUserIdentityToken: data.identity_token,
              delegate: self
        )
    }, onError: { (error) in 
        // your auth error callback
    })
}, onError: { (error) in
    print("error : \(error)")
})
```

## User

### Update User Profile And Profile Image

```
Qiscus.updateProfile(username: username, avatarURL: avatar, onSuccess: { 
            print("success profile")
        }) { (error) in
            print("error update profile: \(error)")
        }
```

### Example Using Extras

```
var dataExtras: [String: Any] = [
"key1": "example value 1",
"key2": "example value 2"
]

Qiscus.updateProfile(username: "username", avatarURL: nil, extras: dataExtras, onSuccess: {
    print("success")
}) { (error) in
    print("error\(error)")
}
```

### Login Status

```
Qiscus.isLoggedIn // return true or false
```

### Logout

```
Qiscus.clear()
```

## Message

### Send Text Message

```
 let comment = room.newComment(roomId: "", text: "") // create new text message on room
 room.post(comment: CommentModel) // post message on room
```

### Send File Attachment

```
import QiscusCore
QiscusCore.shared.upload(data: data, filename: fileName, onSuccess: { (file) in
    let message = CommentModel()
    message.type = "file_attachment"
    message.payload = [
        "url"       : file.url.absoluteString,
        "file_name" : file.name,
        "size"      : file.size,
        "caption"   : "your caption"
        ]
    message.message = "Send Attachment"
    room.post(comment: message)
}, onError: { (error) in
    print("error =\(error)")
}) { (progress) in
    Qiscus.printLog(text: "upload progress: \(progress)")
}

```

### Send Custom Message

```
let comment = room.newCustomComment(type:String, payload:String, text:String? = nil ) //create new custom message on room
room.post(comment: comment) //post message on room
```

Example.

```
let comment = room.newCustomComment(type:"custom", payload:"{ \"key\": \"value\"}", text:"THIS IS CUSTOM MESSAGE" )
room.post(comment: comment)
```

### Load Messages

```
/// Load Comment by room
///
/// - Parameters:
///   - id: Room ID
///   - limit: by default set 20, min 0 and max 100
///   - completion: Response new Qiscus Array of Comment Object and error if exist.
room.loadComments(roomID: "", onSuccess: { (comments) in

}, onError: { (error) in

})
room.loadComments(roomID: String, limit: 20, onSuccess: { (comments) in
        // comments contain array of QComment objects
}) { (error) in
        print(error)
}
```

### Load More

```
// this method will give the messages before the offset given
room.loadMore(roomID: "123", lastCommentID: 231, limit: 20, onSuccess: { (comments, hasMoreMessages) in
        // comments contain array of QComment objects
        // hasMoreMessages signifies that there is still another message before the first message, this is Boolean (true/false) 
}) { (error) in
   print(error)
}
```

### Search Message

```
Qiscus.searchComment(withQuery: (self.searchViewController?.searchBar.text)!, onSuccess: { (comments) in
        self.filteredComments = comments
        self.tableView.reloadData()
        print("success search comment with result:\n\(comments)")
}, onFailed: { (error) in
        print("fail to get search result")
})
```

### Delete Message

To delete one message, we have to provide data QComment.

```
let deletecomment = self.room!.comments[index.row]
```

Delete with this function.

```
var arrayDeleteComment = [String]()
arrayDeleteComment.append(deletecomment.uniqueTempId)

deletecomment.deleteMessage(uniqueIDs id: arrayDeleteComment, type: DeleteType.forMe, onSuccess: { in
    print("success")
}, onError: { (error) in
    print("delete error: \(error)")
})
```

### Delete All Messages

```
var room:QRoom?
var arrayRoom = [String]()
arrayRoom(room.id)
self.room?.deleteAllMessage(roomID: arrayRoom, onSuccess: {
    print("success")
}, onError: { (error) in
    print(error)
})
```

## Room

### Create Group Room

```
Qiscus.newRoom(withUsers: ["user_id1", "user_id2"], roomName: "My RoomName", onSuccess: { (room) in
    // room data in QRoom object
}) { (error) in
    // resulting error in String
} 
```

### Get Chat Room By ID

```
Qiscus.room(withId: roomId, onSuccess: { (room) in
    // room data in QRoom object
    // for accessing comments inside room
    let comments = room.listComment // ressulting array of QComment
}) { (error) in
    // resulting error in String
}
```

### Get Chat Room By Channel

```
Qiscus.room(withChannel: channelName, onSuccess: { (room) in
    // room data in QRoom object
    // for accessing comments inside room
    let comments = room.listComment // ressulting array of QComment
}) { (error) in
    // resulting error in String
}
```

### Get Chat Room Opponent By User ID

```
Qiscus.room(withUserId: userId, onSuccess: { (room) in
    // room data in QRoom object
    // for accessing comments inside room
    let comments = room.listComment // ressulting array of QComment
}) { (error) in
    // resulting error in String
}
```

### Get Room Info With ID

```
Qiscus.roomInfo(withId: "13456", onSuccess: { (room) in
    // room data in QRoom object
}) { (error) in
    // resulting error in string
}
```

### Get Multiple Room Info

```
Qiscus.roomsInfo(withIds: ["12345", "13456"], onSuccess: { (rooms) in
    // rooms data in array of QRoom object
}) { (error) in
    // resulting error in string
}
```

### Get Channel Info

```
Qiscus.channelInfo(withName: "myChannel", onSuccess: { (room) in
    // room data in QRoom object
}) { (error) in
    // resulting error in string
}
```

### Get Multiple Channel Info

```
Qiscus.channelsInfo(withNames: ["myChannel1","myChannel2"], onSuccess: { (rooms) in
    // rooms data in array of QRoom object
}) { (error) in
    // resulting error in string
}
```

### Get Room List

```
Qiscus.roomList(withLimit: 100, page: 1, onSuccess: { (rooms, totalRoom,currentPage) in
    // rooms contains array of room
    // totalRoom = total room in server
}) { (error) in
    // resulting error in string
}
```

### Get Room List in LocalDB

```
let rooms = QRoom.all()
```

### Update Room

```
var room:QRoom?
room.update(withID : "roomId", roomName: roomName, roomAvatarURL: avatar, onSuccess: { (qRoom) in
    //success update
}, onError: { (error) in
    //error
})
```

### Get List Of Participant in a Room

```
Qiscus.room(withId: roomId!, onSuccess: { (room) in
    // getroom list participant
    let allparticipant = room.participants
}) { (error) in
    print("error =\(error)")
}
```

### Add participant in a Room

```
Qiscus.addParticipant(onRoomId: "String", userEmails: ["email"], onSuccess: { (members) in
    print("success")
}) { (error) in
    print("error")
}

```

### Remove participant in a Room

```
Qiscus.removeParticipant(onRoomId: "String", userEmails: ["email"], onSuccess: { (members) in
    print("success")
}) { (error) in
    print("error")
}
```

### Get total unread count

```
Qiscus.getAllUnreadCount(onSuccess: { (unread) in
    print(" unread count " + "\(unread)")
}) { (error) in
    print("error " + error)
}
```

## Statuses

### Publish Start Typing

```
room.publishStartTyping(roomID: room.id)
```

### Publish Stop Typing

```
room.publishStopTyping(roomID: room.id)
```

### Update Message Read Status

```
QRoom.publishStatus(roomId: roomId, commentId: commentId)
```

## Event Handler

### New Messages

Listen to notification.

```
NotificationCenter.default.addObserver(self, selector: #selector(YOUR_CLASS.userTyping(_:)), name: QiscusNotification.USER_TYPING(onRoom: "Your room id"), object: nil)
```

Get data on your selector.

```
func newCommentNotif(_ notification: Notification){
        if let userInfo = notification.userInfo {
            let comment = userInfo["comment"] as! QComment
            
            // if you want to get the room where the comment is
            let room = comment.room
            // *note: it can be nil
        }
    }
```

### Typing

Subscribe All Room to get notification

```
//Just call Qiscus.fetchAllRoom
Qiscus.fetchAllRoom(onSuccess: { (qRoom) in
    print("success")
}) { (error) in
    print("error")
}

//or Qiscus.roomList
Qiscus.roomList(withLimit: 100, page: 1, onSuccess: { (qRooms, totalRooms, currentPage) in
    print("success")
}) { (error) in
    print("error")
}
```

Listen to notification.

```
NotificationCenter.default.addObserver(self, selector: #selector(YOUR_CLASS.userTyping(_:)), name: QiscusNotification.USER_TYPING(onRoom: "Your room id"), object: nil)
```

Get data on your selector.

```
func userTyping(_ notification: Notification){
        if let userInfo = notification.userInfo {
            let user = userInfo["user"] as! UserModel
            let typing = userInfo["typing"] as! Bool
            let room = userInfo["room"] as! RoomModel
            
            // typing can be true or false
        }
}
```

## Notification

### Push Notification

Register device token. Will Receive Push Notification in AppDelegate on didReceiveRemoteNotification 

```
Qiscus.didRegisterUserNotification(withToken: token)
```


