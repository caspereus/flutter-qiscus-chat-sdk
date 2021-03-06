//
//  QiscusEventHandler.swift
//  CocoaAsyncSocket
//
//  Created by ArifCebe on 17/06/20.
//

import Foundation
import Flutter
import QiscusCore



class QiscusEventHandler {
    private var eventChannel: FlutterEventChannel!
    private let EVENT_CHANNEL_NAME: String = "bahaso.com/qiscus_chat_sdk/events"
    private let qiscusSdkHelper: QiscusSdkHelper = QiscusSdkHelper()
    private var eventStreamHandler: QiscusEventStreamHandler
    
    private func getEventSink() -> FlutterEventSink? {
        return eventStreamHandler.eventSink
    }
    
    init(binary messenger: FlutterBinaryMessenger) {
        eventStreamHandler = QiscusEventStreamHandler()
        eventChannel = FlutterEventChannel(name: EVENT_CHANNEL_NAME, binaryMessenger: messenger)
        eventChannel.setStreamHandler(eventStreamHandler)
        
        self.connect()
    }
    
    private func connect() {
        if QiscusCore.hasSetupUser() {
            let _ = QiscusCore.connect(delegate: self)
        }
    }

    public func registerEventBus(){
        QiscusCore.delegate = self
    }
    
    public func unRegisterEventBus(){
        QiscusCore.delegate = nil
    }
    
    public func onFileUploadProgress(withProgress progress: Double) {
        if let eventSink = getEventSink() {
            var result: [String: Any] = [:]
            result["type"] = "file_upload_progress"
            result["progress"] = progress
            
            eventSink(qiscusSdkHelper.toJson(withData: result))
        }
    }
}

// MARK: Core Delegate List of Chat Rooms
extension QiscusEventHandler: QiscusCoreDelegate {
    
    func onRoomMessageReceived(_ room: RoomModel, message: CommentModel) {
        self.handleMessageRecieved(messageComment: message)
    }
    
    func onRoomMessageDeleted(room: RoomModel, message: CommentModel) {
        let commentDic = self.qiscusSdkHelper.commentModelToDic(withComment: message, room)
        
        var args: [String: Any] = [String: Any]()
        args["type"] = "chat_room_event_received"
        args["chatRoomEvent"] = self.qiscusSdkHelper.toJson(withData: commentDic)
        
        if let eventSink = getEventSink() {
            DispatchQueue.main.async {
                eventSink(self.qiscusSdkHelper.toJson(withData: args))
            }
        }
    }
    
    func onRoomMessageDelivered(message: CommentModel) {
        // ROOM meessage deliverd
        handleMessageState(messageComment: message)
    }
    
    func onRoomMessageRead(message: CommentModel) {
        // message has been read
        handleMessageState(messageComment: message)
    }
    
    func onChatRoomCleared(roomId: String) {
        // chat room cleared
    }
    
    func onRoomDidChangeComment(comment: CommentModel, changeStatus status: CommentStatus) {
        var args: [String: Any] = [String: Any]()
        let commentDic = self.qiscusSdkHelper.commentModelToDic(withComment: comment)
        
        args["type"] = "comment_received"
        args["comment"] = self.qiscusSdkHelper.toJson(withData: commentDic)
        
        if let eventSink = getEventSink() {
            eventSink(self.qiscusSdkHelper.toJson(withData: args))
        }
    }
    
    func onRoom(update room: RoomModel) {
        // depracated method
    }
    
    func onRoom(deleted room: RoomModel) {
        // depracated method
    }
    
    func gotNew(room: RoomModel) {
        // depracated method
    }
    
}

// MARK: Core Delegate of Chat Room
extension QiscusEventHandler: QiscusCoreRoomDelegate{
    func onMessageReceived(message: CommentModel) {
        handleMessageRecieved(messageComment: message)
    }
    
    func didComment(comment: CommentModel, changeStatus status: CommentStatus) {
        // sfasdfa
    }
    
    func onMessageDelivered(message: CommentModel) {
        handleMessageState(messageComment: message)
    }
    
    func onMessageRead(message: CommentModel) {
        handleMessageState(messageComment: message)
    }
    
    func onMessageDeleted(message: CommentModel) {
        handleMessageState(messageComment: message)
    }
    
    func onUserTyping(userId: String, roomId: String, typing: Bool) {
        // TODO handle user typing
        if let user = QiscusCore.database.member.find(byUserId: userId) {
            QiscusCore.shared.publishTyping(roomID: roomId, isTyping: typing)
        }
    }
    
    func onUserOnlinePresence(userId: String, isOnline: Bool, lastSeen: Date) {
        // TODO handle state on Qiscus
        let user = QiscusCore.database.member.find(byUserId: userId)
        
    }
    
    private func handleMessageState(messageComment message: CommentModel){
        var args: [String: Any] = [String: Any]()
        let commentDic = self.qiscusSdkHelper.commentModelToDic(withComment: message)
        
        args["type"] = "chat_room_event_received"
        args["chatRoomEvent"] = self.qiscusSdkHelper.toJson(withData: commentDic)
        
        if let eventSink = getEventSink() {
            DispatchQueue.main.async {
                eventSink(self.qiscusSdkHelper.toJson(withData: args))
            }
        }
    }
    
    private func handleMessageRecieved(messageComment message: CommentModel){
        var args: [String: Any] = [String: Any]()
        let commentDic = self.qiscusSdkHelper.commentModelToDic(withComment: message)
        
        args["type"] = "comment_received"
        args["comment"] = commentDic
        
        if let eventSink = getEventSink() {
            DispatchQueue.main.async {
                eventSink(self.qiscusSdkHelper.toJson(withData: args))
            }
        }
    }
    
}

extension QiscusEventHandler: QiscusConnectionDelegate {
    func connectionState(change state: QiscusConnectionState) {
        sendConnectionState(change: state)
    }
    
    func onConnected() {
        sendConnectionState(change: .connected)
    }
    
    func onReconnecting() {
        sendConnectionState(change: .connecting)
    }
    
    func onDisconnected(withError err: QError?) {
        sendConnectionState(change: .disconnected)
    }
    
    private func sendConnectionState(change state: QiscusConnectionState){
        var connectionState: String = ""
        switch state {
        case .connected:
            connectionState = "connected"
            break
        case .connecting:
            connectionState = "reconnecting"
            break
        case .disconnected:
            connectionState = "disconnected"
            break
        }
        var args: [String: Any] = [String: Any]()
        args["status"] = connectionState
        
        if let eventSink = getEventSink() {
            eventSink(self.qiscusSdkHelper.toJson(withData: args))
        }
    }
    
}

class QiscusEventStreamHandler: NSObject, FlutterStreamHandler {
    var eventSink: FlutterEventSink?
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        
        return nil
    }
}
