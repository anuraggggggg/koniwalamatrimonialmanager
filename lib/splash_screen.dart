import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isInitialized) {
      _checkAuth();
    } else {
      authProvider.addListener(_authListener);
    }
  }

  void _authListener() {
    if (context.read<AuthProvider>().isInitialized) {
      context.read<AuthProvider>().removeListener(_authListener);
      _checkAuth();
    }
  }

  Future<void> _checkAuth() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel?.user;
    
    print('DEBUG: SplashScreen _checkAuth - User Model: ${authProvider.userModel != null}');
    if (user != null) {
      print('DEBUG: SplashScreen _checkAuth - User ID: ${user.id}, Role: ${user.role}');
    }

    if (user != null && user.id.isNotEmpty) {
      final role = user.role.toUpperCase();
      print('DEBUG: SplashScreen - Redirecting to dashboard for role: $role');

      if (role == 'MANAGER') {
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
      } else if (role == 'RELATIONSHIP_MANAGER') {
        Navigator.of(context).pushReplacementNamed(AppRoutes.relationshipManagerDashboard);
      } else if (role == 'ADMIN') {
        Navigator.of(context).pushReplacementNamed(AppRoutes.ownerDashboard);
      } else if (role == 'HR') {
        Navigator.of(context).pushReplacementNamed(AppRoutes.hrDashboard);
      } else if (role == 'DATA' || role == 'DATA_ENTRY') {
        Navigator.of(context).pushReplacementNamed(AppRoutes.dataEntryDashboard);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.plainRole, arguments: user.role);
      }
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/wedding_hero 1.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                children: [
                  // Logo
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Image.asset(
                      'assets/app.logo.png',
                      width: 280.w,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'The Wedding\nArchivist',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    '"Curating timeless matches with the\ndignity of tradition and the grace of\nmodern luxury."',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 48.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '150+',
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 32.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'PALATIAL UNIONS',
                            style: GoogleFonts.manrope(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Elite',
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 32.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'GLOBAL CIRCLES',
                            style: GoogleFonts.manrope(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 48.h),

                  // Next Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 140.w,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Next',
                          style: GoogleFonts.manrope(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
