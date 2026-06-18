import 'package:flutter/material.dart';
import 'package:truck_mate/screen/driver/trips_screen.dart';

// 1. كلاس الألوان المستخدم للتصميم الداكن
class AppColors {
  static const Color kBgDark = Color(0xFF0C1D2A);    // خلفية الكارد الداكنة
  static const Color kAmber = Color(0xFFF9A825);     // لون علامة الـ $
  static const Color kTeal = Color(0xFF00BFA5);      // اللون الفيروزي لزر View ونقطة الحالة
  static const Color kMuted = Color(0xFF5F7E97);     // لون النصوص الفرعية والأيقونات (مثل التاريخ والـ ID)
  static const Color kSuccessBg = Color(0xFF0A2F2D); // خلفية بادج Delivered (أخضر داكن شفاف)
  static const Color kSuccessText = Color(0xFF4CAF50); // لون نص بادج Delivered
}

// 2. الكارد الرئيسي المحدث بناءً على الصورة الثانية
class MyTripsCard extends StatefulWidget {
  final TripModel trip; // استبدله بـ TripModel الخاص بك ليكون t.from, t.to, t.id, إلخ.
  final bool isDark;
  const MyTripsCard({required this.trip, this.isDark = true});

  @override
  State<MyTripsCard> createState() => MyTripsCardState();
}

class MyTripsCardState extends State<MyTripsCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.trip;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.kBgDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // أرقونة الشاحنة الدائرية على اليسار
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.kSuccessBg.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.kSuccessText,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // المحتوى الأوسط واليمين
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // السطر الأول: الوجهة وحالة الرحلة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: const TextStyle(fontSize: 16, color: Colors.white),
                              children: [
                                TextSpan(
                                  text: '${t.from ?? "Cairo"} ',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: '→ ',
                                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                                ),
                                TextSpan(
                                  text: ' ${t.to ?? "Alexandria"}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // بادج الحالة (Delivered)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.kSuccessBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.kSuccessText,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Delivered',
                                style: const TextStyle(
                                  color: AppColors.kSuccessText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // السطر الثاني: معرف الرحلة (Trip ID)
                    const SizedBox(height: 2),
                    Text(
                      t.id ?? 'TRIP-4518',
                      style: const TextStyle(
                        color: AppColors.kMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // السطر الثالث: السعر، التاريخ، وزر العرض
                    Row(
                      children: [
                        // السعر
                        const Icon(Icons.attach_money_rounded, color: AppColors.kAmber, size: 16),
                        Text(
                          '${t.earnings ?? "240"} EGP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // التاريخ
                        const Icon(Icons.calendar_today_outlined, color: AppColors.kMuted, size: 12),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            t.date ?? '2026-04-25',
                            style: const TextStyle(
                              color: AppColors.kMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),

                        // زر View الخاص بالتفاصيل
                        InkWell(
                          onTap: () {
                            // الأكشن عند الضغط على زر عرض التفاصيل
                          },
                          child: const Row(
                            children: [
                              Text(
                                'View',
                                style: TextStyle(
                                  color: AppColors.kTeal,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.kTeal,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}