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

  // Controllers
  final _patientNameCtrl   = TextEditingController();
  final _hospitalCtrl      = TextEditingController();
  final _locationCtrl      = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _contactPhoneCtrl  = TextEditingController();
  final _notesCtrl         = TextEditingController();

  // FocusNodes for keyboard Next chain
  final _patientFocus   = FocusNode();
  final _hospitalFocus  = FocusNode();
  final _locationFocus  = FocusNode();
  final _contactPFocus  = FocusNode();
  final _contactPhFocus = FocusNode();
  final _notesFocus     = FocusNode();

  // Values
  String    _bloodType = '';
  String    _urgency   = 'Medium';
  String    _status    = 'Open';
  int       _units     = 1;
  DateTime? _requiredBy;

  bool    _saving    = false;
  String? _saveError;

  bool get _isEditing => widget.existing != null;

  // Urgency config
  static const _urgencyColors = {
    'Critical': Color(0xFFC8102E),
    'High':     Color(0xFFE85D2F),
    'Medium':   Color(0xFFF5A623),
    'Low':      Color(0xFF1D9E75),
  };
  static const _urgencyIcons = {
    'Critical': Icons.local_fire_department_rounded,
    'High':     Icons.arrow_upward_rounded,
    'Medium':   Icons.remove_rounded,
    'Low':      Icons.arrow_downward_rounded,
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _requiredBy ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
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
            fontSize: 17, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [

              // ── Error banner ────────────────────────────
              if (_saveError != null) ...[
                _ErrorBanner(message: _saveError!),
                const SizedBox(height: 14),
              ],

              // ── PATIENT SECTION ─────────────────────────
              _SectionHeader(
                icon: Icons.person_outline_rounded,
                label: AppConfig.addReqSectionPatient,
              ),
              const SizedBox(height: 12),

              _FormField(
                label: AppConfig.addReqPatientName,
                hint: AppConfig.addReqPatientHint,
                required: true,
                controller: _patientNameCtrl,
                focusNode: _patientFocus,
                nextFocus: _hospitalFocus,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Patient name is required' : null,
              ),
              const SizedBox(height: 12),

              _FormField(
                label: AppConfig.addReqHospital,
                hint: AppConfig.addReqHospitalHint,
                required: true,
                controller: _hospitalCtrl,
                focusNode: _hospitalFocus,
                nextFocus: _locationFocus,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Hospital name is required' : null,
              ),
              const SizedBox(height: 12),

              _FormField(
                label: AppConfig.addReqLocation,
                hint: AppConfig.addReqLocationHint,
                required: false,
                controller: _locationCtrl,
                focusNode: _locationFocus,
                nextFocus: _contactPFocus,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 22),

              // ── CONTACT SECTION ─────────────────────────
              _SectionHeader(
                icon: Icons.phone_outlined,
                label: AppConfig.addReqSectionContact,
              ),
              const SizedBox(height: 12),

              _FormField(
                label: AppConfig.addReqContactPerson,
                hint: AppConfig.addReqContactHint,
                required: true,
                controller: _contactPersonCtrl,
                focusNode: _contactPFocus,
                nextFocus: _contactPhFocus,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Contact person is required' : null,
              ),
              const SizedBox(height: 12),

              _FormField(
                label: AppConfig.addReqContactPhone,
                hint: AppConfig.addReqPhoneHint,
                required: true,
                controller: _contactPhoneCtrl,
                focusNode: _contactPhFocus,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Phone number is required';
                  if (v.trim().length < 10) return 'Enter a valid phone number';
                  return null;
                },
              ),

              const SizedBox(height: 22),

              // ── DETAILS SECTION ─────────────────────────
              _SectionHeader(
                icon: Icons.bloodtype_outlined,
                label: AppConfig.addReqSectionDetails,
              ),
              const SizedBox(height: 14),

              // Blood Type — chip grid
              _FieldLabel(label: AppConfig.addReqBloodType, required: true),
              const SizedBox(height: 8),
              _BloodTypeGrid(
                selected: _bloodType,
                onSelect: (t) {
                  setState(() { _bloodType = t; _saveError = null; });
                },
              ),
              if (_bloodType.isEmpty && _saveError != null &&
                  _saveError!.contains('blood type'))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Please select a blood type',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.primary)),
                ),

              const SizedBox(height: 18),

              // Units stepper
              _FieldLabel(label: AppConfig.addReqUnits, required: true),
              const SizedBox(height: 8),
              _UnitsStepper(
                value: _units,
                onDecrement: () { if (_units > 1) setState(() => _units--); },
                onIncrement: () => setState(() => _units++),
              ),

              const SizedBox(height: 18),

              // Urgency — chip row
              _FieldLabel(label: AppConfig.addReqUrgency, required: true),
              const SizedBox(height: 8),
              _UrgencyChips(
                selected: _urgency,
                colors: _urgencyColors,
                icons: _urgencyIcons,
                onSelect: (u) => setState(() => _urgency = u),
              ),

              const SizedBox(height: 18),

              // Required By date
              _FieldLabel(label: AppConfig.addReqRequiredBy, required: false),
              const SizedBox(height: 8),
              _DatePickerTile(
                date: _requiredBy,
                hint: AppConfig.addReqDateHint,
                onTap: _pickDate,
                onClear: () => setState(() => _requiredBy = null),
              ),

              // Status (edit only)
              if (_isEditing) ...[
                const SizedBox(height: 18),
                _FieldLabel(label: AppConfig.addReqStatus, required: false),
                const SizedBox(height: 8),
                _StatusDropdown(
                  value: _status,
                  items: AppConstants.requirementStatuses,
                  onChanged: (v) => setState(() => _status = v ?? 'Open'),
                ),
              ],

              const SizedBox(height: 18),

              // Notes
              _FieldLabel(label: AppConfig.addReqNotes, required: false),
              const SizedBox(height: 8),
              _NotesField(
                controller: _notesCtrl,
                focusNode: _notesFocus,
                hint: AppConfig.addReqNotesHint,
              ),

              const SizedBox(height: 32),

              // ── Save button ─────────────────────────────
              _SaveButton(saving: _saving, isEditing: _isEditing, onTap: _save),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  COMPONENTS
