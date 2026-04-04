import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../services/ai_service.dart';
import '../../widgets/brand_logo.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _aiService = AiService();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode(); // Track input focus
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  bool _isFocused = false; // Add focus state

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'assistant',
      'content': "I've prepared a draft notice for the North Gate maintenance. Please review the details below:",
      'isDraft': true,
    });
    
    // Add listener to track focus changes for animation
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose(); // Cleanup
    super.dispose();
  }

  void _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _loading) return;
    _msgCtrl.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _loading = true;
    });
    _scrollToBottom();
    final reply = await _aiService.sendMessage(text);
    if (!mounted) return;
    setState(() {
      _messages.add({'role': 'assistant', 'content': reply});
      _loading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSlateBg,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
              const _BrandingHeader(),
              const _ConciergeHero(),
              const _QuickActionTiles(),
              
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final msg = _messages[index];
                      return _ConciergeBubble(
                        content: msg['content'],
                        isUser: msg['role'] == 'user',
                        isDraft: msg['isDraft'] ?? false,
                      );
                    },
                    childCount: _messages.length,
                  ),
                ),
              ),

              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: _TypingIndicator(),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 240)), 
            ],
          ),

          _FloatingInputConsole(
            controller: _msgCtrl,
            focusNode: _focusNode,
            isFocused: _isFocused,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _BrandingHeader extends StatelessWidget {
  const _BrandingHeader();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 14,
          left: 20,
          right: 20,
          bottom: 12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: kPrimaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SocietyLogo(size: 20, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'The Sero',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1F2937),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B), size: 24),
                const SizedBox(width: 16),
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF1F5F9)),
                  clipBehavior: Clip.antiAlias,
                  child: const Icon(Icons.person_outline_rounded, color: Color(0xFF64748B), size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConciergeHero extends StatelessWidget {
  const _ConciergeHero();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          children: [
            Text(
              'Concierge AI',
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your premium architectural assistant for seamless\nestate administration and resident harmony.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ).animate().fade().slideY(begin: 0.1),
    );
  }
}

class _QuickActionTiles extends StatelessWidget {
  const _QuickActionTiles();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        delegate: SliverChildListDelegate([
          _ActionCard(icon: Icons.campaign_rounded, title: 'Communication', subtitle: 'Draft notices &\nannouncements'),
          _ActionCard(icon: Icons.insert_chart_rounded, title: 'Data Digest', subtitle: 'Analyze resident\ntrends'),
          _ActionCard(icon: Icons.gavel_rounded, title: 'Rule Auditor', subtitle: 'Bylaw compliance\nchecks'),
          _ActionCard(icon: Icons.account_balance_wallet_rounded, title: 'Financials', subtitle: 'Budget & levy\ntracking'),
        ]),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _ActionCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kSlateBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kPrimaryGreen, size: 20),
          ),
          const Spacer(),
          Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8), height: 1.3)),
        ],
      ),
    ).animate().fade().scale(delay: 200.ms);
  }
}

class _ConciergeBubble extends StatelessWidget {
  final String content;
  final bool isUser, isDraft;

  const _ConciergeBubble({required this.content, required this.isUser, this.isDraft = false});

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                color: kPrimaryGreen,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: Text(
                content,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 6),
            Text('14:22 PM', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8))),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy_rounded, size: 16, color: kPrimaryGreen),
              const SizedBox(width: 8),
              Text('CONCIERGE AI', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: kPrimaryGreen)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24), bottomLeft: Radius.circular(24)),
              border: Border.all(color: kSlateBorder.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(content, style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF334155), height: 1.5)),
                if (isDraft) ...[
                  const SizedBox(height: 20),
                  const _DraftCard(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text('14:23 PM', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSlateBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('OFFICIAL DRAFT', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                const Icon(Icons.description_rounded, size: 14, color: Color(0xFF64748B)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IMPORTANT: North Gate Maintenance', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                const SizedBox(height: 12),
                Text(
                  'Dear Residents, please be advised that the North Gate will be undergoing essential scheduled maintenance on Thursday, Oct 24th, from 10:00 AM to 4:00 PM. Access will be redirected through the East Entrance...',
                  style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B), height: 1.6, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.send_rounded, size: 14),
                        label: const Text('Send to All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit_rounded, size: 14),
                        label: const Text('Edit Draft'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          foregroundColor: const Color(0xFF334155),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingInputConsole extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final VoidCallback onSend;

  const _FloatingInputConsole({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 115), 
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 1.0)],
            stops: const [0.0, 0.4],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _SuggestionChip(label: 'Identify non-payers'),
                  _SuggestionChip(label: 'Security status'),
                  _SuggestionChip(label: 'Utility report'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Animated Standalone Plus Button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: isFocused ? 44 : 0,
                  height: 44,
                  margin: EdgeInsets.only(right: isFocused ? 12 : 0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(color: kSlateBorder.withValues(alpha: 0.5)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isFocused ? 1.0 : 0.0,
                    child: Center(
                      child: Icon(Icons.add_rounded, color: kPrimaryGreen, size: 24),
                    ),
                  ),
                ),

                // Main Input Pill
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: kSlateBorder.withValues(alpha: 0.6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Plus icon inside when NOT focused
                        if (!isFocused) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.add_rounded, color: const Color(0xFF64748B), size: 22),
                          const SizedBox(width: 8),
                        ] else ...[
                          const SizedBox(width: 12),
                        ],
                        
                        Expanded(
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onSubmitted: (_) => onSend(),
                            style: GoogleFonts.outfit(fontSize: 15, color: const Color(0xFF1E293B)),
                            decoration: InputDecoration(
                              hintText: 'Ask ChatGPT', // ChatGPT style hint
                              hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 15),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        
                        // Icon Group on Right
                        const Icon(Icons.mic_none_rounded, color: Color(0xFF64748B), size: 22),
                        const SizedBox(width: 8),
                        
                        // Waveform FAB / Send Button
                        GestureDetector(
                          onTap: onSend,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isFocused ? kPrimaryGreen : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFocused ? Icons.arrow_upward_rounded : Icons.graphic_eq_rounded,
                              color: isFocused ? Colors.white : const Color(0xFF64748B),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _SuggestionChip extends StatelessWidget {
  final String label;
  const _SuggestionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.smart_toy_rounded, size: 14, color: Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Text('Typing...', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
      ],
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms);
  }
}

