import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Empty return trips waste\ntime and money',
      'subtitle': 'Connect. Match. Move.',
      'video': 'assets/videos/truck_empty.mp4',
      'icon': Icons.local_shipping_outlined,
    },
    {
      'title': 'Smart matching links trucks\nto suitable shipments',
      'subtitle': 'Connect. Match. Move.',
      'video': 'assets/videos/smart_matching.mp4',
      'icon': Icons.sync_alt_rounded,
    },
    {
      'title': 'With us, your cargo always\nfinds its way',
      'subtitle': 'Connect. Match. Move.',
      'video': 'assets/videos/map_glow.mp4',
      'icon': Icons.map_outlined,
      'isLast': true,
    },
  ];

  final List<VideoPlayerController> _controllers = [];

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    for (var page in _pages) {
      final controller = VideoPlayerController.asset(page['video'] as String);
      _controllers.add(controller);
      controller.initialize().then((_) {
        if (mounted) {
          setState(() {});
          controller.setLooping(true);
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controllers.isNotEmpty && _controllers[0].value.isInitialized) {
        _controllers[0].play();
      }
    });

    _pageController.addListener(() {
      final newIndex = _pageController.page?.round() ?? 0;
      if (newIndex != _currentPage) {
        setState(() => _currentPage = newIndex);
        for (var i = 0; i < _controllers.length; i++) {
          if (i == newIndex) {
            if (_controllers[i].value.isInitialized) _controllers[i].play();
          } else {
            _controllers[i].pause();
            _controllers[i].seekTo(Duration.zero);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.pause();
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('hasSeenOnboarding', true);
      });
      Navigator.pushReplacementNamed(context, '/select_role');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF001A2C),
              Color(0xFF012A3A),
              Color(0xFF011624),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20, top: 12),
                  child: _currentPage < _pages.length - 1
                      ? GestureDetector(
                          onTap: () {
                            SharedPreferences.getInstance().then((prefs) {
                              prefs.setBool('hasSeenOnboarding', true);
                            });
                            Navigator.pushReplacementNamed(context, '/select_role');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D1D1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    const Color(0xFF00D1D1).withOpacity(0.3),
                              ),
                            ),
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                color: Color(0xFF00D1D1),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(height: 36),
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    final controller = _controllers[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Video / Icon container
                          Container(
                            width: double.infinity,
                            height: 230,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF012A3A),
                                  Color(0xFF011624),
                                ],
                              ),
                              border: Border.all(
                                color:
                                    const Color(0xFF00D1D1).withOpacity(0.2),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00D1D1)
                                      .withOpacity(0.15),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: controller.value.isInitialized
                                ? AspectRatio(
                                    aspectRatio:
                                        controller.value.aspectRatio,
                                    child: VideoPlayer(controller),
                                  )
                                : Center(
                                    child: Icon(
                                      page['icon'] as IconData,
                                      size: 80,
                                      color: const Color(0xFF00D1D1)
                                          .withOpacity(0.6),
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 40),

                          Text(
                            page['title']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),

                          const SizedBox(height: 14),

                          Text(
                            page['subtitle']!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Dots
              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: _pages.length,
                  effect: const ExpandingDotsEffect(
                    activeDotColor: Color(0xFF00D1D1),
                    dotColor: Color(0xFF132D3E),
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 4,
                    spacing: 10,
                  ),
                ),
              ),

              // Next / Get Started button
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                child: GestureDetector(
                  onTap: _handleNext,
                  child: Container(
                    width: double.infinity,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF009EA3), Color(0xFF00D1D1)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D1D1).withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage < _pages.length - 1
                              ? 'Next'
                              : 'Get Started',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ],
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