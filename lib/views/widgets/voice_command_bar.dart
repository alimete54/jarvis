import 'package:flutter/material.dart';
import '../../config/theme.dart';

class VoiceCommandBar extends StatefulWidget {
  final Function(String) onCommand;
  final bool isProcessing;

  const VoiceCommandBar({
    super.key,
    required this.onCommand,
    this.isProcessing = false,
  });

  @override
  State<VoiceCommandBar> createState() => _VoiceCommandBarState();
}

class _VoiceCommandBarState extends State<VoiceCommandBar> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _pulseController;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _submitCommand() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onCommand(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: JARVISTheme.surface.withOpacity(0.95),
        border: Border(top: BorderSide(color: JARVISTheme.primary.withOpacity(0.15))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() => _isListening = !_isListening);
                if (_isListening) {
                  _pulseController.repeat(reverse: true);
                } else {
                  _pulseController.stop();
                  _pulseController.reset();
                }
              },
              child: AnimatedBuilder(
                listenable: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? JARVISTheme.danger.withOpacity(0.15 + _pulseController.value * 0.15)
                          : JARVISTheme.surfaceLight,
                      border: Border.all(
                        color: _isListening
                            ? JARVISTheme.danger.withOpacity(0.5 + _pulseController.value * 0.3)
                            : JARVISTheme.primary.withOpacity(0.2),
                        width: _isListening ? 1.5 : 1,
                      ),
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? JARVISTheme.danger : JARVISTheme.textSecondary,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !widget.isProcessing,
                style: const TextStyle(color: JARVISTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.isProcessing ? 'İşleniyor...' : 'J.A.R.V.I.S.\'e bir şey söyleyin...',
                  hintStyle: TextStyle(
                    color: widget.isProcessing ? JARVISTheme.primary.withOpacity(0.5) : JARVISTheme.textSecondary,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _submitCommand(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.isProcessing ? null : _submitCommand,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isProcessing ? JARVISTheme.surfaceLight : JARVISTheme.primary.withOpacity(0.15),
                ),
                child: Icon(
                  widget.isProcessing ? Icons.hourglass_top : Icons.arrow_upward,
                  color: widget.isProcessing ? JARVISTheme.textSecondary : JARVISTheme.primary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
