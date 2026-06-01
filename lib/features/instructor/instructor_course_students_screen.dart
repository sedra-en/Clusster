import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';

class InstructorCourseStudentsScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final Color color;

  const InstructorCourseStudentsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.color,
  });

  @override
  State<InstructorCourseStudentsScreen> createState() =>
      _InstructorCourseStudentsScreenState();
}

class _InstructorCourseStudentsScreenState
    extends State<InstructorCourseStudentsScreen> {

  List<dynamic> _students = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final response =
        await ApiService.getCourseStudents(widget.courseId);

    if (!mounted) return;

    setState(() {
      _students = response;
      _loading = false;
    });
  }

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _students;
    final q = _search.toLowerCase();
    return _students.where((s) {
      final name =
          (s['full_name'] ?? '').toString().toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (!_loading && _students.isNotEmpty)
                _buildSearchBar(),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _students.isEmpty
                            ? _emptyState()
                            : _filtered.isEmpty
                                ? Center(
                                    child: Text(
                                      'no_search_results'.tr(),
                                      style: GoogleFonts.poppins(
                                        color: getSecondaryTextColor(context),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding:
                                        const EdgeInsets.fromLTRB(
                                            20, 5, 20, 20),
                                    itemCount: _filtered.length,
                                    itemBuilder: (_, i) =>
                                        _studentCard(
                                            _filtered[i]),
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
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.color,
            widget.color.withOpacity(0.7),
          ],
        ),
        borderRadius:
            const BorderRadius.vertical(
                bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                Navigator.pop(context),
            child: Container(
              padding:
                  const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white
                    .withOpacity(0.2),
                shape:
                    BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'enrolled_students'.tr(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                Text(
                  widget.courseTitle,
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4),
            decoration:
                BoxDecoration(
              color: Colors.white
                  .withOpacity(0.25),
              borderRadius:
                  BorderRadius.circular(
                      10),
            ),
            child: Text(
              "${_students.length}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight:
                    FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
              20, 12, 20, 5),
      child: Container(
        padding:
            const EdgeInsets.symmetric(
                horizontal: 14),
        decoration: BoxDecoration(
          color: getCardColor(context),
          borderRadius:
              BorderRadius.circular(
                  12),
        ),
        child: TextField(
          onChanged: (v) =>
              setState(() => _search = v),
          decoration: InputDecoration(
            hintText:
                'search_by_name_or_id'
                    .tr(),
            border:
                InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Text(
        'no_students_enrolled'.tr(),
        style:
            GoogleFonts.poppins(
          color:
              getSecondaryTextColor(
                  context),
        ),
      ),
    );
  }

  Widget _studentCard(dynamic s) {
    final name = s['full_name'] ?? '';
    final email = s['email'] ?? '';

    return Container(
      margin:
          const EdgeInsets.only(
              bottom: 12),
      padding:
          const EdgeInsets.all(
              14),
      decoration:
          BoxDecoration(
        color:
            getCardColor(context),
        borderRadius:
            BorderRadius.circular(
                14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                widget.color
                    .withOpacity(0.12),
            child: Text(
              name.isNotEmpty
                  ? name[0]
                  : '?',
              style: TextStyle(
                color:
                    widget.color,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style:
                      GoogleFonts
                          .poppins(
                    fontWeight:
                        FontWeight
                            .w600,
                  ),
                ),
                Text(
                  email,
                  style:
                      GoogleFonts
                          .poppins(
                    fontSize: 11,
                    color:
                        getSecondaryTextColor(
                            context),
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