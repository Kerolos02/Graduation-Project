import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/user_provider.dart';
import 'providers/driver_provider.dart';
import 'providers/trader_provider.dart';
import 'providers/theme_provider.dart';

import 'splash_screen.dart';
import 'onboarding_screen.dart';

import 'screen/auth/login_screen.dart';
import 'screen/auth/Registration_Screen.dart';
import 'screen/auth/select_role.dart';
import 'screen/auth/driver_reset_password.dart';

import 'screen/driver/driver_otp_screen.dart';
import 'screen/driver/driver_otp_screen_v2.dart';
import 'screen/driver/driver_otp_screen4.dart';
import 'screen/driver/driver_otp_screen5.dart';
import 'screen/driver/driver_otp_screen7.dart';
import 'screen/driver/license_details_screen.dart';
import 'screen/driver/vehicle_details_screen.dart';
import 'screen/driver/driver_home_screen.dart';
import 'screen/driver/trip_assigned_screen.dart';
import 'screen/driver/trip_active_screen.dart';
import 'screen/driver/live_navigation_screen.dart';
import 'screen/driver/trips_screen.dart';
import 'screen/driver/driver_earnings_screen.dart';
import 'screen/driver/driver_profile_screens.dart';
import 'screen/driver/my_wallet_screen.dart';

import 'screen/driver/driver_trip_screens.dart';
import 'screen/driver/driver_state_screens.dart';
import 'screen/driver/driver_pickup_screens.dart';

import 'screen/trader/Trader_registration_screen.dart';
import 'screen/trader/TraderBusiness_Details_Screen.dart';
import 'screen/trader/TraderReviewConfirmScreen.dart';
import 'screen/trader/trader_home_screen.dart';
import 'screen/trader/trader_home_active_screen.dart';
import 'screen/trader/trader_new_shipment_screen.dart';
import 'screen/trader/trader_otp_screen.dart';
import 'screen/trader/trader_rating_screen.dart';
import 'screen/trader/trader_shipment_scheduled.dart';
import 'screen/trader/trader_notifications_screen.dart';
import 'screen/trader/trader_profile_screens.dart';
import 'screen/trader/trader_settings_screens.dart';
import 'screen/trader/trader_driver_screens.dart'
    hide ShipmentDetailsScreen;
