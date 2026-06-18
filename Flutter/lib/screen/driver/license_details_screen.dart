import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/screen/driver/vehicle_details_screen.dart';

class LicenseDetailsScreen extends StatefulWidget {
  final String fullName, phone, email, nationalId;
  const LicenseDetailsScreen({super.key,
    this.fullName='', this.phone='', this.email='', this.nationalId=''});
  @override
  State<LicenseDetailsScreen> createState() => _LicenseDetailsScreenState();
}

class _LicenseDetailsScreenState extends State<LicenseDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseNumCtrl  = TextEditingController();
  final _licenseTypeCtrl = TextEditingController();

  String? _uploadedFileName;
  String? _licenseImageBase64;   // ← ده اللي هيتبعت للباك
  bool _showFileError = false;

  @override
  void dispose() {
    _licenseNumCtrl.dispose();
    _licenseTypeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,   // ← مهم: بيجيب الـ bytes مباشرة
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;

      // بيحول الصورة لـ Base64
      String base64String;
      if (file.bytes != null) {
        // Mobile: bytes موجودة مباشرة
        base64String = base64Encode(file.bytes!);
      } else if (file.path != null) {
        // Desktop/other: نقرأ من الـ path
        final bytes = await File(file.path!).readAsBytes();
        base64String = base64Encode(bytes);
      } else {
        return;
      }

      setState(() {
        _uploadedFileName    = file.name;
        _licenseImageBase64  = base64String;
        _showFileError       = false;
      });
    }
  }

  void _next() {
    final formOk  = _formKey.currentState!.validate();
    final hasFile = _licenseImageBase64 != null;
    if (!hasFile) setState(() => _showFileError = true);
    if (!formOk || !hasFile) return;

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => VehicleDetailsScreen(
        fullName:           widget.fullName,
        phone:              widget.phone,
        email:              widget.email,
        nationalId:         widget.nationalId,
        licenseNumber:      _licenseNumCtrl.text,
        licenseType:        _licenseTypeCtrl.text,
        licenseImageBase64: _licenseImageBase64!, // ← بنبعته للـ screen الجاية
      )));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    return Scaffold(
      backgroundColor: t.regBg,
      body: SafeArea(child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Form(key: _formKey, child: Column(children: [
            // ── Back button ──
            Align(alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(width: 45, height: 45,
                  decoration: BoxDecoration(
                    color: t.fieldBg, shape: BoxShape.circle,
                    border: Border.all(color: t.border)),
                  child: Icon(Icons.arrow_back, color: AppTheme.primary, size: 22)))),
            const SizedBox(height: 15),
            Text('Create Account', style: TextStyle(fontSize: 24,
                fontWeight: FontWeight.bold, color: t.textPrimary)),
            const SizedBox(height: 8),
            Text('Driver Registration', style: TextStyle(fontSize: 16, color: t.textMuted)),
            const SizedBox(height: 40),
            _Stepper(step: 2, theme: t),
            const SizedBox(height: 40),

            // ── Form card ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                boxShadow: t.cardShadow),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Text('License Details', style: TextStyle(
                    fontSize: 18, color: t.textPrimary, fontWeight: FontWeight.bold))),
                const SizedBox(height: 30),
                _ThemedField(label: 'License Number', hint: 'Enter license number',
                  icon: Icons.description_outlined, ctrl: _licenseNumCtrl, theme: t,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                _ThemedField(label: 'License Type', hint: 'e.g., Commercial Class A',
                  icon: Icons.workspace_premium_outlined, ctrl: _licenseTypeCtrl, theme: t,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),

                // ── Upload ──
                Text('Upload License', style: TextStyle(
                    color: t.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(width: double.infinity, height: 58,
                    decoration: BoxDecoration(
                      color: t.fieldBg, borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _showFileError
                            ? Colors.redAccent
                            : _licenseImageBase64 != null
                                ? AppTheme.primary  // ← أخضر لما يتحمل
                                : t.border,
                        width: _licenseImageBase64 != null ? 1.5 : 1.0,
                      )),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(
                        _licenseImageBase64 != null
                            ? Icons.check_circle_outline  // ← تم الرفع ✅
                            : Icons.upload_outlined,
                        color: _licenseImageBase64 != null
                            ? AppTheme.primary
                            : AppTheme.primary,
                        size: 22),
                      const SizedBox(width: 10),
                      Flexible(child: Text(
                        _uploadedFileName ?? 'Choose file...',
                        style: TextStyle(
                          color: _licenseImageBase64 != null
                              ? AppTheme.primary
                              : t.textMuted,
                          fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      )),
                    ]))),
                if (_showFileError) const Padding(
                  padding: EdgeInsets.only(top: 8, left: 12),
                  child: Text('Please upload license file',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12))),

                const SizedBox(height: 30),
                // ── Next button ──
                SizedBox(width: double.infinity, height: 58,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF009EA3), AppTheme.primary]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3),
                          blurRadius: 15, offset: const Offset(0, 5))]),
                    child: ElevatedButton(onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text('Next', style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))))),
              ])),
            const SizedBox(height: 30),
            Text('© 2025 TruckMate', style: TextStyle(color: t.textMuted, fontSize: 14)),
            const SizedBox(height: 10),
          ])),
        ),
      )),
    );
  }
}

