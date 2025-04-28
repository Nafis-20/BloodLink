import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatbotPage extends StatefulWidget {
  final String uid; // User's ID from login or registration

  const ChatbotPage({Key? key, required this.uid}) : super(key: key);

  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _messages = []; // Store messages (user and bot)

  late String _userName = "User"; // Default, will load from Firestore later

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    // Load user's info from Firestore
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .get();

    if (userDoc.exists) {
      setState(() {
        _userName = userDoc['name'] ?? 'User';
      });
    }
  }

  void _sendMessage() {
    String input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': input});
    });

    _controller.clear();

    _generateBotResponse(input);
  }

  void _generateBotResponse(String input) async {
    String response = await _getBotResponse(input);

    setState(() {
      _messages.add({'sender': 'bot', 'text': response});
    });
  }

  Future<String> _getBotResponse(String input) async {
    input = input.toLowerCase();

    // Simple hardcoded responses
    if (input.contains('hello') || input.contains('hi')) {
      return "Hello $_userName! 👋 How can I assist you today?";
    } else if (input.contains('blood') && input.contains('donate')) {
      return "Thank you for your interest! 🩸 You can donate blood every 3-4 months if you are healthy.";
    } else if (input.contains('emergency') || input.contains('help')) {
      return "In case of emergency, please call 999 (Bangladesh Emergency Service) immediately.";
    } else if (input.contains('register')) {
      return "You are already registered with us, $_userName! ✅";
    } else if (input.contains('hospital') || input.contains('clinic')) {
      return "You can visit nearby hospitals like Dhaka Medical College, BSMMU, or your nearest Upazila Health Complex.";
    } else if (input.contains('how are you')) {
      return "I'm doing great! 🤖 Thanks for asking, $_userName.";
    } else {
      // Firestore based dynamic search (optional improvement)
      return "I'm still learning! 🤔 Please ask about blood donation, registration, emergency, or hospitals.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with Bot 🤖'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['sender'] == 'user';
                return Container(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      message['text'] ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
