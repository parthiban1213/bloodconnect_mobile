import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';

// ─────────────────────────────────────────────────────────────
//  HowItWorksScreen
//  Full-screen 5-slide carousel explaining the donation flow.
//  All strings sourced from AppConfig.
// ─────────────────────────────────────────────────────────────

class HowItWorksScreen extends StatefulWidget {
  const HowItWorksScreen({super.key});

  @override
  State<HowItWorksScreen> createState() => _HowItWorksScreenState();
}

class _HowItWorksScreenState extends State<HowItWorksScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 5;

  // Per-slide accent/tip colours — ordered to match hiwSlides
  static const List<Color> _accentColors = [
    AppColors.primary, AppColors.plannedText, AppColors.moderateAccent,
    AppColors.secondary, AppColors.closedText,
  ];
  static const List<Color> _tipBgColors = [
    AppColors.urgentBg, AppColors.plannedBg, AppColors.moderateBg,
    AppColors.secondaryLight, AppColors.closedBg,
  ];
  static const List<Color> _tipBorderColors = [
    AppColors.urgentBorder, AppColors.plannedBorder, AppColors.moderateBorder,
    Color(0xFF9FE1CB), AppColors.closedBorder,
  ];
  static const List<Color> _tipTitleColors = [
    AppColors.urgentText, AppColors.plannedText, AppColors.moderateText,
    Color(0xFF085041), AppColors.closedText,
  ];

  List<_SlideData> get _slides => AppConfig.hiwSlides.asMap().entries.map((e) {
    final i = e.key;
    final s = e.value;
    return _SlideData(
      step: s['step']!, title: s['title']!, description: s['desc']!,
      imagePath: s['image']!,
      accentColor: _accentColors[i], tipColor: _tipBgColors[i],
      tipBorderColor: _tipBorderColors[i], tipTitleColor: _tipTitleColors[i],
      tipTitle: s['tipTitle']!, tipBody: s['tipBody']!,
    );
  }).toList();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page, duration: const Duration(milliseconds: 320), curve: Curves.easeInOut,
    );
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _goToPage(_currentPage + 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prev() {
    if (_currentPage > 0) _goToPage(_currentPage - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            _buildProgressDots(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _totalPages,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) => _SlideView(data: _slides[index]),
              ),
            ),
            _buildNavRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 52, color: AppColors.navBg,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered title
          Text(AppConfig.hiwScreenTitle,
            style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          // Back button pinned left
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.chevron_left_rounded,
                    color: AppColors.navInactive, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDots() {
    return Container(
      color: AppColors.navBg,
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalPages, (i) {
          final isActive = i == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 28 : 8, height: 4,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.navInactive.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavRow() {
    final isLast = _currentPage == _totalPages - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _currentPage > 0 ? _prev : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _currentPage > 0 ? 1.0 : 0.35,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(AppConfig.hiwPrevBtn,
                      style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _next,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: isLast ? AppColors.secondary : AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(isLast ? AppConfig.hiwDoneBtn : AppConfig.hiwNextBtn,
                    style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Slide data model
// ─────────────────────────────────────────────────────────────

class _SlideData {
  final String step, title, description, imagePath, tipTitle, tipBody;
  final Color accentColor, tipColor, tipBorderColor, tipTitleColor;

  const _SlideData({
    required this.step, required this.title, required this.description,
    required this.imagePath, required this.accentColor, required this.tipColor,
    required this.tipBorderColor, required this.tipTitleColor,
    required this.tipTitle, required this.tipBody,
  });
}

// ─────────────────────────────────────────────────────────────
//  Single slide widget
// ─────────────────────────────────────────────────────────────

class _SlideView extends StatelessWidget {
  final _SlideData data;
  const _SlideView({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.urgentBg,
              border: Border.all(color: AppColors.urgentBorder),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(data.step,
              style: GoogleFonts.syne(fontSize: 9, fontWeight: FontWeight.w700,
                  color: AppColors.urgentText, letterSpacing: 0.8)),
          ),
          const SizedBox(height: 10),
          Text(data.title,
            style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary, height: 1.2)),
          const SizedBox(height: 6),
          Text(data.description,
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 14),
          // Screenshot image — expands to fill available space
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset(
                  data.imagePath, fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.background3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, size: 40,
                            color: AppColors.textMuted.withOpacity(0.4)),
                        const SizedBox(height: 8),
                        Text(AppConfig.hiwImagePlaceholder,
                          style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Tip card — fixed at bottom
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: data.tipColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: data.tipBorderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: data.tipTitleColor),
                  const SizedBox(width: 5),
                  Text(data.tipTitle,
                    style: GoogleFonts.syne(fontSize: 11, fontWeight: FontWeight.w700,
                        color: data.tipTitleColor)),
                ]),
                const SizedBox(height: 4),
                Text(data.tipBody,
                  style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