// ── Stepper ──
class _Stepper extends StatelessWidget {
  final int step; final AppTheme theme;
  const _Stepper({required this.step, required this.theme});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _dot(Icons.person, step >= 1),
      _line(step >= 2),
      _dot(Icons.badge_outlined, step >= 2),
      _line(step >= 3),
      _dot(Icons.local_shipping, step >= 3),
    ]);
  Widget _dot(IconData icon, bool active) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(shape: BoxShape.circle,
      color: active ? Colors.transparent : theme.fieldBg,
      border: Border.all(
        color: active ? AppTheme.primary : theme.border, width: 1.5),
      boxShadow: active ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3),
          blurRadius: 12, spreadRadius: 1)] : null),
    child: Icon(icon, color: active ? AppTheme.primary : theme.textMuted, size: 26));
  Widget _line(bool active) => Container(width: 45, height: 2,
    color: active ? AppTheme.primary : theme.border);
}

// ── Themed input field ──
class _ThemedField extends StatelessWidget {
  final String label, hint; final IconData icon;
  final TextEditingController ctrl; final AppTheme theme;
  final String? Function(String?)? validator;
  const _ThemedField({required this.label, required this.hint,
    required this.icon, required this.ctrl, required this.theme, this.validator});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: theme.textPrimary, fontSize: 15,
          fontWeight: FontWeight.w500)),
      const SizedBox(height: 10),
      TextFormField(controller: ctrl, validator: validator,
        style: TextStyle(color: theme.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: theme.textMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 22),
          filled: true, fillColor: theme.fieldBg,
          errorStyle: const TextStyle(color: Colors.redAccent),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5))))
    ]));
}

// ── Shared exports ──
class DriverStepIndicator extends StatelessWidget {
  final int currentStep;
  const DriverStepIndicator({super.key, required this.currentStep});
  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    return _Stepper(step: currentStep, theme: t);
  }
}

class DriverInputField extends StatelessWidget {
  final String label, hint; final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  const DriverInputField({super.key, required this.label, required this.hint,
    required this.icon, required this.controller, this.keyboardType, this.validator});
  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    return _ThemedField(label: label, hint: hint, icon: icon,
        ctrl: controller, theme: t, validator: validator);
  }
}

class DriverUploadField extends StatelessWidget {
  final String fileName; final bool showError; final VoidCallback onTap;
  const DriverUploadField({super.key, required this.fileName,
    required this.showError, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(onTap: onTap,
        child: Container(width: double.infinity, height: 58,
          decoration: BoxDecoration(color: t.fieldBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: showError ? Colors.redAccent : t.border)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.upload_outlined, color: AppTheme.primary, size: 22),
            const SizedBox(width: 10),
            Text(fileName, style: TextStyle(color: t.textMuted, fontSize: 14)),
          ]))),
      if (showError) const Padding(
        padding: EdgeInsets.only(top: 8, left: 12),
        child: Text('Please upload license file',
            style: TextStyle(color: Colors.redAccent, fontSize: 12))),
    ]);
  }
}