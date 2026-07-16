import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';

class KoniwalaPrimaryAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const KoniwalaPrimaryAppBar({
    super.key,
    this.showMenuButton = false,
    this.onMenuPressed,
    this.onAddPressed,
    this.onNotificationPressed,
    this.showActions = true,
  });

  final bool showMenuButton;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onAddPressed;
  final VoidCallback? onNotificationPressed;
  final bool showActions;

  @override
  Size get preferredSize => Size.fromHeight(70.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 70.h,
      backgroundColor: AppColors.primary,
      surfaceTintColor: AppColors.primary,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leadingWidth: showMenuButton ? 56.w : null,

      leading: showMenuButton
          ? Builder(
              builder: (context) => IconButton(
                tooltip: 'Menu',
                onPressed:
                    onMenuPressed ??
                    () => Scaffold.maybeOf(context)?.openDrawer(),
                icon: const Icon(Icons.menu, color: Colors.white),
              ),
            )
          : null,
      title: null,
      flexibleSpace: SafeArea(
        child: IgnorePointer(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(
                left: showMenuButton ? 56.w : 0,
                right: 20.w,
              ),
              child: Image.asset(
                'assets/app.logo.png',
                height: 51.h,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      actions: showActions
          ? [
              IconButton(
                tooltip: 'Add',
                onPressed: onAddPressed ?? () {},
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: 44.w, height: 44.h),
                icon: Image.asset(
                  'assets/Add_Plus_Circle.png',
                  height: 20.h,
                  width: 20.w,
                ),
              ),
              IconButton(
                tooltip: 'Notifications',
                onPressed:
                    onNotificationPressed ??
                    () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.notifications),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: 48.w, height: 44.h),
                icon: Image.asset(
                  'assets/notification_icon.png',
                  height: 35.h,
                  width: 35.w,
                ),
              ),
              SizedBox(width: 8.w),
            ]
          : null,
    );
  }
}