// ════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: AppColors.urgentBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: AppColors.primary),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: GoogleFonts.syne(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: 0.2,
        ),
      ),
    ]);
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel({required this.label, required this.required});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label,
        style: GoogleFonts.dmSans(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
      if (required)
        Text(' *', style: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: AppColors.primary)),
    ]);
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final bool required;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _FormField({
    required this.label,
    required this.hint,
    required this.required,
    required this.controller,
    required this.focusNode,
    required this.textInputAction,
    this.nextFocus,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label, required: required),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: textInputAction,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onFieldSubmitted: (_) {
            if (nextFocus != null) {
              FocusScope.of(context).requestFocus(nextFocus);
            } else {
              focusNode.unfocus();
            }
          },
          style: GoogleFonts.dmSans(
              fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
                fontSize: 14, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.primary, width: 1.5),
            ),
            errorStyle: GoogleFonts.dmSans(
                fontSize: 11, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _BloodTypeGrid extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _BloodTypeGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.0,
      ),
      itemCount: AppConstants.bloodTypes.length,
      itemBuilder: (_, i) {
        final t = AppConstants.bloodTypes[i];
        final isSelected = t == selected;
        return GestureDetector(
          onTap: () => onSelect(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 0 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              t,
              style: GoogleFonts.syne(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UnitsStepper extends StatelessWidget {
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  const _UnitsStepper({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        _StepBtn(
          icon: Icons.remove_rounded,
          enabled: value > 1,
          onTap: onDecrement,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                '$value',
                style: GoogleFonts.syne(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                value == 1 ? 'unit' : 'units',
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        _StepBtn(
          icon: Icons.add_rounded,
          enabled: true,
          onTap: onIncrement,
          filled: true,
        ),
      ]),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool filled;
  final VoidCallback onTap;
  const _StepBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: !enabled
              ? AppColors.background
              : filled
                  ? AppColors.primary
                  : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: !enabled
                ? AppColors.border
                : filled
                    ? AppColors.primary
                    : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: !enabled
              ? AppColors.textMuted
              : filled
                  ? Colors.white
                  : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _UrgencyChips extends StatelessWidget {
  final String selected;
  final Map<String, Color> colors;
  final Map<String, IconData> icons;
  final ValueChanged<String> onSelect;
  const _UrgencyChips({
    required this.selected,
    required this.colors,
    required this.icons,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: AppConstants.urgencyLevels.map((u) {
        final isSelected = u == selected;
        final color = colors[u]!;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: u == AppConstants.urgencyLevels.last ? 0 : 8,
            ),
            child: GestureDetector(
              onTap: () => onSelect(u),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.12)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? color : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icons[u], size: 16,
                        color: isSelected ? color : AppColors.textMuted),
                    const SizedBox(height: 4),
                    Text(u,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected ? color : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final DateTime? date;
  final String hint;
  final VoidCallback onTap;
  final VoidCallback onClear;
  const _DatePickerTile({
    required this.date,
    required this.hint,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined,
              size: 16,
              color: date != null ? AppColors.primary : AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              date != null
                  ? DateFormat('d MMM yyyy').format(date!)
                  : hint,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: date != null
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
            ),
          ),
          if (date != null)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close_rounded,
                  size: 16, color: AppColors.textMuted),
            )
          else
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textMuted),
        ]),
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _StatusDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 20, color: AppColors.textMuted),
          style: GoogleFonts.dmSans(
              fontSize: 14, color: AppColors.textPrimary),
          dropdownColor: AppColors.surface,
          items: items
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _NotesField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  const _NotesField({
    required this.controller,
    required this.focusNode,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLines: 4,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => focusNode.unfocus(),
      style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(
            fontSize: 14, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool saving;
  final bool isEditing;
  final VoidCallback onTap;
  const _SaveButton({
    required this.saving,
    required this.isEditing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: saving ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: saving
              ? AppColors.primary.withOpacity(0.55)
              : AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: saving
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Center(
          child: saving
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isEditing
                          ? Icons.check_rounded
                          : Icons.add_rounded,
                      color: Colors.white, size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppConfig.addReqSaveBtn,
                      style: GoogleFonts.syne(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.urgentBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.urgentBorder),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: AppColors.primary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
            style: GoogleFonts.dmSans(
                fontSize: 12, color: AppColors.urgentText)),
        ),
      ]),
    );
  }
}
