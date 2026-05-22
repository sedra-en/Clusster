import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/features/student/course_details_screen.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final courses = [
      {"title": 'dart_flutter'.tr(), "color": AppColors.primary},
      {"title": 'ui_ux_design'.tr(), "color": AppColors.purple},
      {"title": 'data_science'.tr(), "color": AppColors.orange},
      {"title": 'cyber_security'.tr(), "color": AppColors.darkBlue},
    ];

    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: getTextColor(context)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text('my_courses'.tr(),
                      style: GoogleFonts.poppins(color: getTextColor(context), fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return FadeInSlide(
                    delay: index * 0.1,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: getCardColor(context),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: (course["color"] as Color).withOpacity(0.3)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (course["color"] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(Icons.book_rounded, color: course["color"] as Color, size: 28),
                        ),
                        title: Text(course["title"] as String,
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: getTextColor(context))),
                        subtitle: Text('tap_to_view'.tr(),
                            style: GoogleFonts.poppins(fontSize: 12, color: getSecondaryTextColor(context))),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: getSecondaryTextColor(context)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourseDetailsScreen(
                                title: course["title"] as String,
                                color: course["color"] as Color,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}