import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/blood_requirement.dart';
import '../../services/requirements_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_extensions.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';

class AddRequirementScreen extends ConsumerStatefulWidget {
  final BloodRequirement? existing;
  const AddRequirementScreen({super.key, this.existing});

  @override
  ConsumerState<AddRequirementScreen> createState() =>
      _AddRequirementScreenState();
}

class _AddRequirementScreenState extends ConsumerState<AddRequirementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = RequirementsService();

  final _patientNameCtrl   = TextEditingController();
  final _hospitalCtrl      = TextEditingController();
  final _locationCtrl      = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _contactPhoneCtrl  = TextEditingController();
  final _notesCtrl         = TextEditingController();

  final _patientFocus   = FocusNode();
  final _hospitalFocus  = FocusNode();
  final _locationFocus  = FocusNode();
  final _contactPFocus  = FocusNode();
  final _contactPhFocus = FocusNode();
  final _notesFocus     = FocusNode();

  String    _bloodType = '';
  String    _urgency   = 'Medium';
  String    _status    = 'Open';
  int       _units     = 1;
  DateTime? _requiredBy;

  bool    _saving    = false;
  String? _saveError;

  bool get _isEditing => widget.existing != null;

  static const _urgencyColors = {
    'Critical': Color(0xFFC8102E),
    'High':     Color(0xFFE85D2F),
    'Medium':   Color(0xFFF5A623),
    'Low':      Color(0xFF1D9E75),
  };

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _patientNameCtrl.text   = e.patientName;
      _hospitalCtrl.text      = e.hospital;
      _locationCtrl.text      = e.location;
      _contactPersonCtrl.text = e.contactPerson;
      _contactPhoneCtrl.text  = e.contactPhone;
      _notesCtrl.text         = e.notes;
      _bloodType  = e.bloodType;
      _urgency    = e.urgency;
      _status     = e.status;
      _units      = e.unitsRequired;
      _requiredBy = e.requiredBy;
    }
  }

  @override
  void dispose() {
    _patientNameCtrl.dispose();
    _hospitalCtrl.dispose();
    _locationCtrl.dispose();
    _contactPersonCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _notesCtrl.dispose();
    _patientFocus.dispose();
    _hospitalFocus.dispose();
    _locationFocus.dispose();
    _contactPFocus.dispose();
    _contactPhFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    context.dismissKeyboard();
    final picked = await showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => _CompactDatePicker(
        initial: _requiredBy ?? DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      ),
    );
    if (picked != null) setState(() => _requiredBy = picked);
  }

  Future<void> _save() async {
    context.dismissKeyboard();
    if (!_formKey.currentState!.validate()) return;
    if (_bloodType.isEmpty) {
      setState(() => _saveError = 'Please select a blood type.');
      return;
    }
    setState(() { _saving = true; _saveError = null; });
    try {
      final body = {
        'patientName':   _patientNameCtrl.text.trim(),
        'hospital':      _hospitalCtrl.text.trim(),
        'location':      _locationCtrl.text.trim(),
        'contactPerson': _contactPersonCtrl.text.trim(),
        'contactPhone':  _contactPhoneCtrl.text.trim(),
        'bloodType':     _bloodType,
        'unitsRequired': _units,
        'urgency':       _urgency,
        'status':        'Open',
        'notes':         _notesCtrl.text.trim(),
        if (_requiredBy != null) 'requiredBy': _requiredBy!.toIso8601String(),
        if (!_isEditing)         'remainingUnits': _units,
      };
      if (_isEditing) {
        await _service.updateRequirement(widget.existing!.id, body);
      } else {
        await _service.createRequirement(body);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            _isEditing ? AppConfig.addReqUpdatedMsg : AppConfig.addReqCreatedMsg,
            style: GoogleFonts.dmSans(fontSize: 13),
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        context.pop();
      }
    } catch (e) {
      setState(() {
        _saving    = false;
        _saveError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary, size: 22),
        ),
        title: Text(
          _isEditing ? AppConfig.addReqTitleEdit : AppConfig.addReqTitleNew,
          style: GoogleFonts.syne(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: Column(
              children: [

                // ── Error banner ──────────────────────────────
                if (_saveError != null) ...[
                  _ErrorBanner(message: _saveError!),
                  const SizedBox(height: 8),
                ],

                // ── PATIENT card ──────────────────────────────
                _SectionCard(
                  icon: Icons.person_outline_rounded,
                  label: 'Patient',
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(child: _CompactField(
                          hint: 'Patient name *',
                          controller: _patientNameCtrl,
                          focusNode: _patientFocus,
                          nextFocus: _hospitalFocus,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required' : null,
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: _CompactField(
                          hint: 'Hospital *',
                          controller: _hospitalCtrl,
                          focusNode: _hospitalFocus,
                          nextFocus: _locationFocus,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required' : null,
                        )),
                      ]),
                      const SizedBox(height: 7),
                      _CompactField(
                        hint: 'Location (optional)',
                        controller: _locationCtrl,
                        focusNode: _locationFocus,
                        nextFocus: _contactPFocus,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // ── CONTACT card ──────────────────────────────
                _SectionCard(
                  icon: Icons.phone_outlined,
                  label: 'Contact',
                  child: Row(children: [
                    Expanded(child: _CompactField(
                      hint: 'Contact person *',
                      controller: _contactPersonCtrl,
                      focusNode: _contactPFocus,
                      nextFocus: _contactPhFocus,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Required' : null,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _CompactField(
                      hint: 'Phone *',
                      controller: _contactPhoneCtrl,
                      focusNode: _contactPhFocus,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 10) return 'Too short';
                        return null;
                      },
                    )),
                  ]),
                ),

                const SizedBox(height: 6),

                // ── BLOOD DETAILS card ────────────────────────
                _SectionCard(
                  icon: Icons.bloodtype_outlined,
                  label: 'Blood details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Blood type grid 4x2
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 2.4,
                        ),
                        itemCount: AppConstants.bloodTypes.length,
                        itemBuilder: (_, i) {
                          final t = AppConstants.bloodTypes[i];
                          final sel = t == _bloodType;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _bloodType = t;
                              _saveError = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: sel
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(t,
                                  style: GoogleFonts.syne(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: sel
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  )),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 8),

                      // Units stepper + Urgency chips
                      Row(children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(children: [
                              GestureDetector(
                                onTap: () {
                                  if (_units > 1) setState(() => _units--);
                                },
                                child: Container(
                                  width: 26, height: 26,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(Icons.remove_rounded,
                                      size: 14,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                              Expanded(child: Column(children: [
                                Text('$_units',
                                    style: GoogleFonts.syne(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                    textAlign: TextAlign.center),
                                Text('unit${_units != 1 ? 's' : ''}',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 9,
                                        color: AppColors.textMuted),
                                    textAlign: TextAlign.center),
                              ])),
                              GestureDetector(
                                onTap: () => setState(() => _units++),
                                child: Container(
                                  width: 26, height: 26,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: const Icon(Icons.add_rounded,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ]),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          flex: 2,
                          child: Row(
                            children: AppConstants.urgencyLevels.map((u) {
                              final sel = u == _urgency;
                              final color = _urgencyColors[u]!;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: u == AppConstants.urgencyLevels.last
                                        ? 0 : 5,
                                  ),
                                  child: GestureDetector(
                                    onTap: () => setState(() => _urgency = u),
                                    child: AnimatedContainer(
                                      duration:
                                      const Duration(milliseconds: 140),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 9),
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? color.withOpacity(0.12)
                                            : AppColors.background,
                                        borderRadius:
                                        BorderRadius.circular(8),
                                        border: Border.all(
                                          color: sel
                                              ? color
                                              : AppColors.border,
                                          width: sel ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Text(
                                        u[0],
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.syne(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: sel
                                              ? color
                                              : AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ]),

                      const SizedBox(height: 8),

                      // Required by + Notes
                      Row(children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 9),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: 13,
                                    color: _requiredBy != null
                                        ? AppColors.primary
                                        : AppColors.textMuted),
                                const SizedBox(width: 6),
                                Expanded(child: Text(
                                  _requiredBy != null
                                      ? DateFormat('d MMM yy')
                                      .format(_requiredBy!)
                                      : 'Required by',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: _requiredBy != null
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                )),
                                if (_requiredBy != null)
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _requiredBy = null),
                                    child: const Icon(Icons.close_rounded,
                                        size: 12,
                                        color: AppColors.textMuted),
                                  ),
                              ]),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: TextFormField(
                            controller: _notesCtrl,
                            focusNode: _notesFocus,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _notesFocus.unfocus(),
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Notes (optional)',
                              hintStyle: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: AppColors.textMuted),
                              filled: true,
                              fillColor: AppColors.background,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ]),

                      // Status dropdown (edit only)
                      if (_isEditing) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _status,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            labelStyle: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.background,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                              const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                              const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 1.5),
                            ),
                          ),
                          style: GoogleFonts.dmSans(
                              fontSize: 12, color: AppColors.textPrimary),
                          dropdownColor: AppColors.surface,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 18, color: AppColors.textMuted),
                          items: AppConstants.requirementStatuses
                              .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _status = v ?? 'Open'),
                        ),
                      ],
                    ],
                  ),
                ),


                // ── Save button ───────────────────────────────
                GestureDetector(
                  onTap: _saving ? null : _save,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _saving
                          ? AppColors.primary.withOpacity(0.55)
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isEditing
                                ? Icons.check_rounded
                                : Icons.add_rounded,
                            color: Colors.white, size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppConfig.addReqSaveBtn,
                            style: GoogleFonts.syne(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),           // Column
          ),             // SingleChildScrollView
        ),               // Form
      ),                 // SafeArea
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SHARED COMPONENTS
// ════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppColors.borderSoft)),
            ),
            child: Row(children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 12, color: AppColors.primary),
              ),
              const SizedBox(width: 7),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.syne(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _CompactField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _CompactField({
    required this.hint,
    required this.controller,
    required this.focusNode,
    this.nextFocus,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      textInputAction:
      nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          focusNode.unfocus();
        }
      },
      style: GoogleFonts.dmSans(
          fontSize: 12, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
        GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.background,
        isDense: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorStyle:
        GoogleFonts.dmSans(fontSize: 10, color: AppColors.primary),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  COMPACT DATE PICKER
// ════════════════════════════════════════════════════════════

class _CompactDatePicker extends StatefulWidget {
  final DateTime initial;
  final DateTime firstDate;
  final DateTime lastDate;

  const _CompactDatePicker({
    required this.initial,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_CompactDatePicker> createState() => _CompactDatePickerState();
}

class _CompactDatePickerState extends State<_CompactDatePicker> {
  late DateTime _cursor;   // month being displayed
  late DateTime _selected;

  static const _weekLabels = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    _cursor   = DateTime(widget.initial.year, widget.initial.month);
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_cursor.year, _cursor.month + delta);
    final minMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    final maxMonth = DateTime(widget.lastDate.year,  widget.lastDate.month);
    if (next.isBefore(minMonth) || next.isAfter(maxMonth)) return;
    setState(() => _cursor = next);
  }

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(_cursor.year, _cursor.month, 1);
    final daysInMonth  = DateTime(_cursor.year, _cursor.month + 1, 0).day;
    final startOffset  = firstOfMonth.weekday % 7; // Sun=0
    final totalCells   = startOffset + daysInMonth;

    final minMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    final maxMonth = DateTime(widget.lastDate.year,  widget.lastDate.month);
    final canGoBack = _cursor.isAfter(minMonth);
    final canGoFwd  = _cursor.isBefore(maxMonth);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── month navigation ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                _NavBtn(
                  icon: Icons.chevron_left_rounded,
                  enabled: canGoBack,
                  onTap: () => _shiftMonth(-1),
                ),
                Expanded(
                  child: Text(
                    '${_monthName(_cursor.month)} ${_cursor.year}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.syne(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _NavBtn(
                  icon: Icons.chevron_right_rounded,
                  enabled: canGoFwd,
                  onTap: () => _shiftMonth(1),
                ),
              ]),
            ),

            // ── weekday labels ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: _weekLabels.map((d) => Expanded(
                  child: Text(d,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                )).toList(),
              ),
            ),

            const SizedBox(height: 4),

            // ── day grid ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                  childAspectRatio: 1.15,
                ),
                itemCount: totalCells,
                itemBuilder: (_, idx) {
                  if (idx < startOffset) return const SizedBox.shrink();
                  final day  = idx - startOffset + 1;
                  final date = DateTime(_cursor.year, _cursor.month, day);
                  final isSel = date.year  == _selected.year  &&
                      date.month == _selected.month &&
                      date.day   == _selected.day;
                  final isToday = date.year  == DateTime.now().year  &&
                      date.month == DateTime.now().month &&
                      date.day   == DateTime.now().day;
                  final enabled = !date.isBefore(
                      DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day)) &&
                      !date.isAfter(
                          DateTime(widget.lastDate.year,  widget.lastDate.month,  widget.lastDate.day));

                  return GestureDetector(
                    onTap: enabled ? () => setState(() => _selected = date) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.primary
                            : isToday
                            ? AppColors.primaryLight
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                          color: isSel
                              ? Colors.white
                              : !enabled
                              ? AppColors.textMuted.withOpacity(0.4)
                              : isToday
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── action row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: Text('Cancel',
                        style: GoogleFonts.syne(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(_selected),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text('Confirm',
                        style: GoogleFonts.syne(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),   // Column
      ),     // Container
    );       // Dialog
  }

  static String _monthName(int m) => const [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ][m];
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon,
          size: 18,
          color: enabled ? AppColors.textPrimary : AppColors.textMuted.withOpacity(0.3),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.urgentBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.urgentBorder),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: AppColors.primary, size: 14),
        const SizedBox(width: 7),
        Expanded(
          child: Text(message,
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: AppColors.urgentText)),
        ),
      ]),
    );
  }
}