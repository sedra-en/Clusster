import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/core/constants/app_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class InstructorCourseQuizStatsScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final Color color;

  const InstructorCourseQuizStatsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.color,
  });

  @override
  State<InstructorCourseQuizStatsScreen> createState() =>
      _InstructorCourseQuizStatsScreenState();
}

class _InstructorCourseQuizStatsScreenState
    extends State<InstructorCourseQuizStatsScreen> {
  bool _loading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getCourseQuizStats(widget.courseId);

    if (!mounted) return;

    setState(() {
      _stats = data;
      _loading = false;
    });
  }

  List<dynamic> get _lectures => (_stats['lectures'] as List<dynamic>?) ?? [];

  int get _totalEnrolled => (_stats['total_enrolled'] ?? 0) as int;

  int get _uniqueParticipants => (_stats['unique_participants'] ?? 0) as int;

  int get _lecturesWithQuiz => (_stats['lectures_with_quiz'] ?? 0) as int;

  double get _maxY {
    if (_lectures.isEmpty) return 10;
    final maxVal = _lectures
        .map((l) => (l['students_attempted'] ?? 0) as int)
        .reduce((a, b) => a > b ? a : b);
    return (maxVal * 1.2).ceilToDouble().clamp(5, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child:
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                          onRefresh: _load,
                          child:
                              _lectures.isEmpty
                                  ? _emptyState()
                                  : ListView(
                                    padding: const EdgeInsets.all(20),
                                    children: [
                                      _buildStatsCards(),
                                      const SizedBox(height: 20),
                                      _buildChartCard(),
                                      const SizedBox(height: 20),
                                      _buildLecturesList(),
                                    ],
                                  ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.color, widget.color.withOpacity(0.7)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: const AppIconImage(AppIcons.dashboard, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'quiz_statistics'.tr(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.courseTitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const AppIconImage(AppIcons.business, size: 28),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        _statCard(
          value: _totalEnrolled.toString(),
          label: 'enrolled_students'.tr(),
          icon: AppIcons.community,
          color: widget.color,
        ),
        const SizedBox(width: 10),
        _statCard(
          value: _uniqueParticipants.toString(),
          label: 'solved_quiz'.tr(),
          icon: AppIcons.checkMark,
          color: Colors.green,
        ),
        const SizedBox(width: 10),
        _statCard(
          value: _lecturesWithQuiz.toString(),
          label: 'lectures_with_quiz'.tr(),
          icon: AppIcons.education,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _statCard({
    required String value,
    required String label,
    required String icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.14), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            AppIconImage(icon, size: 26),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconImage(AppIcons.business, size: 20),
              const SizedBox(width: 8),
              Text(
                'students_attempted_quiz'.tr(),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 320,
            child: SfCartesianChart(
              enableAxisAnimation: true,
              zoomPanBehavior: ZoomPanBehavior(
                enablePinching: true,
                enablePanning: true,
                zoomMode: ZoomMode.x,
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                header: '',
                format: 'point.x\npoint.y طالب',
                color: widget.color,
                textStyle: const TextStyle(color: Colors.white),
              ),
              primaryXAxis: CategoryAxis(
                labelRotation: 0,
                majorGridLines: const MajorGridLines(width: 0),
                labelStyle: const TextStyle(fontSize: 10),
              ),
              primaryYAxis: NumericAxis(
                minimum: 0,
                interval: (_maxY / 5).ceilToDouble(),
                majorGridLines: MajorGridLines(
                  width: 1,
                  color: getSecondaryTextColor(context).withOpacity(0.08),
                ),
              ),
              series: <CartesianSeries>[
                ColumnSeries<dynamic, String>(
                  dataSource: _lectures,
                  animationDuration: 1200,
                  xValueMapper: (data, _) => data['lecture_title'] ?? '',
                  yValueMapper:
                      (data, _) =>
                          int.tryParse(
                            data['students_attempted']?.toString() ??
                                data['students_attempted_count']?.toString() ??
                                '0',
                          ) ??
                          0,
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [widget.color, widget.color.withOpacity(0.6)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    labelAlignment: ChartDataLabelAlignment.top,
                    textStyle: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLecturesList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: List.generate(_lectures.length, (i) {
          final l = _lectures[i];
          final count = (l['students_attempted'] ?? 0) as int;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                AppIconImage(AppIcons.book, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text(l['lecture_title'] ?? '')),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$count ${'students'.tr()}",
                    style: TextStyle(color: widget.color),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIconImage(AppIcons.business, size: 80),
          const SizedBox(height: 14),
          Text('no_quiz_attempts_yet'.tr(), style: GoogleFonts.poppins()),
        ],
      ),
    );
  }
}
