import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/screen/trader/TraderReviewConfirmScreen.dart';

class TraderBusinessDetailsScreen extends StatefulWidget {
  final String fullName, phone, email, nationalId, password;
  const TraderBusinessDetailsScreen({super.key,
    this.fullName='', this.phone='', this.email='',
    this.nationalId='', this.password=''});
  @override
  State<TraderBusinessDetailsScreen> createState() => _TraderBusinessDetailsScreenState();
}

class _TraderBusinessDetailsScreenState extends State<TraderBusinessDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => TraderReviewConfirmScreen(
          fullName: widget.fullName, phone: widget.phone,
          email: widget.email, nationalId: widget.nationalId,
          password: widget.password,
          businessName: _businessNameCtrl.text,
          address: _addressCtrl.text,
        )));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    return Scaffold(
      backgroundColor: t.regBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Form(
              key: _formKey,
              child: Column(children: [
                // ── Back ──
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 45, height: 45,
                      decoration: BoxDecoration(
                        color: t.fieldBg, shape: BoxShape.circle,
                        border: Border.all(color: t.border),
                        boxShadow: t.cardShadow),
                      child: Icon(Icons.arrow_back, color: AppTheme.primary, size: 22)),
                  ),
                ),
                const SizedBox(height: 15),
                Text('Create Account', style: TextStyle(fontSize: 24,
                    fontWeight: FontWeight.bold, color: t.textPrimary)),
                const SizedBox(height: 8),
                Text('Trader Registration', style: TextStyle(fontSize: 16, color: t.textMuted)),
                const SizedBox(height: 40),

                // ── Stepper ──
                _buildStepper(t),
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
                    Center(child: Text('Business Details',
                        style: TextStyle(fontSize: 18, color: t.textPrimary,
                            fontWeight: FontWeight.bold))),
                    const SizedBox(height: 30),
                    _buildField('Business Name', 'Enter your business name',
                        Icons.business_outlined, _businessNameCtrl, t,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter business name' : null),
                    _buildField('Address', 'Enter business address',
                        Icons.location_on_outlined, _addressCtrl, t,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter address' : null),
                    const SizedBox(height: 10),
                    _buildNextBtn(),
                  ]),
                ),
                const SizedBox(height: 30),
                Text('© 2025 TruckMate',
                    style: TextStyle(color: t.textMuted, fontSize: 14)),
                const SizedBox(height: 10),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepper(AppTheme t) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _stepDot(Icons.person, true, t),
      _stepLine(true, t),
      _stepDot(Icons.business_center_outlined, true, t),
      _stepLine(false, t),
      _stepDot(Icons.check_circle_outline, false, t),
    ],
  );

  Widget _stepDot(IconData icon, bool active, AppTheme t) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: active ? AppTheme.primaryLight.withOpacity(t.isDark ? 0.1 : 0.3) : t.fieldBg,
      border: Border.all(color: active ? AppTheme.primary : t.border, width: 1.5),
      boxShadow: active ? [BoxShadow(
          color: AppTheme.primary.withOpacity(0.25),
          blurRadius: 10, spreadRadius: 1)] : null),
    child: Icon(icon, color: active ? AppTheme.primary : t.textMuted, size: 24),
  );

  Widget _stepLine(bool active, AppTheme t) => Container(
    width: 45, height: 1.5,
    color: active ? AppTheme.primary : t.border,
  );

  Widget _buildField(String label, String hint, IconData icon,
      TextEditingController ctrl, AppTheme t,
      {String? Function(String?)? validator}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: t.textPrimary, fontSize: 14,
            fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl, validator: validator,
          style: TextStyle(color: t.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: t.textMuted, fontSize: 13),
            prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
            filled: true, fillColor: t.fieldBg,
            errorStyle: const TextStyle(color: Colors.redAccent),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: t.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.2)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
          ),
        ),
      ]),
    );

  Widget _buildNextBtn() => SizedBox(
    width: double.infinity, height: 55,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF009EA3), AppTheme.primary],
            begin: Alignment.centerLeft, end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 15, offset: const Offset(0, 5))]),
      child: ElevatedButton(
        onPressed: _handleNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        child: const Text('Next',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    ),
  );
}