import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/providers/user_provider.dart';
import '/screen/driver/driver_otp_screen4.dart';
import '/screen/driver/license_details_screen.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final String fullName, phone, email, nationalId, licenseNumber, licenseType;
  final String licenseImageBase64; // ← جديد
  const VehicleDetailsScreen({super.key,
    this.fullName='', this.phone='', this.email='',
    this.nationalId='', this.licenseNumber='', this.licenseType='',
    this.licenseImageBase64=''}); // ← جديد
  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl    = TextEditingController();
  final _truckCtrl    = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  String _unit = 'kg';

  @override
  void dispose() {
    _plateCtrl.dispose(); _truckCtrl.dispose(); _capacityCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    final capacity = '${_capacityCtrl.text} $_unit';
    context.read<UserProvider>().update(
      fullName: widget.fullName, phone: widget.phone,
      email: widget.email, nationalId: widget.nationalId,
      licenseNumber: widget.licenseNumber, licenseType: widget.licenseType,
      plateNumber: _plateCtrl.text, truckType: _truckCtrl.text, capacity: capacity);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => DriverOtpScreen4(
        fullName:           widget.fullName,
        phone:              widget.phone,
        email:              widget.email,
        nationalId:         widget.nationalId,
        licenseNumber:      widget.licenseNumber,
        licenseType:        widget.licenseType,
        plateNumber:        _plateCtrl.text,
        truckType:          _truckCtrl.text,
        capacity:           capacity,
        password:           _passCtrl.text,
        licenseImageBase64: widget.licenseImageBase64, // ← جديد
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
            Align(alignment: Alignment.centerLeft,
              child: GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(width: 45, height: 45,
                  decoration: BoxDecoration(color: t.fieldBg, shape: BoxShape.circle,
                    border: Border.all(color: t.border)),
                  child: Icon(Icons.arrow_back, color: AppTheme.primary, size: 22)))),
            const SizedBox(height: 15),
            Text('Create Account', style: TextStyle(fontSize: 24,
                fontWeight: FontWeight.bold, color: t.textPrimary)),
            const SizedBox(height: 8),
            Text('Driver Registration', style: TextStyle(fontSize: 16, color: t.textMuted)),
            const SizedBox(height: 40),
            DriverStepIndicator(currentStep: 3),
            const SizedBox(height: 40),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              decoration: BoxDecoration(
                color: t.card, borderRadius: BorderRadius.circular(35),
                border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                boxShadow: t.cardShadow),
              child: Column(children: [
                Text('Vehicle Information', style: TextStyle(fontSize: 18,
                    color: t.textPrimary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),

                DriverInputField(label: 'Plate Number', hint: 'e.g. أ ب ج 123',
                  icon: Icons.tag, controller: _plateCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                DriverInputField(label: 'Truck Type', hint: 'e.g., Box Truck, Flatbed',
                  icon: Icons.local_shipping_outlined, controller: _truckCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),

                // ── Capacity + unit ──
                Padding(padding: const EdgeInsets.only(bottom: 22),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Capacity', style: TextStyle(color: t.textPrimary,
                        fontSize: 15, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: TextFormField(
                        controller: _capacityCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: t.textPrimary, fontSize: 16),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        decoration: InputDecoration(
                          hintText: 'e.g. 5000',
                          hintStyle: TextStyle(color: t.textMuted, fontSize: 14),
                          prefixIcon: Icon(Icons.inventory_2_outlined,
                              color: AppTheme.primary, size: 22),
                          filled: true, fillColor: t.fieldBg,
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: t.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.redAccent)),
                          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5))))),
                      const SizedBox(width: 10),
                      Container(height: 56, padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: t.fieldBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.4))),
                        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                          value: _unit,
                          dropdownColor: t.card,
                          style: TextStyle(color: AppTheme.primary, fontSize: 15,
                              fontWeight: FontWeight.w600),
                          icon: Icon(Icons.keyboard_arrow_down,
                              color: AppTheme.primary, size: 18),
                          items: const [
                            DropdownMenuItem(value: 'kg', child: Text('kg')),
                            DropdownMenuItem(value: 'ton', child: Text('ton')),
                          ],
                          onChanged: (v) => setState(() => _unit = v!)))),
                    ]),
                  ])),

                _PassField(label: 'Password', hint: 'Enter your password',
                  ctrl: _passCtrl, obscure: _obscurePass, theme: t,
                  onToggle: () => setState(() => _obscurePass = !_obscurePass),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 8) return 'Min 8 characters';
                    return null;
                  }),
                _PassField(label: 'Confirm Password', hint: 'Retype your password',
                  ctrl: _confirmCtrl, obscure: _obscureConfirm, theme: t,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null),

                const SizedBox(height: 15),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
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

class _PassField extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final bool obscure;
  final VoidCallback onToggle;
  final AppTheme theme;
  final String? Function(String?)? validator;
  const _PassField({required this.label, required this.hint, required this.ctrl,
    required this.obscure, required this.onToggle, required this.theme, this.validator});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: theme.textPrimary, fontSize: 15,
          fontWeight: FontWeight.w500)),
      const SizedBox(height: 10),
      TextFormField(controller: ctrl, obscureText: obscure, validator: validator,
        style: TextStyle(color: theme.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: theme.textMuted, fontSize: 14),
          prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primary, size: 22),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.primary, size: 20),
            onPressed: onToggle),
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