import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:intl/intl.dart';

class ChatConversationPage extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String currentUserRole;
  final String targetUserId;
  final String targetUserName;
  final String targetUserRole;

  const ChatConversationPage({
    Key? key,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserRole,
    required this.targetUserId,
    required this.targetUserName,
    required this.targetUserRole,
  }) : super(key: key);

  @override
  _ChatConversationPageState createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  static const String _baseUrl = 'https://neurosense-palsy.fly.dev';

  late IO.Socket socket;
  List<Map<String, dynamic>> messages = [];
  TextEditingController messageController = TextEditingController();
  bool isConnected = false;
  bool isOnline = false;
  bool isTyping = false;
  String roomId = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  void _connectToServer() {
    socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print('Connected to server');
      setState(() => isConnected = true);

      socket.emit('register', {
        'userId': widget.currentUserId,
        'userName': widget.currentUserName,
        'role': widget.currentUserRole,
      });

      socket.emit('startConversation', {
        'targetUserId': widget.targetUserId,
      });
    });

    socket.on('conversationStarted', (data) {
      print('Conversation started: ${data['roomId']}');
      setState(() => roomId = data['roomId']);
    });

    socket.on('messageHistory', (data) {
      print('Received message history');
      if (data['messages'] != null) {
        setState(() {
          messages = List<Map<String, dynamic>>.from(data['messages']);
          messages.sort((a, b) {
            DateTime timeA = DateTime.parse(a['timestamp']);
            DateTime timeB = DateTime.parse(b['timestamp']);
            return timeA.compareTo(timeB);
          });
        });

        _scrollToBottom();
      }
    });

    socket.on('newMessage', (message) {
      print('New message received: $message');
      setState(() {
        messages.add(Map<String, dynamic>.from(message));

        if (message['senderId'] == widget.targetUserId) {
          socket.emit('markAsRead', {
            'roomId': roomId,
            'messageIds': [message['id']],
          });
        }
      });

      _scrollToBottom();
    });

    socket.on('messagesRead', (data) {
      print('Messages marked as read: ${data['messageIds']}');
      setState(() {
        for (var message in messages) {
          if (data['messageIds'].contains(message['id'])) {
            message['isRead'] = true;
          }
        }
      });
    });

    socket.on('userTyping', (data) {
      if (data['userId'] == widget.targetUserId) {
        setState(() => isTyping = data['isTyping']);
        if (data['isTyping']) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => isTyping = false);
          });
        }
      }
    });

    socket.on('user-status-changed', (data) {
      if (data['userId'] == widget.targetUserId) {
        setState(() => isOnline = data['status'] == 'online');
      }
    });

    socket.onDisconnect((_) {
      print('Disconnected from server');
      setState(() => isConnected = false);
    });

    socket.onConnectError((error) {
      print('Connection error: $error');
      setState(() => isConnected = false);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void sendMessage() {
    if (messageController.text.trim().isEmpty || roomId.isEmpty) return;

    final messageData = {
      'roomId': roomId,
      'content': messageController.text,
      'receiverId': widget.targetUserId,
    };

    socket.emit('sendMessage', messageData);
    messageController.clear();

    // Stop typing indicator
    socket.emit('typing', {'roomId': roomId, 'isTyping': false});
  }

  void _onTyping() {
    socket.emit('typing', {'roomId': roomId, 'isTyping': true});
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFFFDA4AF);
      case 'customer':
        return const Color(0xFF2196F3);
      case 'seller':
        return const Color(0xFFF9A8D4);
      case 'analyst':
        return const Color(0xFFFB7185);
      default:
        return Colors.grey;
    }
  }

  Widget buildMessage(Map<String, dynamic> msg) {
    final isSelf = msg['senderId'] == widget.currentUserId;

    String formattedTime = '';
    try {
      final timestamp = DateTime.parse(msg['timestamp']);
      formattedTime = DateFormat.jm().format(timestamp);
    } catch (e) {
      formattedTime = '';
    }

    return Align(
      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelf ? const Color(0xFFFDA4AF) : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isSelf ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isSelf ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg['content'] ?? '',
              style: TextStyle(
                fontSize: 15,
                color: isSelf ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelf ? Colors.white70 : Colors.black45,
                  ),
                ),
                if (isSelf) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg['isRead'] == true ? Icons.done_all : Icons.done,
                    size: 14,
                    color: msg['isRead'] == true ? Colors.white : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(0),
          const SizedBox(width: 4),
          _buildDot(1),
          const SizedBox(width: 4),
          _buildDot(2),
          const SizedBox(width: 6),
          Text(
            'typing...',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(widget.targetUserRole);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDA4AF),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: roleColor.withOpacity(0.3),
                  child: Text(
                    widget.targetUserName.isNotEmpty ? widget.targetUserName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFDA4AF), width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.targetUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOnline ? Colors.greenAccent : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.targetUserRole,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!isConnected)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.orange.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Connecting...',
                    style: TextStyle(fontSize: 13, color: Colors.orange.shade700),
                  ),
                ],
              ),
            ),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: messages.length + (isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && isTyping) {
                        return _buildTypingIndicator();
                      }
                      return buildMessage(messages[index]);
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      minLines: 1,
                      maxLines: 5,
                      onChanged: (text) {
                        if (text.isNotEmpty) {
                          _onTyping();
                        }
                      },
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: const Color(0xFFFDA4AF),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: isConnected ? sendMessage : null,
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.send,
                          color: isConnected ? Colors.white : Colors.white60,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