import 'screen/trader/payment_screens.dart';
import 'screen/trader/trader_state_screens.dart';
import 'screen/trader/trader_shipment_tracking_screen.dart';
import '/screen/trader/trader_my_shipments_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (_) => DriverProvider()),
      ChangeNotifierProvider(create: (_) => TraderProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TruckMate',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/splash',
      routes: {
        '/splash':                    (_) => const SplashScreen(),
        '/onboarding':                (_) => const OnboardingScreen(),
        '/select_role':               (_) => const SelectRole(),
        '/login':                     (_) => const LoginScreen(),
        '/signup':                    (_) => const RegistrationScreen(),
        '/driver_reset_password':     (_) => const DriverResetPassword(),
        '/driver_otp_v2':             (_) => const DriverOtpScreenV2(),
        '/driver_otp_basic':          (_) => const DriverOtpScreen(),
        '/driver_otp_4':              (_) => const DriverOtpScreen4(),
        '/driver_otp_5':              (_) => const DriverOTPScreen5(),
        '/driver_otp_7':              (_) => const DriverOTPScreen7(),
        '/license_details':           (_) => const LicenseDetailsScreen(),
        '/vehicle_details':           (_) => const VehicleDetailsScreen(),
        '/driver_home':               (_) => const DriverHomeScreen(),
        '/trip_assigned':             (_) => const TripAssignedScreen(),
        '/trip_active':               (_) => const TripActiveScreen(),
        '/live_navigation':           (_) => const LiveNavigationScreen(),
        '/trips':                     (_) => const TripsScreen(),
        '/available_trips':           (_) => const AvailableTripsScreen(),
        '/driver_earnings':           (_) => const DriverEarningsScreen(),
        '/driver_earnings_history':   (_) => const DriverEarningsHistoryScreen(),
        '/driver_earnings_breakdown': (_) => const DriverEarningsBreakdownScreen(),
        '/driver_profile':            (_) => const DriverProfileScreen(),
        '/driver_settings':           (_) => const DriverSettingsScreen(),
        '/reviews_ratings':           (_) => const ReviewsRatingsScreen(),
        '/advanced_settings':         (_) => const AdvancedSettingsScreen(),
        '/driver_notifications':      (_) => const DriverNotificationsScreen(),
        '/notification_preferences':  (_) => const NotificationPreferencesScreen(),
        '/my_wallet':                 (_) => const MyWalletScreen(),
        '/finding_shipments':         (_) => const FindingShipmentsScreen(),
        '/no_requests':               (_) => const NoRequestsScreen(),
        '/request_expired':           (_) => const RequestExpiredScreen(),
        '/connection_lost':           (_) => const ConnectionLostScreen(),
        '/failed_to_load':            (_) => const FailedToLoadScreen(),
        '/earnings_empty':            (_) => const DriverEarningsEmptyScreen(),
        '/earnings_error':            (_) => const DriverEarningsErrorScreen(),
        '/earnings_loading':          (_) => const DriverEarningsLoadingScreen(),
        '/alerts_empty':              (_) => const DriverAlertsEmptyScreen(),
        '/alerts_error':              (_) => const DriverAlertsErrorScreen(),
        '/alerts_loading':            (_) => const DriverAlertsLoadingScreen(),

        '/trader_registration':       (_) => const TraderRegistrationScreen(),
        '/trader_business_details':   (_) => const TraderBusinessDetailsScreen(),
        '/trader_review_confirm':     (_) => const TraderReviewConfirmScreen(),
        '/trader_otp':                (_) => const TraderOtpScreen(),
        '/trader_home':               (_) => const TraderHomeScreen(),
        '/trader_home_active':        (_) => const TraderHomeActiveScreen(),
        '/trader_new_shipment':       (_) => const TraderNewShipmentScreen(),
        '/rate_driver':               (_) => const RateDriverScreen(),
        '/write_review':              (_) => const WriteReviewScreen(),
        '/review_submitted':          (_) => const ReviewSubmittedScreen(),
        '/reviews_list':              (_) => const ReviewsListScreen(),
        '/trader_notifications':      (_) => const TraderNotificationsScreen(),
        '/trader_profile':            (_) => const TraderProfileScreen(),
        '/trader_details':            (_) => const TraderDetailsScreen(),
        '/trader_profile_settings':   (_) => const TraderProfileScreen(),
        '/trader_advanced_settings':  (_) => const TraderAdvancedSettingsScreen(),
        '/trader_notif_preferences':  (_) => const TraderNotifPreferencesScreen(),
        '/trader_my_shipments':       (_) => const TraderMyShipmentsScreen(),
        '/suggested_drivers':         (_) => const SuggestedDriversScreen(),
        '/no_drivers':                (_) => const NoDriversScreen(),
        '/drivers_loading':           (_) => const DriversLoadingScreen(),
        '/drivers_error':             (_) => const DriversErrorScreen(),
        '/driver_offers':             (_) => const DriverOffersScreen(),
        '/shipment_details':          (_) => const ShipmentDetailsScreen(),
        '/payment_processing':        (_) => const PaymentProcessingScreen(),
        '/payment_success_simple':    (_) => const PaymentSuccessScreen(),
        '/payment_success':           (_) => const PaymentSuccessScreen(),
        '/payment_failed':            (_) => const PaymentFailedScreen(),
        '/payment_methods':           (_) => const PaymentMethodsListScreen(),
        '/payment_methods_select':    (_) => const PaymentMethodsSelectScreen(),
        '/add_card':                  (_) => const AddCardScreen(),
        '/invoice':                   (_) => const InvoiceScreen(),
        '/shipments_state':           (_) => const ShipmentsStateScreen(),
        '/notifications_state':       (_) => const NotificationsStateScreen(),
        '/offers_state': (_) => const OffersStateScreen(shipmentId: ''),
        '/payment_state': (_) => const PaymentStateScreen(invoiceId: '', paymentCardId: ''),
        '/trader_delivery_success':   (_) => const TraderDeliverySuccessScreen(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/heading_to_pickup' ||
            settings.name == '/arrived_at_pickup' ||
            settings.name == '/pickup_confirmed'  ||
            settings.name == '/in_transit'        ||
            settings.name == '/delivery_success') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          final tripId = args['tripId'] as String? ?? '';

          switch (settings.name) {
            case '/heading_to_pickup':
              return MaterialPageRoute(builder: (_) => PickupScreen(tripId: tripId));
            case '/arrived_at_pickup':
              return MaterialPageRoute(builder: (_) => ArrivedAtPickupScreen(tripId: tripId));
            case '/pickup_confirmed':
              return MaterialPageRoute(builder: (_) => PickupConfirmationScreen(tripId: tripId));
            case '/in_transit':
              return MaterialPageRoute(builder: (_) => InTransitScreen(tripId: tripId));
            case '/delivery_success':
              return MaterialPageRoute(builder: (_) => DeliverySuccessScreen(tripId: tripId));
          }
        }

        if (settings.name == '/trip_available') {
          final trip = settings.arguments as TripData?;
          return MaterialPageRoute(
              builder: (_) => TripAvailableScreen(trip: trip ?? _kDummy));
        }
        if (settings.name == '/request_details') {
          final trip = settings.arguments as TripData?;
          return MaterialPageRoute(
              builder: (_) => RequestDetailsScreen(trip: trip ?? _kDummy));
        }
        if (settings.name == '/request_accepted') {
          final trip = settings.arguments as TripData?;
          return MaterialPageRoute(
              builder: (_) => RequestAcceptedScreen(trip: trip ?? _kDummy));
        }

        if (settings.name == '/trader_shipment_scheduled') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
              builder: (_) => TraderShipmentScheduled(
                pickup:   args['pickup']   ?? '',
                dropoff:  args['dropoff']  ?? '',
                date:     args['date']     ?? '',
                time:     args['time']     ?? '',
                packages: args['packages'] ?? '',
                weight:   args['weight']   ?? '',
              ));
        }

        if (settings.name == '/shipment_details_args') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
              builder: (_) => ShipmentDetailsScreen(
                shipmentId:     args['shipmentId']     ?? 'TM-000000',
                pickup:         args['pickup']         ?? 'Not set',
                dropoff:        args['dropoff']        ?? 'Not set',
                date:           args['date']           ?? '-',
                time:           args['time']           ?? '-',
                packages:       args['packages']       ?? '1',
                weight:         args['weight']         ?? '0',
                status:         args['status']         ?? 'pending',
                driverName:     args['driverName']     ?? 'Ahmed Hassan',
                driverInitials: args['driverInitials'] ?? 'AH',
                cancelReason:   args['cancelReason'],
              ));
        }

        if (settings.name == '/rate_driver') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
              builder: (_) => RateDriverScreen(
                driverName:     args['driverName']     ?? 'Ahmed Hassan',
                driverInitials: args['driverInitials'] ?? 'AH',
              ));
        }

        if (settings.name == '/payment_methods_select') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
              builder: (_) => PaymentMethodsSelectScreen(
                driverName:     args['driverName']     ?? 'Ahmed Hassan',
                driverInitials: args['driverInitials'] ?? 'AH',
                price:          (args['price'] as num?)?.toDouble() ?? 240,
              ));
        }

        if (settings.name == '/payment_processing') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
              builder: (_) => PaymentProcessingScreen(
                driverName:     args['driverName']     ?? 'Ahmed Hassan',
                driverInitials: args['driverInitials'] ?? 'AH',
                amount:         (args['amount'] as num?)?.toDouble() ?? 240,
              ));
        }

        if (settings.name == '/trader_delivery_success') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
              builder: (_) => TraderDeliverySuccessScreen(
                shipmentId:     args['shipmentId']     ?? 'TM-000000',
                pickup:         args['pickup']         ?? '',
                dropoff:        args['dropoff']        ?? '',
                driverName:     args['driverName']     ?? '',
                driverInitials: args['driverInitials'] ?? '',
                deliveredAt:    args['deliveredAt']    ?? '',
              ));
        }

        if (settings.name == '/trader_tracking') {
          final shipmentId = settings.arguments as String? ?? '';
          return MaterialPageRoute(
            builder: (_) => TraderShipmentTrackingScreen(
              shipmentId: shipmentId,
            ),
          );
        }

        return null;
      },
    );
  }
}

const _kDummy = TripData(
  id: 'REQ-0000',
  pickup: 'Cairo Distribution Hub',
  dropoff: 'Alexandria Port Terminal',
  distance: '120 km',
  estTime: '2 hr 30 min',
  cargoType: 'General Cargo',
  trader: 'TruckMate Trader',
  price: 240,
);