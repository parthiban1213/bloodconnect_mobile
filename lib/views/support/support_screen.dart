import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';
import '../../utils/app_constants.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  // Attached files
  final List<PlatformFile> _attachments = [];

  bool    _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  // ── File picking ────────────────────────────────────────────
  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'jpg', 'jpeg', 'png', 'gif', 'webp',
          'pdf', 'doc', 'docx', 'txt',
        ],
      );
      if (result == null) return;

      // Deduplicate by name and cap at 5 attachments total
      final existing = _attachments.map((f) => f.name).toSet();
      final fresh = result.files
          .where((f) => !existing.contains(f.name))
          .toList();

      if (_attachments.length + fresh.length > 5) {
        setState(() => _error = AppConfig.supportMaxFilesError);
        return;
      }

      setState(() {
        _attachments.addAll(fresh);
        _error = null;
      });
    } catch (_) {
      setState(() => _error = AppConfig.supportPickerError);
    }
  }

  void _removeAttachment(int index) {
    setState(() => _attachments.removeAt(index));
  }

  // ── Send ────────────────────────────────────────────────────
  Future<void> _send() async {
    final name    = _nameCtrl.text.trim();
    final email   = _emailCtrl.text.trim();
    final subject = _subjectCtrl.text.trim();
    final message = _messageCtrl.text.trim();

    setState(() { _error = null; _success = null; });

    if (name.isEmpty) {
      setState(() => _error = 'Your name is required.'); return;
    }
    if (email.isEmpty || !RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$').hasMatch(email)) {
      setState(() => _error = 'A valid email address is required.'); return;
    }
    if (subject.isEmpty) {
      setState(() => _error = 'Subject is required.'); return;
    }
    if (message.isEmpty) {
      setState(() => _error = 'Message is required.'); return;
    }

    setState(() => _loading = true);

    final String adminEmail = AppConfig.supportAdminEmail;

    // Build attachment note — same pattern as the website
    final attachNote = _attachments.isNotEmpty
        ? '\n\n[Attachments: ${_attachments.map((f) => '"${f.name}"').join(', ')} — please attach these files manually after your mail client opens]'
        : '';

    final body =
        'From: $name <$email>\n\n$message$attachNote${AppConfig.supportEmailBodySuffix}';

    final mailtoUri = Uri(
      scheme: 'mailto',
      path: adminEmail,
      queryParameters: {
        'subject': '${AppConfig.supportEmailSubjectPrefix}$subject',
        'body': body,
      },
    );

    setState(() => _loading = false);

    try {
      final launched = await launchUrl(mailtoUri);
      if (!launched) throw Exception('Could not launch mail client.');

      if (mounted) {
        setState(() {
          _success = _attachments.isNotEmpty
              ? AppConfig.supportSentWithAttachMsg
              : AppConfig.supportSentMsg;
          _nameCtrl.clear();
          _emailCtrl.clear();
          _subjectCtrl.clear();
          _messageCtrl.clear();
          _attachments.clear();
        });
      }
    } catch (_) {
      await Clipboard.setData( ClipboardData(text: adminEmail));
      if (mounted) {
        setState(() =>
            _error = '${AppConfig.supportNoMailApp}$adminEmail');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.chevron_left_rounded,
                        color: AppColors.textPrimary, size: 26),
                  ),
                  Text(
                    AppConfig.supportScreenTitle,
                    style: GoogleFonts.syne(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoBanner(),
                    const SizedBox(height: 20),

                    if (_error != null) ...[
                      _FeedbackPill(msg: _error!, isError: true),
                      const SizedBox(height: 14),
                    ],
                    if (_success != null) ...[
                      _FeedbackPill(msg: _success!, isError: false),
                      const SizedBox(height: 14),
                    ],

                    _SectionLabel(AppConfig.supportNameLabel),
                    const SizedBox(height: 8),
                    _InputField(
                      ctrl: _nameCtrl,
                      hint: AppConfig.supportNameHint,
                      icon: Icons.person_outline_rounded,
                      action: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    _SectionLabel(AppConfig.supportEmailLabel),
                    const SizedBox(height: 8),
                    _InputField(
                      ctrl: _emailCtrl,
                      hint: AppConfig.supportEmailHint,
                      icon: Icons.mail_outline_rounded,
                      keyboard: TextInputType.emailAddress,
                      action: TextInputAction.next,
                      autocorrect: false,
                    ),
                    const SizedBox(height: 16),

                    _SectionLabel(AppConfig.supportSubjectLabel),
                    const SizedBox(height: 8),
                    _InputField(
                      ctrl: _subjectCtrl,
                      hint: AppConfig.supportSubjectHint,
                      icon: Icons.topic_outlined,
                      action: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    _SectionLabel(AppConfig.supportMessageLabel),
                    const SizedBox(height: 8),
                    _MultilineField(
                      ctrl: _messageCtrl,
                      hint: AppConfig.supportMessageHint,
                    ),
                    const SizedBox(height: 16),

                    // ── Attachment section ─────────────────────
                    _AttachmentSection(
                      attachments: _attachments,
                      onPick: _pickFiles,
                      onRemove: _removeAttachment,
                    ),
                    const SizedBox(height: 24),

                    _SendButton(isLoading: _loading, onTap: _loading ? null : _send),
                    const SizedBox(height: 20),

                    // _QuickHelpSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  ATTACHMENT SECTION
// ════════════════════════════════════════════════════════════

class _AttachmentSection extends StatelessWidget {
  final List<PlatformFile> attachments;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;

  const _AttachmentSection({
    required this.attachments,
    required this.onPick,
    required this.onRemove,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _iconFor(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'jpg': case 'jpeg': case 'png': case 'gif': case 'webp':
        return Icons.image_outlined;
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc': case 'docx':
        return Icons.description_outlined;
      default:
        return Icons.attach_file_rounded;
    }
  }

  Color _colorFor(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'jpg': case 'jpeg': case 'png': case 'gif': case 'webp':
        return const Color(0xFF7C3AED);
      case 'pdf':
        return AppColors.primary;
      case 'doc': case 'docx':
        return const Color(0xFF2563EB);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ──────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(AppConfig.supportAttachLabel),
                  const SizedBox(height: 2),
                  Text(
                    AppConfig.supportAttachSubtitle,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (attachments.length < 5)
              GestureDetector(
                onTap: onPick,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.urgentBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.attach_file_rounded,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(AppConfig.supportAttachBtn,
                          style: GoogleFonts.syne(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          )),
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        // ── Empty drop zone ──────────────────────────────────
        if (attachments.isEmpty)
          GestureDetector(
            onTap: onPick,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.cloud_upload_outlined,
                      size: 28, color: AppColors.textMuted),
                  const SizedBox(height: 6),
                  Text(AppConfig.supportAttachDropzone,
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(AppConfig.supportAttachTypes,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textVeryMuted)),
                ],
              ),
            ),
          ),

        // ── File list ────────────────────────────────────────
        if (attachments.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Column(
              children: List.generate(attachments.length, (i) {
                final f     = attachments[i];
                final color = _colorFor(f.extension);
                final isLast = i == attachments.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Icon(_iconFor(f.extension),
                                  color: color, size: 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(f.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary)),
                                Text(_formatSize(f.size),
                                    style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => onRemove(i),
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(Icons.close_rounded,
                                    size: 15, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                          height: 1, thickness: 1,
                          color: AppColors.borderSoft,
                          indent: 14, endIndent: 14),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  INFO BANNER
// ════════════════════════════════════════════════════════════

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.urgentBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.urgentBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10)),
              child: const Center(
                child: Icon(Icons.support_agent_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppConfig.supportInfoTitle,
                      style: GoogleFonts.syne(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.urgentText,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    AppConfig.supportInfoBody,
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.urgentText, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ════════════════════════════════════════════════════════════
//  QUICK HELP
// ════════════════════════════════════════════════════════════

class _QuickHelpSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppConfig.quickHelpTitle,
              style: GoogleFonts.syne(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 10),
          _HelpCard(
            icon: Icons.lock_outline_rounded,
            iconColor: AppColors.primary,
            iconBg: AppColors.urgentBg,
            title: AppConfig.quickHelpLoginTitle,
            body: AppConfig.quickHelpLoginBody,
          ),
          const SizedBox(height: 10),
          _HelpCard(
            icon: Icons.person_add_outlined,
            iconColor: AppColors.secondary,
            iconBg: AppColors.secondaryLight,
            title: AppConfig.quickHelpNewAccTitle,
            body: AppConfig.quickHelpNewAccBody,
          ),
          const SizedBox(height: 10),
          _HelpCard(
            icon: Icons.notifications_none_rounded,
            iconColor: const Color(0xFF7C3AED),
            iconBg: const Color(0xFFF5F0FF),
            title: AppConfig.quickHelpNotifTitle,
            body: AppConfig.quickHelpNotifBody,
          ),
        ],
      );
}

class _HelpCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, body;

  const _HelpCard({
    required this.icon, required this.iconColor,
    required this.iconBg, required this.title, required this.body,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Icon(icon, color: iconColor, size: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.syne(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      )),
                  const SizedBox(height: 4),
                  Text(body,
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      );
}

// ════════════════════════════════════════════════════════════
//  FORM COMPONENTS
// ════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ));
}

class _InputField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType keyboard;
  final TextInputAction action;
  final bool autocorrect;

  const _InputField({
    required this.ctrl, required this.hint, required this.icon,
    this.keyboard = TextInputType.text,
    this.action = TextInputAction.next,
    this.autocorrect = true,
  });

  @override
  Widget build(BuildContext context) => Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(children: [
          const SizedBox(width: 16),
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: keyboard,
              textInputAction: action,
              autocorrect: autocorrect,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.dmSans(
                    fontSize: 14, color: AppColors.textVeryMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true, contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ]),
      );
}

class _MultilineField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  const _MultilineField({required this.ctrl, required this.hint});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSoft),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: TextField(
          controller: ctrl,
          maxLines: 5, minLines: 4,
          textInputAction: TextInputAction.newline,
          style: GoogleFonts.dmSans(
              fontSize: 14, color: AppColors.textPrimary, height: 1.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
                fontSize: 14, color: AppColors.textVeryMuted),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true, contentPadding: EdgeInsets.zero,
          ),
        ),
      );
}

class _SendButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  const _SendButton({required this.onTap, required this.isLoading});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity, height: 52,
        child: Material(
          color: isLoading || onTap == null
              ? AppColors.primary.withOpacity(0.7)
              : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.send_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(AppConfig.supportSendBtn,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          )),
                    ]),
            ),
          ),
        ),
      );
}

// ════════════════════════════════════════════════════════════
//  FEEDBACK PILLS
// ════════════════════════════════════════════════════════════

class _FeedbackPill extends StatelessWidget {
  final String msg;
  final bool isError;
  const _FeedbackPill({required this.msg, required this.isError});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isError ? AppColors.urgentBg : const Color(0xFFEDFBF3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isError
                ? AppColors.urgentBorder
                : const Color(0xFFBBF7D0),
          ),
        ),
        child: Row(children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 15,
            color: isError
                ? AppColors.urgentText
                : const Color(0xFF15803D),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(msg,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: isError
                        ? AppColors.urgentText
                        : const Color(0xFF15803D),
                    height: 1.4,
                  ))),
        ]),
      );
}
