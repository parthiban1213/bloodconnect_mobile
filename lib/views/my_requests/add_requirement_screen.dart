import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/blood_requirement.dart';
import '../../services/requirements_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  AddRequirementScreen
//  Form fields mirror the website exactly:
//    Patient Name*, Hospital*, Location, Contact Person*,
//    Contact Phone*, Blood Type*, Units Required*,
//    Urgency*, Required By Date, Status, Notes
// ─────────────────────────────────────────────────────────────

class AddRequirementScreen extends ConsumerStatefulWidget {
  /// When provided, the form pre-fills with this requirement's data (edit mode).
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

  // Dropdown values
  String _bloodType = '';
  String _urgency   = 'Medium';
  String _status    = 'Open';
  int    _units     = 1;
  DateTime? _requiredBy;

  bool _saving = false;
  String? _saveError;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields when editing an existing request
    final e = widget.existing;
    if (e != null) {
      _patientNameCtrl.text   = e.patientName;
      _hospitalCtrl.text      = e.hospital;
      _locationCtrl.text      = e.location;
      _contactPersonCtrl.text = e.contactPerson;
      _contactPhoneCtrl.text  = e.contactPhone;
      _notesCtrl.text         = e.notes;
      _bloodType = e.bloodType;
      _urgency   = e.urgency;
      _status    = e.status;
      _units     = e.unitsRequired;
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
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _requiredBy = picked);
  }

  Future<void> _save() async {
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
        'status':        _status,
        'notes':         _notesCtrl.text.trim(),
        if (_requiredBy != null)
          'requiredBy': _requiredBy!.toIso8601String(),
        if (!_isEditing)
          'remainingUnits': _units,
      };

      if (_isEditing) {
        await _service.updateRequirement(widget.existing!.id, body);
      } else {
        await _service.createRequirement(body);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            _isEditing
                ? 'Request updated successfully!'
                : 'Requirement created successfully!',
            style: GoogleFonts.dmSans(fontSize: 13),
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
        context.pop();
      }
    } catch (e) {
      setState(() {
        _saving     = false;
        _saveError  = e.toString().replaceFirst('Exception: ', '');
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
          _isEditing ? 'Edit Blood Request' : 'New Blood Request',
          style: GoogleFonts.syne(
            fontSize: 17,
            fontWeight: FontWeight.w700,
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            // ── Error banner ─────────────────────────────
            if (_saveError != null) ...[
              _ErrorBanner(message: _saveError!),
              const SizedBox(height: 12),
            ],

            // ── Section: Patient ─────────────────────────
            _SectionHeader('Patient Details'),
            const SizedBox(height: 10),
            _Field(
              label: 'Patient Name',
              required: true,
              hint: 'e.g. Ravi Kumar',
              controller: _patientNameCtrl,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Patient name is required' : null,
            ),
            const SizedBox(height: 10),
            _Field(
              label: 'Hospital / Centre',
              required: true,
              hint: 'e.g. PSG Hospital',
              controller: _hospitalCtrl,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Hospital name is required' : null,
            ),
            const SizedBox(height: 10),
            _Field(
              label: 'Location',
              required: false,
              hint: 'e.g. Coimbatore, Tamil Nadu',
              controller: _locationCtrl,
            ),

            const SizedBox(height: 18),
            _SectionHeader('Contact Information'),
            const SizedBox(height: 10),

            _Field(
              label: 'Contact Person',
              required: true,
              hint: 'Name of coordinator',
              controller: _contactPersonCtrl,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Contact person is required' : null,
            ),
            const SizedBox(height: 10),
            _Field(
              label: 'Contact Phone',
              required: true,
              hint: '+91 98765 43210',
              controller: _contactPhoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Phone number is required';
                if (v.trim().length < 10) return 'Enter a valid phone number';
                return null;
              },
            ),

            const SizedBox(height: 18),
            _SectionHeader('Requirement Details'),
            const SizedBox(height: 10),

            // ── Blood Type dropdown ──────────────────────
            _DropdownField<String>(
              label: 'Blood Type',
              required: true,
              value: _bloodType.isEmpty ? null : _bloodType,
              hint: 'Select blood type',
              items: AppConstants.bloodTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _bloodType = v ?? ''),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Please select a blood type' : null,
            ),
            const SizedBox(height: 10),

            // ── Units Required ───────────────────────────
            _FieldContainer(
              label: 'Units Required',
              required: true,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_units > 1) setState(() => _units--);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.remove_rounded,
                          size: 16, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '$_units',
                    style: GoogleFonts.syne(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: () => setState(() => _units++),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_rounded,
                          size: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'unit${_units != 1 ? 's' : ''}',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Urgency dropdown ─────────────────────────
            _DropdownField<String>(
              label: 'Urgency',
              required: true,
              value: _urgency,
              items: AppConstants.urgencyLevels
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (v) => setState(() => _urgency = v ?? 'Medium'),
            ),
            const SizedBox(height: 10),

            // ── Required By date picker ──────────────────
            _FieldContainer(
              label: 'Required By Date',
              required: false,
              child: GestureDetector(
                onTap: _pickDate,
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 15, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Text(
                      _requiredBy != null
                          ? DateFormat('d MMM yyyy').format(_requiredBy!)
                          : 'Select date (optional)',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: _requiredBy != null
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    if (_requiredBy != null)
                      GestureDetector(
                        onTap: () => setState(() => _requiredBy = null),
                        child: const Icon(Icons.close_rounded,
                            size: 15, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Status dropdown ──────────────────────────
            _DropdownField<String>(
              label: 'Status',
              required: false,
              value: _status,
              items: AppConstants.requirementStatuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? 'Open'),
            ),
            const SizedBox(height: 10),

            // ── Notes ────────────────────────────────────
            _FieldContainer(
              label: 'Additional Notes',
              required: false,
              child: TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Any special instructions or context…',
                  hintStyle: GoogleFonts.dmSans(
                      fontSize: 13, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Save button ──────────────────────────────
            GestureDetector(
              onTap: _saving ? null : _save,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _saving
                      ? AppColors.primary.withOpacity(0.55)
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save Requirement',
                          style: GoogleFonts.syne(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ── Reusable form components ──────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.syne(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
        color: AppColors.textMuted,
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
          child: Text(
            message,
            style: GoogleFonts.dmSans(
                fontSize: 12, color: AppColors.urgentText),
          ),
        ),
      ]),
    );
  }
}

class _FieldContainer extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;

  const _FieldContainer({
    required this.label,
    required this.required,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(
            label,
            style: GoogleFonts.syne(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.06,
            ),
          ),
          if (required)
            Text(
              ' *',
              style: GoogleFonts.syne(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary),
            ),
        ]),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final bool required;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _Field({
    required this.label,
    required this.required,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldContainer(
      label: label,
      required: required,
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: GoogleFonts.dmSans(
            fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(
              fontSize: 13, color: AppColors.textMuted),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          errorStyle: GoogleFonts.dmSans(
              fontSize: 11, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final bool required;
  final T? value;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const _DropdownField({
    required this.label,
    required this.required,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldContainer(
      label: label,
      required: required,
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        style: GoogleFonts.dmSans(
            fontSize: 13, color: AppColors.textPrimary),
        hint: hint != null
            ? Text(hint!,
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textMuted))
            : null,
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            size: 18, color: AppColors.textMuted),
        isExpanded: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        dropdownColor: AppColors.surface,
      ),
    );
  }
}
