import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'chat-conversation.dart';

class ChatContactsPage extends StatefulWidget {
  final String userEmail;
  final String userName;
  final String userRole;

  const ChatContactsPage({
    Key? key,
    required this.userEmail,
    required this.userName,
    required this.userRole,
  }) : super(key: key);

  @override
  _ChatContactsPageState createState() => _ChatContactsPageState();
}

class _ChatContactsPageState extends State<ChatContactsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _conversations = [];
  List<dynamic> _allUsers = [];
  List<dynamic> _filteredUsers = [];
  Map<String, bool> _onlineUsers = {};
  bool _isLoadingConversations = false;
  bool _isLoadingUsers = false;
  IO.Socket? socket;
  final TextEditingController _searchController = TextEditingController();

  final String apiUrl = 'https://neurosense-palsy.fly.dev/api/v1';
  final String socketUrl = 'https://neurosense-palsy.fly.dev';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _connectSocket();
    _fetchConversations();
    _fetchAllUsers();

    _searchController.addListener(_filterUsers);
  }

  void _connectSocket() {
    socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket?.on('connect', (_) {
      print('Socket connected!');
      socket?.emit('register', {
        'userId': widget.userEmail,
        'userName': widget.userName,
        'role': widget.userRole,
      });
      socket?.emit('getOnlineUsers', {});
    });

    socket?.on('onlineUsers', (data) {
      if (mounted) {
        setState(() {
          _onlineUsers.clear();
          for (var user in data) {
            _onlineUsers[user['userId']] = true;
          }
        });
      }
    });

    socket?.on('user-status-changed', (data) {
      if (mounted) {
        setState(() {
          _onlineUsers[data['userId']] = data['status'] == 'online';
        });
      }
    });

    socket?.on('newMessage', (data) {
      if (mounted) {
        _fetchConversations();
      }
    });

    socket?.on('newConversation', (data) {
      if (mounted) {
        _fetchConversations();
      }
    });

    socket?.connect();
  }

  Future<void> _fetchConversations() async {
    setState(() => _isLoadingConversations = true);
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/chat/conversations/${widget.userEmail}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _conversations = data['data'];
          });
        }
      }
    } catch (e) {
      print('Error fetching conversations: $e');
    } finally {
      setState(() => _isLoadingConversations = false);
    }
  }

  Future<void> _fetchAllUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final response = await http.get(Uri.parse('$apiUrl/chat/users'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _allUsers = data['data']
                .where((user) => user['email'] != widget.userEmail)
                .toList();
            _filteredUsers = _allUsers;
          });
        }
      }
    } catch (e) {
      print('Error fetching users: $e');
    } finally {
      setState(() => _isLoadingUsers = false);
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        return user['name'].toLowerCase().contains(query) ||
            user['email'].toLowerCase().contains(query);
      }).toList();
    });
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'seller':
        return Colors.green;
      case 'customer':
        return Colors.blue;
      case 'analyst':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Widget _buildChatsTab() {
    if (_isLoadingConversations) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFDA4AF)));
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a chat from the Contacts tab',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFFDA4AF),
      onRefresh: _fetchConversations,
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conv = _conversations[index];
          final otherUser = conv['otherUser'];
          final isOnline = _onlineUsers[otherUser['email']] ?? false;

          return ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: _getRoleColor(otherUser['type']),
                  child: Text(
                    _getInitials(otherUser['name']),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    otherUser['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  _formatTimestamp(conv['lastMessageTime']),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRoleColor(otherUser['type']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    otherUser['type'],
                    style: TextStyle(
                      fontSize: 10,
                      color: _getRoleColor(otherUser['type']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    conv['lastMessage'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            trailing: conv['unreadCount'] > 0
                ? Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDA4AF),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${conv['unreadCount']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatConversationPage(
                    currentUserId: widget.userEmail,
                    currentUserName: widget.userName,
                    currentUserRole: widget.userRole,
                    targetUserId: otherUser['email'],
                    targetUserName: otherUser['name'],
                    targetUserRole: otherUser['type'],
                  ),
                ),
              ).then((_) => _fetchConversations());
            },
          );
        },
      ),
    );
  }

  Widget _buildContactsTab() {
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFDA4AF)));
    }

    // Group users by role
    final groupedUsers = <String, List<dynamic>>{};
    for (var user in _filteredUsers) {
      final role = user['type'] as String;
      groupedUsers.putIfAbsent(role, () => []);
      groupedUsers[role]!.add(user);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFFFDA4AF)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Color(0xFFFDA4AF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Color(0xFFFDA4AF), width: 2),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: groupedUsers.keys.length,
            itemBuilder: (context, index) {
              final role = groupedUsers.keys.elementAt(index);
              final users = groupedUsers[role]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getRoleColor(role),
                      ),
                    ),
                  ),
                  ...users.map((user) {
                    final isOnline = _onlineUsers[user['email']] ?? false;
                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: _getRoleColor(user['type']),
                            child: Text(
                              _getInitials(user['name']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        user['name'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        user['email'],
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user['type']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user['type'],
                          style: TextStyle(
                            fontSize: 11,
                            color: _getRoleColor(user['type']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatConversationPage(
                              currentUserId: widget.userEmail,
                              currentUserName: widget.userName,
                              currentUserRole: widget.userRole,
                              targetUserId: user['email'],
                              targetUserName: user['name'],
                              targetUserRole: user['type'],
                            ),
                          ),
                        ).then((_) => _fetchConversations());
                      },
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFDA4AF),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'CHATS'),
            Tab(text: 'CONTACTS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatsTab(),
          _buildContactsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFDA4AF),
        child: const Icon(Icons.chat, color: Colors.white),
        onPressed: () {
          _tabController.animateTo(1);
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }
}
