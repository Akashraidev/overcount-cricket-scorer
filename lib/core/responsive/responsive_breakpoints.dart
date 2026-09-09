import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  static const double mobileMax = 600.0;
  static const double tabletMax = 1024.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMax;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobileMax &&
      MediaQuery.sizeOf(context).width <= tabletMax;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width > tabletMax;

  static bool isTabletOrDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobileMax;
}
