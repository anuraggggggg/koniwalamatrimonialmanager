import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';

class ProposalsScreen extends StatelessWidget {
  const ProposalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.r, 20.r, 16.r, 16.r),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Proposals',
                          style: GoogleFonts.inter(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.rmPrimary,
                          ),
                        ),
                        Text(
                          '12 Pending Proposals',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.rmMutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.tune, color: AppColors.rmPrimary),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                itemCount: 5,
                separatorBuilder: (context, index) => SizedBox(height: 12.h),
                itemBuilder: (context, index) => _buildProposalCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProposalCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEECAD4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: Image.asset(
                    'assets/wedding_hero 1.png',
                    width: 70.w,
                    height: 70.w,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bhavesh Chaudhary',
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.rmPrimary,
                        ),
                      ),
                      Text(
                        'Sent 2 hours ago • ID: #WA-3762',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: AppColors.rmMutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                _buildStatusPill(
                  'Pending',
                  const Color(0xFFFFF7DE),
                  const Color(0xFFFFA000),
                  const Color(0xFF8B6200),
                ),
                SizedBox(width: 8.w),
                _buildStatusPill(
                  'High Priority',
                  const Color(0xFFFBE0E9),
                  const Color(0xFFD1213E),
                  const Color(0xFFD1213E),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.rmPrimary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'View Details',
                      style: GoogleFonts.inter(
                        color: AppColors.rmPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rmPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Follow Up',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String label, Color bg, Color dot, Color text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8.sp, color: dot),
          SizedBox(width: 4.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}
