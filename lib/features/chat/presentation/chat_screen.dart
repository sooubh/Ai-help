import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../services/ai_service.dart';
import '../../../services/firebase_service.dart';
import '../../../services/tts_service.dart';
import '../../../models/chat_message_model.dart';

/// Premium AI Chat screen with Gemini integration,
/// streaming responses, voice output, and safety disclaimer.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseService _firebaseService = FirebaseService();
  final TtsService _ttsService = TtsService();

  final List<_ChatMsg> _messages = [];
  bool _isTyping = false;
  bool _ttsEnabled = false;
  bool _isListening = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initChat();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    if (mounted) setState(() {});
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else if (_speechAvailable) {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _messageController.text = result.recognizedWords;
          });
          if (result.finalResult) {
            setState(() => _isListening = false);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _initChat() async {
    // Capture reference before async gap
    final aiService = context.read<AiService>();
    final profile = await _firebaseService.getChildProfile();
    aiService.startChatSession(childProfile: profile);

    // Load chat history from Firestore (last 50)
    try {
      final stream = _firebaseService.getChatMessages();
      final messages = await stream.first;
      if (messages.isNotEmpty && mounted) {
        final historyMsgs = messages.take(50).map((msg) {
          return _ChatMsg(
            text: msg.message,
            isUser: msg.sender == 'user',
          );
        }).toList();

        setState(() {
          _messages.addAll(historyMsgs);
        });
        _scrollToBottom();
      }
    } catch (_) {
      // History load failed, proceed with welcome message
    }

    // Add welcome message if no history
    if (_messages.isEmpty) {
      _messages.add(_ChatMsg(
        text: AppStrings.chatWelcome,
        isUser: false,
      ));
      if (mounted) setState(() {});
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping) return;

    // Add user message
    setState(() {
      _messages.add(_ChatMsg(text: text, isUser: true));
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // Capture AI service reference before async gap
    final aiService = context.read<AiService>();

    // Save user message to Firestore
    await _firebaseService.sendChatMessage(ChatMessageModel(
      id: '',
      message: text,
      sender: 'user',
      timestamp: DateTime.now(),
    ));

    // Get AI response
    try {
      final response = await aiService.getResponse(text);

      if (!mounted) return;

      setState(() {
        _messages.add(_ChatMsg(text: response, isUser: false));
        _isTyping = false;
      });

      // Save AI response to Firestore
      await _firebaseService.sendChatMessage(ChatMessageModel(
        id: '',
        message: response,
        sender: 'ai',
        timestamp: DateTime.now(),
      ));

      // Speak response if TTS is enabled
      if (_ttsEnabled) {
        _ttsService.speak(response);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMsg(
          text: 'Sorry, I encountered an error. Please try again.',
          isUser: false,
        ));
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          // Disclaimer banner
          _buildDisclaimerBanner(isDark),

          // Messages area
          Expanded(
            child: _messages.isEmpty && !_isTyping
                ? _buildSuggestedPrompts(isDark)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator(isDark);
                      }
                      return _buildMessageBubble(
                          _messages[index], isDark, index);
                    },
                  ),
          ),

          // Input area
          _buildInputArea(isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B6EF5), Color(0xFFA855F7)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(AppStrings.chatTitle),
        ],
      ),
      actions: [
        // Voice Assistant toggle
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/voice-assistant'),
          icon: const Icon(Icons.mic_rounded, size: 22),
          tooltip: 'Voice Assistant',
        ),
        // TTS toggle
        IconButton(
          onPressed: () {
            setState(() => _ttsEnabled = !_ttsEnabled);
            if (!_ttsEnabled) _ttsService.stop();
          },
          icon: Icon(
            _ttsEnabled
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            size: 22,
          ),
          tooltip: _ttsEnabled ? 'Mute voice' : 'Enable voice',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'clear') {
              showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Clear Chat'),
                  content: const Text(
                      'This will clear the current chat session. History in Firestore is preserved.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ).then((confirmed) {
                if (confirmed == true && mounted) {
                  setState(() => _messages.clear());
                  _initChat();
                }
              });
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Clear Chat'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisclaimerBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark
          ? AppColors.darkSurfaceVariant.withValues(alpha: 0.5)
          : AppColors.warningLight.withValues(alpha: 0.5),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded,
              color: AppColors.warning, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              AppStrings.disclaimerShort,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMsg message, bool isDark, int index) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : (isDark ? AppColors.darkCardBackground : AppColors.aiBubble),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
          border: !isUser && isDark
              ? Border.all(
                  color: AppColors.darkBorder.withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.smart_toy_rounded,
                      size: 12,
                      color: isDark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'CARE-AI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.primaryLight
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            SelectableText(
              message.text,
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            // TTS button for AI messages
            if (!isUser)
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => _ttsService.speak(message.text),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.volume_up_rounded,
                      size: 16,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(
          begin: isUser ? 0.05 : -0.05,
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : AppColors.aiBubble,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TypingDot(delay: 0.ms),
            const SizedBox(width: 4),
            _TypingDot(delay: 200.ms),
            const SizedBox(width: 4),
            _TypingDot(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedPrompts(bool isDark) {
    const prompts = [
      '💬 How can I help my child with speech?',
      '🧸 Sensory-friendly activities for today',
      '😴 Tips for better sleep routines',
      '🌪️ How to handle meltdowns calmly',
      '📈 What milestones should I watch for?',
      '🎮 Fun games to build motor skills',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Icon(Icons.smart_toy_rounded,
              size: 56,
              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Hi! I\'m your CARE-AI assistant',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ask me anything about your child\'s development',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Try asking:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: prompts.map((prompt) {
              return GestureDetector(
                onTap: () {
                  _messageController.text = prompt;
                  _sendMessage();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    prompt,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    // Mic button for voice input
                    if (_speechAvailable)
                      GestureDetector(
                        onTap: _toggleListening,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            _isListening
                                ? Icons.mic_rounded
                                : Icons.mic_none_rounded,
                            color: _isListening
                                ? AppColors.error
                                : (isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.textTertiary),
                            size: 22,
                          ),
                        ),
                      ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: AppStrings.typeMessage,
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.textTertiary,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: _isTyping
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF5B6EF5), Color(0xFFA855F7)],
                        ),
                  color: _isTyping
                      ? (isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.surfaceVariant)
                      : null,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: _isTyping
                      ? AppColors.textTertiary
                      : Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper Classes ──────────────────────────────────────────

class _ChatMsg {
  final String text;
  final bool isUser;

  const _ChatMsg({required this.text, required this.isUser});
}

class _TypingDot extends StatelessWidget {
  final Duration delay;

  const _TypingDot({required this.delay});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .fadeIn(delay: delay, duration: 300.ms)
        .then()
        .fadeOut(duration: 300.ms)
        .then()
        .fadeIn(duration: 300.ms);
  }
}
