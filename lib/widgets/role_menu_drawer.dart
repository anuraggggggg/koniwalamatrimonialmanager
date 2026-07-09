import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';

class RoleMenuItem {
  const RoleMenuItem({
    required this.label,
    required this.icon,
    required this.index,
  });

  final String label;
  final IconData icon;
  final int index;
}

class RoleDrawerMetric {
  const RoleDrawerMetric({required this.value, required this.label});

  final String value;
  final String label;
}

class RoleDrawerTheme {
  const RoleDrawerTheme({
    required this.primaryColor,
    required this.backgroundColor,
    required this.headingColor,
    required this.mutedTextColor,
    required this.selectedItemBgColor,
    required this.softBackgroundColor,
    required this.dividerColor,
    required this.borderColor,
  });

  final Color primaryColor;
  final Color backgroundColor;
  final Color headingColor;
  final Color mutedTextColor;
  final Color selectedItemBgColor;
  final Color softBackgroundColor;
  final Color dividerColor;
  final Color borderColor;

  static const rm = RoleDrawerTheme(
    primaryColor: AppColors.rmPrimary,
    backgroundColor: AppColors.white,
    headingColor: AppColors.rmHeading,
    mutedTextColor: AppColors.rmMutedText,
    selectedItemBgColor: AppColors.selectedNavItemBackgroundColor,
    softBackgroundColor: AppColors.rmSoftPink,
    dividerColor: AppColors.rmDivider,
    borderColor: AppColors.rmPaleRoseBorder,
  );

  static const hr = RoleDrawerTheme(
    primaryColor: AppColors.hrPrimary,
    backgroundColor: AppColors.hrBackground,
    headingColor: AppColors.hrText,
    mutedTextColor: AppColors.hrMuted,
    selectedItemBgColor: Color(0xFFF0DDE4), // Based on HR context
    softBackgroundColor: AppColors.hrBackground,
    dividerColor: AppColors.rmDivider,
    borderColor: AppColors.hrMetricBorder,
  );
}

class RoleMenuDrawer extends StatelessWidget {
  const RoleMenuDrawer({
    super.key,
    required this.userName,
    required this.roleLabel,
    required this.selectedIndex,
    required this.items,
    required this.metrics,
    required this.statusText,
    required this.onItemSelected,
    required this.theme,
    this.onLogout,
  });

  final String userName;
  final String roleLabel;
  final int selectedIndex;
  final List<RoleMenuItem> items;
  final List<RoleDrawerMetric> metrics;
  final String statusText;
  final ValueChanged<int> onItemSelected;
  final RoleDrawerTheme theme;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: theme.backgroundColor,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24.r,
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person_outline,
                      color: theme.primaryColor,
                      size: 26.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: theme.headingColor,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          roleLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  for (final metric in metrics)
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                          right: metric == metrics.last ? 0 : 8.w,
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          color: theme.softBackgroundColor,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: theme.borderColor),
                        ),
                        child: Column(
                          children: [
                            Text(
                              metric.value,
                              style: GoogleFonts.manrope(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w900,
                                color: theme.primaryColor,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              metric.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: theme.mutedTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 18.h),
              Divider(color: theme.dividerColor),
              SizedBox(height: 8.h),
              for (final item in items)
                _RoleMenuTile(
                  item: item,
                  selected: selectedIndex == item.index,
                  theme: theme,
                  onTap: () {
                    Navigator.of(context).maybePop();
                    onItemSelected(item.index);
                  },
                ),
              const Spacer(),
              if (onLogout != null) ...[
                _RoleLogoutButton(
                  onTap: () {
                    Navigator.of(context).maybePop();
                    onLogout!();
                  },
                ),
                SizedBox(height: 12.h),
              ],
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: theme.softBackgroundColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.manrope(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.mutedTextColor,
                    height: 1.35,
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

class _RoleLogoutButton extends StatelessWidget {
  const _RoleLogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.dangerContainer,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.error.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Icon(Icons.logout_outlined, color: AppColors.error, size: 23.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Logout',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleMenuTile extends StatelessWidget {
  const _RoleMenuTile({
    required this.item,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  final RoleMenuItem item;
  final bool selected;
  final RoleDrawerTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? theme.primaryColor : theme.mutedTextColor;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: selected
                ? theme.selectedItemBgColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(item.icon, color: color, size: 23.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 15.sp,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: color,
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
