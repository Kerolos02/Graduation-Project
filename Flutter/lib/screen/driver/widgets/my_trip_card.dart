import 'package:flutter/material.dart';
import 'package:truck_mate/screen/driver/trips_screen.dart';

// 1. كلاس الألوان المنظم
class AppColors {
  static const Color kBgDark = Color(0xFF0C1D2A);    // خلفية الكارد الداكنة
  static const Color kAmber = Color(0xFFF9A825);     // اللون الأصفر العلوي
  static const Color kTeal = Color(0xFF00BFA5);      // اللون الفيروزي لزر Accept
  static const Color kCardTile = Color(0xFF14293A);  // خلفية المربعات الصغيرة (Distance/Time)
  static const Color kMuted = Color(0xFF8A9A9F);     // لون النصوص الفرعية
}

// 2. الكارد الرئيسي
class MyTripCard extends StatefulWidget {
  final TripModel trip; // استبدله بـ TripModel الخاص بك
  final bool isDark;
  final VoidCallback onViewDetails;
  const MyTripCard({required this.trip, this.isDark = true , required this.onViewDetails});

  @override
  State<MyTripCard> createState() => MyTripCardState();
}

class MyTripCardState extends State<MyTripCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.kBgDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // السطر العلوي (Offered Price & Earnings)
              Container(
                color: AppColors.kAmber,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Offered Price',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      textBaseline: TextBaseline.alphabetic,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      children: [
                        Text(
                          '\$ ',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          widget.trip.earnings.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'EGP',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // محتوى الكارد الداخلي
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // خط سير الرحلة (Pickup & Drop-off)
                    _LocationRow(
                      pickup: widget.trip.from,
                      dropoff: widget.trip.to,
                    ),
                    const SizedBox(height: 20),

                    // المربعات الثلاثة (Distance, Time, Weight)
                    Row(
                      children: [
                        Expanded(
                          child: _InfoTile(
                            icon: Icons.location_on_outlined,
                            title: 'Distance',
                            value: '${widget.trip.miles.toString()} miles',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: _InfoTile(
                              icon: Icons.date_range,
                              iconColor: AppColors.kAmber,
                              title: 'Date',
                              value: '${widget.trip.date}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                         Expanded(
                          child: _InfoTile(
                            icon: Icons.local_shipping_outlined,
                            title: 'Weight',
                            value: widget.trip.weight.toString(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // نوع الشحنة ووقت النشر
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cargo Type',
                              style: TextStyle(color: AppColors.kMuted, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Construction Materials',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Posted',
                              style: TextStyle(color: AppColors.kMuted, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '5 mins ago',
                              style: TextStyle(
                                color: AppColors.kTeal,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // أزرار التحكم السفلية
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF1F384D)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'View Details',
                                  style: TextStyle(
                                    color: AppColors.kTeal,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.chevron_right_rounded, color: AppColors.kTeal, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: ElevatedButton(
                            onPressed: widget.onViewDetails ,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.kTeal,
                              foregroundColor: AppColors.kBgDark,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Accept',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
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
        ),
      ),
    );
  }
}

// 3. ويدجت المربعات الصغيرة الثلاثة
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    this.iconColor = AppColors.kTeal,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.kCardTile,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 14),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(color: AppColors.kMuted, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// 4. ويدجت خط سير الرحلة العمودي
class _LocationRow extends StatelessWidget {
  final String pickup;
  final String dropoff;
  const _LocationRow({required this.pickup, required this.dropoff});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const SizedBox(height: 4),
            const Icon(Icons.circle, color: AppColors.kTeal, size: 14),
            Container(
              width: 2,
              height: 32,
              color: AppColors.kAmber,
            ),
            const Icon(Icons.location_on, color: AppColors.kAmber, size: 16),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pickup', style: TextStyle(color: AppColors.kMuted, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                pickup,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Drop-off', style: TextStyle(color: AppColors.kMuted, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                dropoff,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}