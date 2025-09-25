import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomSplashScreen extends StatefulWidget {
  const CustomSplashScreen({super.key});

  @override
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    // Navigate to home after splash display (shortened delay)
    Future.delayed(const Duration(milliseconds: 1000), () {
      print('🚀 Splash timer expired - attempting navigation to /home');
      if (mounted) {
        print('🚀 Widget is mounted - navigating to /home');
        try {
          context.go('/home');
          print('🚀 Navigation to /home completed');
        } catch (e) {
          print('❌ Navigation failed: $e');
          // Fallback: try different navigation method
          context.pushReplacement('/home');
        }
      } else {
        print('❌ Widget not mounted - skipping navigation');
      }
    });
    
    // Backup timer in case first one fails
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        print('🆘 Backup timer - forcing navigation to /home');
        try {
          context.pushReplacement('/home');
        } catch (e) {
          print('❌ Backup navigation also failed: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('💦 CustomSplashScreen build called');
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Image.asset(
            'assets/splash_logo.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Failed to load splash logo: $error');
              // Simple fallback
              return Container(
                color: Theme.of(context).colorScheme.primary,
                child: Center(
                  child: Text(
                    'SportEve',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
