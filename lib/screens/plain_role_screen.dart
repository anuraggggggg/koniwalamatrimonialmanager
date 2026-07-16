import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';

class PlainRoleScreen extends StatelessWidget {
  final String roleName;

  const PlainRoleScreen({super.key, required this.roleName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      appBar: AppBar(
        title: const Text('Access Restricted'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_person_outlined,
              size: 80.sp,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Your logged in role is:',
              style: TextStyle(fontSize: 18.sp, color: const Color(0xFF1E1F1F)),
            ),
            const SizedBox(height: 8),
            Text(
              roleName,
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 48),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed('/login'),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
