import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';

/// Individual chat screen with message bubbles.
class ChatScreen extends StatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  // Sample messages
  final List<Map<String, dynamic>> _messages = [
    {'content': 'Hey I\'m at gate 3', 'isMine': false, 'time': '10:30'},
    {'content': 'Cool, 2 min away', 'isMine': true, 'time': '10:31'},
    {'content': 'I\'m in the yellow Honda Civic', 'isMine': false, 'time': '10:32'},
  ];

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface0,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Alex Rivera'),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.directions_car, size: 16, color: AppColors.signalYellow),
            label: Text('Detail', style: AppTextStyles.label.copyWith(color: AppColors.signalYellow)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppConstants.screenPaddingH),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                final isMine = msg['isMine'] as bool;
                return _MessageBubble(
                  content: msg['content'] as String,
                  time: msg['time'] as String,
                  isMine: isMine,
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface1,
              border: Border(top: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_msgController.text.trim().isEmpty) return;
                    setState(() {
                      _messages.add({
                        'content': _msgController.text.trim(),
                        'isMine': true,
                        'time': 'now',
                      });
                      _msgController.clear();
                    });
                  },
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.signalYellow,
                      borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
                    ),
                    child: const Icon(Icons.send, color: AppColors.systemBlack, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final String time;
  final bool isMine;

  const _MessageBubble({
    required this.content,
    required this.time,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMine
            ? AppColors.signalYellow.withOpacity(0.12)
            : AppColors.surface2,
          borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
          border: isMine
            ? Border.all(color: AppColors.signalYellow.withOpacity(0.3), width: 1)
            : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(content, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(time, style: AppTextStyles.labelSm),
          ],
        ),
      ),
    );
  }
}
