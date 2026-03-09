import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:chewie/chewie.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../services/ai_service.dart';
import '../../../services/firebase_service.dart';
import '../../../services/tts_service.dart';
import '../../../services/context_builder_service.dart';
import '../../../models/chat_message_model.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'widgets/media_picker_bottom_sheet.dart';

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

  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedMedia;
  MediaSourceType? _selectedMediaType;
  Uint8List? _videoThumbnailBytes;

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

  Future<void> _pickMedia(MediaSourceType type) async {
    try {
      XFile? file;
      if (type == MediaSourceType.camera) {
        file = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 70);
      } else if (type == MediaSourceType.gallery) {
        file = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      } else if (type == MediaSourceType.video) {
        file = await _imagePicker.pickVideo(source: ImageSource.gallery);
      }

      if (file != null && mounted) {
        Uint8List? thumbnailBytes;
        if (type == MediaSourceType.video) {
          thumbnailBytes = await VideoThumbnail.thumbnailData(
            video: file.path,
            imageFormat: ImageFormat.JPEG,
            quality: 70,
            maxWidth: 150,
          );
        }

        setState(() {
          _selectedMedia = file;
          _selectedMediaType = type;
          _videoThumbnailBytes = thumbnailBytes;
        });
      }
    } catch (e) {
      debugPrint('Failed to pick media: \$e');
    }
  }

  Future<List<Uint8List>> _extractKeyFrames(String videoPath, {int count = 4}) async {
    final List<Uint8List> frames = [];
    final VideoPlayerController controller = VideoPlayerController.file(File(videoPath));
    await controller.initialize();
    final durationMs = controller.value.duration.inMilliseconds;
    await controller.dispose();

    final interval = durationMs ~/ (count + 1);
    for (int i = 1; i <= count; i++) {
      final timeMs = interval * i;
      final uint8list = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        timeMs: timeMs,
        quality: 60,
        maxWidth: 512,
      );
      if (uint8list != null) {
        frames.add(uint8list);
      }
    }
    return frames;
  }

  Future<void> _initChat() async {
    // Capture reference before async gap
    final aiService = context.read<AiService>();
    final profile = await _firebaseService.getChildProfile();
    
    // Build full holistic context
    final userId = _firebaseService.currentUser?.uid;
    String fullContext = "";
    if (userId != null) {
      final contextService = ContextBuilderService(_firebaseService);
      fullContext = await contextService.buildFullContext(
        userId: userId,
        childProfile: profile,
      );
    }
    
    aiService.startChatSession(childProfile: profile, fullContext: fullContext);

    // Load chat history from Firestore (last 50)
    try {
      final stream = _firebaseService.getChatMessages();
      final messages = await stream.first;
      if (messages.isNotEmpty && mounted) {
        final historyMsgs =
            messages.take(50).map((msg) {
              return _ChatMsg(text: msg.message, isUser: msg.sender == 'user', imagePath: msg.imagePath);
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
      _messages.add(const _ChatMsg(text: AppStrings.chatWelcome, isUser: false));
      if (mounted) setState(() {});
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedMedia == null || _isTyping) return;

    final String messageText = text.isEmpty ? "Sent an attached media object." : text;

    // Capture AI service reference before async gap
    final aiService = context.read<AiService>();

    List<Uint8List>? imageBytesList;
    String? imagePath;
    Uint8List? videoThumbnail = _videoThumbnailBytes;
    bool isVideo = _selectedMediaType == MediaSourceType.video;

    if (_selectedMedia != null) {
      if (_selectedMediaType == MediaSourceType.camera || _selectedMediaType == MediaSourceType.gallery) {
        imageBytesList = [await _selectedMedia!.readAsBytes()];
        imagePath = _selectedMedia!.path;
      } else if (_selectedMediaType == MediaSourceType.video) {
        imagePath = _selectedMedia!.path;
        setState(() => _isTyping = true); // Start typing to show "Processing video..."
        imageBytesList = await _extractKeyFrames(_selectedMedia!.path, count: 4);
      }
    }

    // Add user message
    setState(() {
      _messages.add(_ChatMsg(text: messageText, isUser: true, imagePath: imagePath, videoThumbnail: videoThumbnail, isVideo: isVideo));
      _isTyping = true;
      _selectedMedia = null;
      _selectedMediaType = null;
      _videoThumbnailBytes = null;
    });
    _messageController.clear();
    _scrollToBottom();

    // Save user message to Firestore
    await _firebaseService.sendChatMessage(
      ChatMessageModel(
        id: '',
        message: messageText,
        sender: 'user',
        timestamp: DateTime.now(),
        imagePath: imagePath,
      ),
    );

    // Get AI response stream
    try {
      int aiMsgIndex = _messages.length;
      setState(() {
        _messages.add(const _ChatMsg(text: '', isUser: false));
      });

      final stream = aiService.getStreamingResponse(
        isVideo ? "These are key frames from a video. Describe what is happening and provide insights.\n\$messageText" : messageText, 
        imageBytesList: imageBytesList,
      );
      String fullResponse = '';

      await for (final chunk in stream) {
        if (!mounted) return;

        // Catch the function call JSON injected by AiService
        if (chunk.startsWith('{"__is_function_call__":true')) {
          try {
            final data = jsonDecode(chunk);
            if (data['name'] == 'perform_app_action') {
              final args = data['args'];
              final target = args['target'];
              final message = args['message'] ?? "I'm taking you there now!";
              
              fullResponse += message;
              
              setState(() {
                _messages[aiMsgIndex] = _ChatMsg(text: fullResponse, isUser: false);
                _isTyping = false;
              });
              
              String routeName = '/home';
              switch (target) {
                case 'home': routeName = '/home'; break;
                case 'dashboard': routeName = '/doctor-dashboard'; break;
                case 'wellness': routeName = '/wellness'; break;
                case 'daily_plan': routeName = '/daily-plan'; break;
                case 'games': routeName = '/games'; break;
                case 'emergency': routeName = '/emergency'; break;
                case 'settings': routeName = '/settings'; break;
                case 'progress': routeName = '/progress'; break;
                case 'community': routeName = '/community'; break;
                case 'activities': routeName = '/activities'; break;
              }
              
              // Navigate after a short delay so user sees AI message
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) Navigator.pushNamed(context, routeName);
              });
            }
          } catch (_) {}
          continue;
        }

        fullResponse += chunk;

        setState(() {
          _messages[aiMsgIndex] = _ChatMsg(text: fullResponse, isUser: false);
          _isTyping = false; // Turn off typing indicator once data arrives
        });
        _scrollToBottom();
      }

      // Save AI response to Firestore
      await _firebaseService.sendChatMessage(
        ChatMessageModel(
          id: '',
          message: fullResponse,
          sender: 'ai',
          timestamp: DateTime.now(),
        ),
      );

      // Speak response if TTS is enabled
      if (_ttsEnabled) {
        _ttsService.speak(fullResponse);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeLast(); // Remove empty or partial AI message
        _isTyping = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Failed to generate response. Please check your connection.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Retry Text',
            textColor: Colors.white,
            onPressed: () {
              _messageController.text = messageText;
            },
          ),
        ),
      );
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
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          // Disclaimer banner
          _buildDisclaimerBanner(isDark),

          // Messages area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0) + (_messages.length == 1 && !_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator(isDark);
                }
                if (index == _messages.length && _messages.length == 1 && !_isTyping) {
                  return _buildSuggestedPrompts(isDark);
                }
                return _buildMessageBubble(
                  _messages[index],
                  isDark,
                  index,
                );
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
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      title: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                AppStrings.chatTitle,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Online',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/voice-assistant'),
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic_rounded, size: 18, color: AppColors.primary),
          ),
          tooltip: 'Voice Assistant',
        ),
        IconButton(
          onPressed: () {
            setState(() => _ttsEnabled = !_ttsEnabled);
            if (!_ttsEnabled) _ttsService.stop();
          },
          icon: Icon(
            _ttsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            size: 22,
            color: _ttsEnabled ? AppColors.primary : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
          ),
          tooltip: _ttsEnabled ? 'Mute voice' : 'Enable voice',
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          onSelected: (value) {
            if (value == 'clear') {
              showDialog<bool>(
                context: context,
                builder:
                    (_) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Clear Chat', style: TextStyle(fontWeight: FontWeight.w700)),
                      content: const Text(
                        'This will clear the current chat session.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
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
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Clear Chat', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildDisclaimerBanner(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.darkSurfaceVariant.withValues(alpha: 0.5) 
            : AppColors.warningLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder.withValues(alpha: 0.3) : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, color: AppColors.warning, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.disclaimerShort,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
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
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: isUser
                  ? const LinearGradient(
                      colors: [AppColors.primary, AppColors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isUser
                  ? null
                  : (isDark ? AppColors.darkCardBackground : AppColors.cardBackground),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 20),
              ),
              boxShadow: isDark ? [] : [
                if (!isUser)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                if (isUser)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
              border: !isUser && isDark
                  ? Border.all(color: AppColors.darkBorder.withValues(alpha: 0.5))
                  : (!isUser && !isDark 
                      ? Border.all(color: AppColors.divider.withValues(alpha: 0.5)) 
                      : null),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.smart_toy_rounded,
                          size: 14,
                          color: isDark ? AppColors.primaryLight : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'CARE-AI',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isDark ? AppColors.primaryLight : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (message.imagePath != null)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => message.isVideo 
                              ? FullScreenVideoPlayer(videoPath: message.imagePath!)
                              : FullScreenImageView(imagePath: message.imagePath!),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Hero(
                        tag: message.imagePath!,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: message.isVideo 
                              ? Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (message.videoThumbnail != null)
                                      Image.memory(
                                        message.videoThumbnail!,
                                        width: MediaQuery.of(context).size.width * 0.65,
                                        fit: BoxFit.cover,
                                      )
                                    else
                                      Container(
                                        width: MediaQuery.of(context).size.width * 0.65,
                                        height: 150,
                                        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                                      ),
                                    const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 48),
                                  ],
                                )
                              : Image.file(
                                  File(message.imagePath!),
                                  width: MediaQuery.of(context).size.width * 0.65,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                  ),
                MarkdownBody(
                  data: message.text,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: isUser
                          ? Colors.white
                          : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                    strong: TextStyle(
                      color: isUser
                          ? Colors.white
                          : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                      fontWeight: FontWeight.w700,
                    ),
                    listBullet: TextStyle(
                      color: isUser
                          ? Colors.white
                          : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                    ),
                  ),
                ),
                // TTS button for AI messages
                if (!isUser)
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => _ttsService.speak(message.text),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Icon(
                          Icons.volume_up_rounded,
                          size: 18,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideX(
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

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDivider.withValues(alpha: 0.3) : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedMedia != null) _buildMediaPreview(isDark),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : AppColors.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, -2),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
            border: Border.all(
              color: isDark 
                  ? AppColors.darkDivider.withValues(alpha: 0.5) 
                  : AppColors.border.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  MediaPickerBottomSheet.show(context, onSelected: (type) {
                    _pickMedia(type);
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: Icon(
                    Icons.add_photo_alternate_rounded,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                    size: 24,
                  ),
                ),
              ),
              if (_speechAvailable)
                GestureDetector(
                  onTap: _toggleListening,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isListening 
                          ? AppColors.error.withValues(alpha: 0.1) 
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening 
                          ? AppColors.error 
                          : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                      size: 22,
                    ),
                  ),
                )
              else 
                const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: AppStrings.typeMessage,
                    hintStyle: TextStyle(
                      color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: _isTyping
                        ? null 
                        : const LinearGradient(
                            colors: [AppColors.primary, AppColors.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: _isTyping
                        ? (isDark ? AppColors.darkBackground : AppColors.surfaceVariant)
                        : null,
                    shape: BoxShape.circle,
                    boxShadow: _isTyping || isDark ? [] : [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: _isTyping
                        ? (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary) 
                        : Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 2),
            ],
          ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: _selectedMediaType == MediaSourceType.video 
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_videoThumbnailBytes != null)
                          Image.memory(
                            _videoThumbnailBytes!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        else
                          Container(
                            color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                          ),
                        const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 28),
                      ],
                    ) 
                  : Image.file(
                      File(_selectedMedia!.path),
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMedia = null;
                  _selectedMediaType = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? AppColors.darkBackground : AppColors.background, width: 2),
                ),
                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedPrompts(bool isDark) {
    final prompts = [
      "Tell me a bedtime story",
      "How do I manage a meltdown?",
      "Fun indoor activities",
      "Open the daily plan",
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Try asking about:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: prompts.map((prompt) {
              return ActionChip(
                label: Text(prompt, style: const TextStyle(fontSize: 13)),
                backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                labelStyle: TextStyle(
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.divider,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onPressed: () {
                  _messageController.text = prompt;
                  _sendMessage();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Classes ──────────────────────────────────────────

class _ChatMsg {
  final String text;
  final bool isUser;
  final String? imagePath;
  final Uint8List? videoThumbnail;
  final bool isVideo;

  const _ChatMsg({required this.text, required this.isUser, this.imagePath, this.videoThumbnail, this.isVideo = false});
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


class FullScreenImageView extends StatelessWidget {
  final String imagePath;
  const FullScreenImageView({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: imagePath,
          child: Image.file(File(imagePath)),
        ),
      ),
    );
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoPath;
  const FullScreenVideoPlayer({super.key, required this.videoPath});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.file(File(widget.videoPath));
    await _videoPlayerController.initialize();
    
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
    );
    setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
            ? Chewie(controller: _chewieController!)
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

