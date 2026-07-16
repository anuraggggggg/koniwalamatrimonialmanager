import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';

class ColorPage extends StatelessWidget {
  const ColorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      appBar: AppBar(
        title: const Text('Color Showcase'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Constant Colors',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            _buildColorGrid('AppColors Constants', [
              ColorSwatch(name: 'Primary', color: AppColors.primary),
              ColorSwatch(name: 'Accent', color: AppColors.accent),
              ColorSwatch(
                name: 'Background Light',
                color: AppColors.backgroundLight,
              ),
              ColorSwatch(
                name: 'Background Dark',
                color: AppColors.backgroundDark,
              ),
              ColorSwatch(name: 'Text Primary', color: AppColors.textPrimary),
              ColorSwatch(
                name: 'Text Secondary',
                color: AppColors.textSecondary,
              ),
              ColorSwatch(name: 'Error', color: AppColors.error),
            ]),
            SizedBox(height: 32.h),
            Text(
              'Dynamic Theme Colors',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            _buildColorGrid('Theme Colors', [
              ColorSwatch(name: 'Primary', color: colorScheme.primary),
              ColorSwatch(name: 'On Primary', color: colorScheme.onPrimary),
              ColorSwatch(
                name: 'Primary Container',
                color: colorScheme.primaryContainer,
              ),
              ColorSwatch(
                name: 'On Primary Container',
                color: colorScheme.onPrimaryContainer,
              ),
              ColorSwatch(name: 'Secondary', color: colorScheme.secondary),
              ColorSwatch(name: 'On Secondary', color: colorScheme.onSecondary),
              ColorSwatch(
                name: 'Secondary Container',
                color: colorScheme.secondaryContainer,
              ),
              ColorSwatch(
                name: 'On Secondary Container',
                color: colorScheme.onSecondaryContainer,
              ),
              ColorSwatch(name: 'Tertiary', color: colorScheme.tertiary),
              ColorSwatch(name: 'On Tertiary', color: colorScheme.onTertiary),
              ColorSwatch(
                name: 'Tertiary Container',
                color: colorScheme.tertiaryContainer,
              ),
              ColorSwatch(
                name: 'On Tertiary Container',
                color: colorScheme.onTertiaryContainer,
              ),
              ColorSwatch(name: 'Surface', color: colorScheme.surface),
              ColorSwatch(name: 'On Surface', color: colorScheme.onSurface),
              ColorSwatch(
                name: 'Surface Variant',
                color: colorScheme.surfaceVariant,
              ),
              ColorSwatch(
                name: 'On Surface Variant',
                color: colorScheme.onSurfaceVariant,
              ),
              ColorSwatch(name: 'Outline', color: colorScheme.outline),
              ColorSwatch(name: 'Shadow', color: colorScheme.shadow),
              ColorSwatch(
                name: 'Inverse Surface',
                color: colorScheme.inverseSurface,
              ),
              ColorSwatch(
                name: 'On Inverse Surface',
                color: colorScheme.onInverseSurface,
              ),
              ColorSwatch(
                name: 'Inverse Primary',
                color: colorScheme.inversePrimary,
              ),
              ColorSwatch(name: 'Error', color: colorScheme.error),
              ColorSwatch(name: 'On Error', color: colorScheme.onError),
              ColorSwatch(
                name: 'Error Container',
                color: colorScheme.errorContainer,
              ),
              ColorSwatch(
                name: 'On Error Container',
                color: colorScheme.onErrorContainer,
              ),
              ColorSwatch(name: 'Background', color: colorScheme.background),
              ColorSwatch(
                name: 'On Background',
                color: colorScheme.onBackground,
              ),
              ColorSwatch(name: 'Surface Tint', color: colorScheme.surfaceTint),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildColorGrid(String title, List<ColorSwatch> swatches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 10.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 8.h,
            childAspectRatio: 1.0,
          ),
          itemCount: swatches.length,
          itemBuilder: (context, index) {
            final swatch = swatches[index];
            return _ColorCard(name: swatch.name, color: swatch.color);
          },
        ),
      ],
    );
  }
}

class ColorSwatch {
  final String name;
  final Color color;
  ColorSwatch({required this.name, required this.color});
}

class _ColorCard extends StatelessWidget {
  final String name;
  final Color color;

  const _ColorCard({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Copied ${name}: Color(${color.value.toRadixString(16).padLeft(8, 'f')})',
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(color: color),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: double.infinity,
                color: Colors.black.withOpacity(0.5),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
