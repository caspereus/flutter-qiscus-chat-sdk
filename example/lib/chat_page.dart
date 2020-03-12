import 'package:bubble/bubble.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/fa_icon.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:qiscus_sdk/qiscus_sdk.dart';

class ChatPage extends StatefulWidget {
  final int roomId;
  final String roomName;
  final QiscusAccount senderAccount;

  ChatPage({
    Key key,
    @required int roomId,
    this.roomName,
    this.senderAccount,
  })  : this.roomId = roomId,
        super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String message;
  List<QiscusComment> comments = [];
  QiscusChatRoom chatRoom;

  @override
  void initState() {
    super.initState();
    _getChatRoomWithMessages();
  }

  Future<void> _getChatRoomWithMessages() async {
    var tupple = await ChatSdk.getChatRoomWithMessages(widget.roomId);
    setState(() {
      chatRoom = tupple.item1;
      comments = tupple.item2;
    });
  }

  String timeFormat(DateTime dateTime) {
    return DateFormat("HH:mm").format(dateTime);
  }

  IconData getCommentState(QiscusComment comment) {
    switch (comment.state) {
      case QiscusComment.STATE_SENDING:
        return FontAwesomeIcons.hourglassHalf;
      case QiscusComment.STATE_FAILED:
        return FontAwesomeIcons.times;
      case QiscusComment.STATE_DELIVERED:
        return FontAwesomeIcons.checkDouble;
      case QiscusComment.STATE_READ:
        return FontAwesomeIcons.eye;
      default:
        return FontAwesomeIcons.hourglassHalf;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
      ),
      body: ListView(
        children: [
          Container(
            height: 550,
            child: ListView(
              shrinkWrap: true,
              children: comments.reversed.map((QiscusComment comment) {
                return Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: <Widget>[
                      Bubble(
                        alignment: widget.senderAccount.email == comment.senderEmail
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        color: widget.senderAccount.email == comment.senderEmail
                            ? Colors.lightBlueAccent
                            : Colors.white,
                        child: Text(
                          comment.message.trim(),
                          style: TextStyle(),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: widget.senderAccount.email == comment.senderEmail
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: <Widget>[
                          Text(timeFormat(comment.time.toLocal())),
                          FaIcon(getCommentState(comment))
                        ],
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          Row(
            children: <Widget>[
              Container(
                width: 300,
                padding: EdgeInsets.all(5),
                child: TextField(
                  onChanged: (String text) {
                    message = text;
                  },
                  textInputAction: TextInputAction.newline,
                ),
              ),
              RaisedButton(
                color: Colors.blue,
                textColor: Colors.white,
                child: Icon(
                  Icons.send,
                  size: 25,
                ),
                onPressed: () async {
                  var comment = await ChatSdk.sendMessage(
                    roomId: widget.roomId,
                    message: message,
                    type: CommentType.TEXT,
                  );

                  setState(() {
                    comments.add(comment);
                  });
                },
              )
            ],
          ),
        ],
      ),
    );
  }
}
