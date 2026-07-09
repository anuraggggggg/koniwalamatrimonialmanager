import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/models/holiday_model.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/providers/holiday_provider.dart';
import 'package:provider/provider.dart';

class HolidayManagementScreen extends StatefulWidget {
  const HolidayManagementScreen({super.key});

  @override
  State<HolidayManagementScreen> createState() =>
      _HolidayManagementScreenState();
}

class _HolidayManagementScreenState extends State<HolidayManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _searchController;
  late int _selectedYear;
  late int _selectedMonth;
  DateTime? _selectedDate;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _selectedDate = DateTime(now.year, now.month, now.day);
    _tabController = TabController(length: 2, vsync: this);
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final holidayProvider = Provider.of<HolidayProvider>(
        context,
        listen: false,
      );
      holidayProvider.fetchHolidays(
        _selectedYear,
        authProvider.userModel?.accessToken ?? '',
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<HolidayModel> _visibleHolidays(List<HolidayModel> holidays) {
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? holidays.toList()
        : holidays.where((holiday) {
            final formattedDate = _formatFullDate(holiday.date).toLowerCase();
            return holiday.name.toLowerCase().contains(query) ||
                holiday.type.toLowerCase().contains(query) ||
                holiday.description.toLowerCase().contains(query) ||
                formattedDate.contains(query);
          }).toList();

    filtered.sort((left, right) => left.date.compareTo(right.date));
    return filtered;
  }

  List<HolidayModel> _holidaysForSelectedMonth(List<HolidayModel> holidays) {
    return holidays.where((holiday) {
      return holiday.date.year == _selectedYear &&
          holiday.date.month == _selectedMonth;
    }).toList();
  }

  List<HolidayModel> _holidaysForSelectedDate(List<HolidayModel> holidays) {
    final selectedDate = _selectedDate;
    if (selectedDate == null) {
      return const [];
    }

    return holidays
        .where((holiday) => _isSameDate(holiday.date, selectedDate))
        .toList();
  }

  bool _isMandatoryType(String type) {
    final normalized = type.trim().toLowerCase();
    return normalized.contains('mandatory') ||
        normalized.contains('national') ||
        normalized.contains('gazetted');
  }

  bool _isOptionalType(String type) {
    final normalized = type.trim().toLowerCase();
    return normalized.contains('optional') ||
        normalized.contains('floating') ||
        normalized.contains('restricted');
  }

  bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  void _changeMonth(int delta) {
    final currentYear = _selectedYear;
    final nextMonthDate = DateTime(_selectedYear, _selectedMonth + delta, 1);
    setState(() {
      _selectedYear = nextMonthDate.year;
      _selectedMonth = nextMonthDate.month;
      _selectedDate = DateTime(nextMonthDate.year, nextMonthDate.month, 1);
    });

    if (nextMonthDate.year != currentYear) {
      final accessToken = context.read<AuthProvider>().userModel?.accessToken;
      context.read<HolidayProvider>().fetchHolidays(
        nextMonthDate.year,
        accessToken ?? '',
      );
    }
  }

  void _selectYear(int year) {
    if (year == _selectedYear) {
      return;
    }

    setState(() {
      _selectedYear = year;
      _selectedDate = DateTime(year, _selectedMonth, 1);
    });

    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    context.read<HolidayProvider>().fetchHolidays(year, accessToken ?? '');
  }

  void _selectCalendarDate(DateTime date) {
    final currentYear = _selectedYear;
    setState(() {
      _selectedYear = date.year;
      _selectedMonth = date.month;
      _selectedDate = DateTime(date.year, date.month, date.day);
    });

    if (date.year != currentYear) {
      final accessToken = context.read<AuthProvider>().userModel?.accessToken;
      context.read<HolidayProvider>().fetchHolidays(
        date.year,
        accessToken ?? '',
      );
    }
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  String _shortMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  String _formatFullDate(DateTime date) {
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  String _formatShortDate(DateTime date) {
    return '${_shortMonthName(date.month)} ${date.day}';
  }

  String _weekdayName(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[(date.weekday - 1).clamp(0, 6)];
  }

  List<int> _calendarYears() {
    final currentYear = DateTime.now().year;
    if (_selectedYear >= currentYear) {
      return [currentYear - 1, _selectedYear];
    }
    return [_selectedYear, _selectedYear + 1];
  }

  String _holidayTypeLabel(HolidayModel holiday) {
    if (holiday.isHalfDay) {
      return 'Half-day';
    }
    if (_isMandatoryType(holiday.type)) {
      return 'Mandatory';
    }
    if (_isOptionalType(holiday.type)) {
      return 'Optional';
    }
    return holiday.type.trim().isEmpty ? 'Holiday' : holiday.type;
  }

  Color _holidayAccent(HolidayModel holiday) {
    if (holiday.isHalfDay) {
      return const Color(0xFF444444);
    }
    if (_isMandatoryType(holiday.type)) {
      return const Color(0xFFD12C3F);
    }
    if (_isOptionalType(holiday.type)) {
      return const Color(0xFFD1A300);
    }
    return AppColors.rmPrimary;
  }

  IconData _holidayIcon(HolidayModel holiday) {
    if (holiday.isHalfDay) {
      return Icons.pie_chart_rounded;
    }
    if (_isMandatoryType(holiday.type)) {
      return Icons.event_busy_outlined;
    }
    if (_isOptionalType(holiday.type)) {
      return Icons.beach_access_outlined;
    }
    return Icons.calendar_month_outlined;
  }

  Future<void> _showAddHolidayDialog() async {
    final initialDate =
        _selectedDate ?? DateTime(_selectedYear, _selectedMonth, 1);
    final holiday = await showDialog<_HolidayDraft>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (context) => _AddHolidayDialog(initialDate: initialDate),
    );

    if (holiday == null || !mounted) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final holidayProvider = context.read<HolidayProvider>();
    final token = authProvider.userModel?.accessToken ?? '';

    if (_hasMatchingHoliday(holidayProvider.holidays, holiday)) {
      _showHolidayMessage(
        'Holiday already exists for this date.',
        isError: true,
      );
      return;
    }

    final error = await holidayProvider.createHoliday(
      token: token,
      name: holiday.name,
      date: holiday.date,
      type: holiday.type,
      isHalfDay: holiday.isHalfDay,
      description: holiday.description,
    );

    if (!mounted) {
      return;
    }

    if (error != null) {
      _showHolidayMessage(_holidayErrorMessage(error), isError: true);
      return;
    }

    if (holiday.date.year != _selectedYear) {
      setState(() {
        _selectedYear = holiday.date.year;
        _selectedMonth = holiday.date.month;
        _selectedDate = holiday.date;
      });
      await holidayProvider.fetchHolidays(_selectedYear, token);
      if (!mounted) {
        return;
      }
    }

    _showHolidayMessage('${holiday.name} has been created.');
  }

  bool _hasMatchingHoliday(
    List<HolidayModel> holidays,
    _HolidayDraft holiday,
  ) {
    final normalizedName = holiday.name.trim().toLowerCase();
    final normalizedType = holiday.type.trim().toLowerCase();
    return holidays.any((item) {
      return _isSameDate(item.date, holiday.date) &&
          item.name.trim().toLowerCase() == normalizedName &&
          item.type.trim().toLowerCase() == normalizedType;
    });
  }

  String _holidayErrorMessage(String error) {
    final normalized = error.toLowerCase();
    if (normalized.contains('already') ||
        normalized.contains('duplicate') ||
        normalized.contains('unique') ||
        normalized.contains('exists')) {
      return 'Holiday already exists for this date.';
    }
    if (normalized.contains('date')) {
      return 'Choose a valid holiday date.';
    }
    if (normalized.contains('name') || normalized.contains('designation')) {
      return 'Enter a holiday name.';
    }
    if (normalized.contains('authorization') || normalized.contains('token')) {
      return 'Please log in again to add holidays.';
    }
    return 'Unable to add holiday. Please check the details.';
  }

  void _showHolidayMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: isError ? AppColors.error : AppColors.rmPrimary,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      body: SafeArea(
        child: Consumer<HolidayProvider>(
          builder: (context, provider, _) {
            final holidays = provider.holidays;
            final visibleHolidays = _visibleHolidays(holidays);
            final monthHolidays = _holidaysForSelectedMonth(holidays);
            final selectedDateHolidays = _holidaysForSelectedDate(holidays);
            final mandatoryCount = holidays
                .where((holiday) => _isMandatoryType(holiday.type))
                .length;
            final optionalCount = holidays
                .where((holiday) => _isOptionalType(holiday.type))
                .length;
            final halfDayCount = holidays
                .where((holiday) => holiday.isHalfDay)
                .length;

            return NestedScrollView(
              physics: const ClampingScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Holiday Management',
                                      style: GoogleFonts.manrope(
                                        fontSize: 30.sp,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.rmPrimary,
                                        height: 1.08,
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      'Configure and manage organization-wide\nholidays and calendar events.',
                                      style: GoogleFonts.manrope(
                                        color: const Color(0xFF726972),
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w500,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (Navigator.of(context).canPop())
                                Container(
                                  width: 42.r,
                                  height: 42.r,
                                  margin: EdgeInsets.only(left: 8.w, top: 2.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.rmPaleRoseBorder,
                                    ),
                                  ),
                                  child: IconButton(
                                    tooltip: 'Back',
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    visualDensity: VisualDensity.compact,
                                    icon: Icon(
                                      Icons.arrow_back,
                                      color: AppColors.rmPrimary,
                                      size: 18.sp,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: Container(
                                  constraints: BoxConstraints(minHeight: 54.h),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(24.r),
                                    border: Border.all(
                                      color: AppColors.rmPaleRoseBorder,
                                    ),
                                  ),
                                  child: TabBar(
                                    controller: _tabController,
                                    tabAlignment: TabAlignment.fill,
                                    dividerColor: Colors.transparent,
                                    indicator: BoxDecoration(
                                      color: const Color(0xFFF6E2EA),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    indicatorColor: Colors.transparent,
                                    labelColor: AppColors.rmPrimary,
                                    unselectedLabelColor: const Color(
                                      0xFF7E737B,
                                    ),
                                    labelStyle: GoogleFonts.manrope(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    unselectedLabelStyle: GoogleFonts.manrope(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    tabs: const [
                                      Tab(text: 'Calendar'),
                                      Tab(text: 'List View'),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                flex: 5,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minHeight: 52.h),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _showAddHolidayDialog();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.rmPrimary,
                                      foregroundColor: AppColors.white,
                                      elevation: 0,
                                      minimumSize: Size.fromHeight(52.h),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          24.r,
                                        ),
                                      ),
                                    ),
                                    icon: Icon(Icons.add, size: 18.sp),
                                    label: Text(
                                      'Add Holiday',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.manrope(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                          child: Container(
                            height: 52.h,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: AppColors.rmPaleRoseBorder,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) =>
                                  setState(() => _query = value),
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                hintText: 'Search holidays by name...',
                                isDense: true,
                                hintStyle: GoogleFonts.manrope(
                                  color: const Color(0xFFAAA1A8),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: const Color(0xFF8A7B84),
                                  size: 22.sp,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12.h,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 10.h),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _HolidayInsightCard(
                                      title: 'Total Holidays',
                                      value: '${holidays.length}',
                                      subtitle: holidays.isEmpty
                                          ? 'No entries yet'
                                          : '${holidays.length} events this year',
                                      icon: Icons.calendar_month_outlined,
                                      iconColor: AppColors.rmPrimary,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: _HolidayInsightCard(
                                      title: 'Mandatory',
                                      value: '$mandatoryCount',
                                      subtitle: 'Required attendance',
                                      icon: Icons.event_busy_outlined,
                                      iconColor: const Color(0xFFD12C3F),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: _HolidayInsightCard(
                                      title: 'Optional',
                                      value: '$optionalCount',
                                      subtitle: 'Floating holidays',
                                      icon: Icons.beach_access_outlined,
                                      iconColor: const Color(0xFFD1A300),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: _HolidayInsightCard(
                                      title: 'Half-days',
                                      value: '$halfDayCount',
                                      subtitle: 'Partial leave units',
                                      icon: Icons.pie_chart_rounded,
                                      iconColor: const Color(0xFF444444),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ];
              },
              body: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCalendarView(
                          monthHolidays: monthHolidays,
                          selectedDateHolidays: selectedDateHolidays,
                        ),
                        _buildListView(visibleHolidays),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCalendarView({
    required List<HolidayModel> monthHolidays,
    required List<HolidayModel> selectedDateHolidays,
  }) {
    final firstDayOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
    final firstWeekdayIndex = firstDayOfMonth.weekday % 7;
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    final previousMonthDays = DateTime(_selectedYear, _selectedMonth, 0).day;
    final totalCells = ((firstWeekdayIndex + daysInMonth) / 7).ceil() * 7;
    final selectedDate = _selectedDate ?? firstDayOfMonth;
    final yearTabs = _calendarYears();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.rmPaleRoseBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    for (int index = 0; index < yearTabs.length; index++) ...[
                      _CalendarYearTab(
                        year: yearTabs[index],
                        selected: yearTabs[index] == _selectedYear,
                        onTap: () => _selectYear(yearTabs[index]),
                      ),
                      if (index != yearTabs.length - 1) SizedBox(width: 22.w),
                    ],
                  ],
                ),
                SizedBox(height: 10.h),
                Divider(
                  color: AppColors.rmPaleRoseBorder,
                  thickness: 1,
                  height: 1,
                ),
                SizedBox(height: 18.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Previous month',
                      onPressed: () => _changeMonth(-1),
                      icon: Icon(
                        Icons.chevron_left,
                        color: AppColors.rmPrimary,
                        size: 24.sp,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${_monthName(_selectedMonth).toUpperCase()} $_selectedYear',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 19.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.rmPrimary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next month',
                      onPressed: () => _changeMonth(1),
                      icon: Icon(
                        Icons.chevron_right,
                        color: AppColors.rmPrimary,
                        size: 24.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                Row(
                  children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                      .map(
                        (day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                color: Color(0xFF8A7B84),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: 16.h),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalCells,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 12.h,
                    crossAxisSpacing: 2.w,
                    mainAxisExtent: 52.h,
                  ),
                  itemBuilder: (context, index) {
                    late final DateTime currentDate;
                    late final int day;
                    final isCurrentMonth =
                        index >= firstWeekdayIndex &&
                        index < firstWeekdayIndex + daysInMonth;

                    if (!isCurrentMonth && index < firstWeekdayIndex) {
                      day = previousMonthDays - firstWeekdayIndex + index + 1;
                      currentDate = DateTime(
                        _selectedYear,
                        _selectedMonth - 1,
                        day,
                      );
                    } else if (!isCurrentMonth) {
                      day = index - (firstWeekdayIndex + daysInMonth) + 1;
                      currentDate = DateTime(
                        _selectedYear,
                        _selectedMonth + 1,
                        day,
                      );
                    } else {
                      day = index - firstWeekdayIndex + 1;
                      currentDate = DateTime(
                        _selectedYear,
                        _selectedMonth,
                        day,
                      );
                    }

                    HolidayModel? holiday;
                    if (isCurrentMonth) {
                      for (final item in monthHolidays) {
                        if (_isSameDate(item.date, currentDate)) {
                          holiday = item;
                          break;
                        }
                      }
                    }

                    final isSelected = _isSameDate(currentDate, selectedDate);
                    final isHoliday = holiday != null;
                    final isHalfDay = holiday?.isHalfDay ?? false;
                    final markerColor = isHalfDay
                        ? const Color(0xFFF0A225)
                        : const Color(0xFFE3262E);
                    final numberColor = isSelected
                        ? AppColors.white
                        : isCurrentMonth
                        ? AppColors.rmHeading
                        : const Color(0xFFA89DA5);

                    return InkWell(
                      borderRadius: BorderRadius.circular(20.r),
                      onTap: () => _selectCalendarDate(currentDate),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 34.r,
                            height: 34.r,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.rmPrimary
                                  : isHoliday && !isHalfDay
                                  ? const Color(0xFFF8EAF0)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$day',
                              style: GoogleFonts.manrope(
                                color: numberColor,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          SizedBox(
                            height: 6.h,
                            child: isHoliday
                                ? Container(
                                    width: 6.r,
                                    height: 6.r,
                                    decoration: BoxDecoration(
                                      color: markerColor,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 18.h),
                Divider(
                  color: AppColors.rmPaleRoseBorder,
                  thickness: 1,
                  height: 1,
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegend(
                      color: const Color(0xFFE3262E),
                      label: 'Holiday',
                    ),
                    SizedBox(width: 22.w),
                    _buildLegend(
                      color: const Color(0xFFF0A225),
                      label: 'Half-day',
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 18.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.rmPaleRoseBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _weekdayName(selectedDate).toUpperCase(),
                            style: GoogleFonts.manrope(
                              color: AppColors.rmPrimary,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            _formatFullDate(selectedDate),
                            style: GoogleFonts.manrope(
                              color: AppColors.rmHeading,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6E2EA),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        tooltip: 'Add holiday',
                        onPressed: () {
                          _showAddHolidayDialog();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.add,
                          color: AppColors.rmPrimary,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Divider(
                  color: AppColors.rmPaleRoseBorder,
                  thickness: 1,
                  height: 1,
                ),
                SizedBox(height: 18.h),
                if (selectedDateHolidays.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 34.r,
                          height: 34.r,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6E2EA),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.work_history_outlined,
                            color: const Color(0xFFD79AB6),
                            size: 18.sp,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No archival entries for this date.\nClick to provision a new holiday.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            color: const Color(0xFFA39AA0),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      for (
                        int index = 0;
                        index < selectedDateHolidays.length;
                        index++
                      ) ...[
                        if (index > 0) SizedBox(height: 12.h),
                        _CalendarHolidayRow(
                          holiday: selectedDateHolidays[index],
                          accent: selectedDateHolidays[index].isHalfDay
                              ? const Color(0xFFF0A225)
                              : const Color(0xFFE3262E),
                          icon: _holidayIcon(selectedDateHolidays[index]),
                          typeLabel: _holidayTypeLabel(
                            selectedDateHolidays[index],
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<HolidayModel> holidays) {
    if (holidays.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Text(
            _query.isEmpty
                ? 'No holidays are available right now.'
                : 'No holidays match "$_query".',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: AppColors.rmMutedText,
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
      itemCount: holidays.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final holiday = holidays[index];
        final accent = _holidayAccent(holiday);
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: AppColors.rmPaleRoseBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 42.r,
                height: 42.r,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(_holidayIcon(holiday), color: accent, size: 20.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      holiday.name,
                      style: GoogleFonts.manrope(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.rmHeading,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${_holidayTypeLabel(holiday)} - ${_formatFullDate(holiday.date)}',
                      style: GoogleFonts.manrope(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.rmMutedText,
                      ),
                    ),
                    if (holiday.description.trim().isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text(
                        holiday.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6A5F66),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                _formatShortDate(holiday.date),
                style: GoogleFonts.manrope(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.r,
          height: 8.r,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8.w),
        Text(
          label,
          style: GoogleFonts.manrope(
            color: AppColors.rmHeading,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CalendarYearTab extends StatelessWidget {
  const _CalendarYearTab({
    required this.year,
    required this.selected,
    required this.onTap,
  });

  final int year;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.fromLTRB(8.w, 2.h, 8.w, 8.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.rmPrimary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          '$year',
          style: GoogleFonts.manrope(
            color: selected ? AppColors.rmPrimary : const Color(0xFF8F858C),
            fontSize: 15.sp,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _HolidayInsightCard extends StatelessWidget {
  const _HolidayInsightCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6D6169),
                  ),
                ),
              ),
              Icon(icon, color: iconColor, size: 18.sp),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 34.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.rmHeading,
              height: 1,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: GoogleFonts.manrope(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7B7078),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarHolidayRow extends StatelessWidget {
  const _CalendarHolidayRow({
    required this.holiday,
    required this.accent,
    required this.icon,
    required this.typeLabel,
  });

  final HolidayModel holiday;
  final Color accent;
  final IconData icon;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6F7),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holiday.name,
                  style: GoogleFonts.manrope(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.rmHeading,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  typeLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HolidayDraft {
  const _HolidayDraft({
    required this.name,
    required this.date,
    required this.type,
    required this.isHalfDay,
    required this.description,
  });

  final String name;
  final DateTime date;
  final String type;
  final bool isHalfDay;
  final String description;
}

class _AddHolidayDialog extends StatefulWidget {
  const _AddHolidayDialog({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_AddHolidayDialog> createState() => _AddHolidayDialogState();
}

class _AddHolidayDialogState extends State<_AddHolidayDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _selectedDate;
  String _selectedType = 'Mandatory';
  bool _isHalfDay = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDialogDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.rmPrimary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) {
      return;
    }

    setState(() => _selectedDate = pickedDate);
  }

  void _confirmHoliday() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Holiday designation is required.');
      return;
    }

    Navigator.of(context, rootNavigator: true).pop(
      _HolidayDraft(
        name: name,
        date: _selectedDate,
        type: _selectedType,
        isHalfDay: _isHalfDay,
        description: _descriptionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 24.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 268.w),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 26.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22.r,
                      height: 22.r,
                      margin: EdgeInsets.only(top: 3.h),
                      decoration: const BoxDecoration(
                        color: AppColors.rmPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.calendar_month,
                        color: AppColors.white,
                        size: 13.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INSTITUTIONAL CALENDAR',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              color: AppColors.rmPrimary,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            'Create New Holiday',
                            style: GoogleFonts.manrope(
                              color: AppColors.rmHeading,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Set up a new organization-wide\nholiday event in the registry.',
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF6F6670),
                              fontSize: 11.sp,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(999.r),
                      onTap: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Icon(
                          Icons.close,
                          color: const Color(0xFF6B626A),
                          size: 18.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                _DialogLabel('Holiday Designation'),
                SizedBox(height: 8.h),
                _DialogTextField(
                  controller: _nameController,
                  hintText: 'e.g. Diwali Observance',
                ),
                SizedBox(height: 18.h),
                _DialogLabel('Registry Date'),
                SizedBox(height: 8.h),
                InkWell(
                  borderRadius: BorderRadius.circular(5.r),
                  onTap: _pickDate,
                  child: Container(
                    height: 36.h,
                    padding: EdgeInsets.symmetric(horizontal: 11.w),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: const Color(0xFFE0DDE2)),
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: const Color(0xFF6F6670),
                          size: 15.sp,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          _formatDialogDate(_selectedDate),
                          style: GoogleFonts.manrope(
                            color: AppColors.rmHeading,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                _DialogLabel('Categorization'),
                SizedBox(height: 8.h),
                Container(
                  height: 36.h,
                  padding: EdgeInsets.symmetric(horizontal: 11.w),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: const Color(0xFFE0DDE2)),
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedType,
                      isExpanded: true,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF6F6670),
                        size: 18.sp,
                      ),
                      style: GoogleFonts.manrope(
                        color: AppColors.rmHeading,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Mandatory',
                          child: Text('Mandatory'),
                        ),
                        DropdownMenuItem(
                          value: 'Optional',
                          child: Text('Optional'),
                        ),
                        DropdownMenuItem(
                          value: 'Floating',
                          child: Text('Floating'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedType = value);
                      },
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                InkWell(
                  borderRadius: BorderRadius.circular(6.r),
                  onTap: () => setState(() => _isHalfDay = !_isHalfDay),
                  child: Container(
                    height: 40.h,
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEF4),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18.r,
                          height: 18.r,
                          child: Checkbox(
                            value: _isHalfDay,
                            onChanged: (value) {
                              setState(() => _isHalfDay = value ?? false);
                            },
                            activeColor: AppColors.rmPrimary,
                            side: const BorderSide(
                              color: AppColors.rmPrimary,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3.r),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            'This is a Half-Day Holiday',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              color: AppColors.rmPrimary,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                _DialogLabel('Description & Context'),
                SizedBox(height: 8.h),
                _DialogTextField(
                  controller: _descriptionController,
                  hintText: 'Additional archival notes for employees...',
                  minLines: 4,
                  maxLines: 4,
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(top: 14.h),
                    child: Text(
                      _errorMessage!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: AppColors.error,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                SizedBox(height: 34.h),
                SizedBox(
                  width: double.infinity,
                  height: 34.h,
                  child: ElevatedButton(
                    onPressed: _confirmHoliday,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rmPrimary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Confirm Holiday',
                      style: GoogleFonts.manrope(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Center(
                  child: TextButton(
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                    child: Text(
                      'Discard changes',
                      style: GoogleFonts.manrope(
                        color: AppColors.rmPrimary,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogLabel extends StatelessWidget {
  const _DialogLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        color: const Color(0xFF4F4750),
        fontSize: 11.sp,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _DialogTextField extends StatelessWidget {
  const _DialogTextField({
    required this.controller,
    required this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: GoogleFonts.manrope(
        color: AppColors.rmHeading,
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.manrope(
          color: const Color(0xFFA99CA5),
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.white,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5.r),
          borderSide: const BorderSide(color: Color(0xFFE0DDE2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5.r),
          borderSide: const BorderSide(color: AppColors.rmPrimary),
        ),
      ),
    );
  }
}
