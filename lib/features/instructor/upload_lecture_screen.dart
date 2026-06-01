import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/features/instructor/instructor_lecture_ai_view_screen.dart';

class UploadLectureScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final Color color;

  const UploadLectureScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.color,
  });

  @override
  State<UploadLectureScreen> createState() =>
      _UploadLectureScreenState();
}

class _UploadLectureScreenState
    extends State<UploadLectureScreen> {

  final _titleController = TextEditingController();

  PlatformFile? _pickedFile;
  PlatformFile? _pickedAudio;

  bool _isUploading  = false;
  bool _isGenerating = false;

  // ⭐ بعد الحفظ نحتفظ بـ lectureId لتوليد الملخص لاحقاً
  String? _savedLectureId;
  String? _savedLectureTitle;

  // ─── Pick Files ───────────────────────────────────────────

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'ogg', 'wav', 'm4a', 'aac'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedAudio = result.files.first);
    }
  }

  // ─── Validate ─────────────────────────────────────────────

  bool _validate() {
    if (_titleController.text.trim().isEmpty) {
      _snack('please_enter_title'.tr());
      return false;
    }
    if (_pickedFile == null && _pickedAudio == null) {
      _snack('please_upload_first'.tr());
      return false;
    }
    return true;
  }

  // ─── Step 1: حفظ المحاضرة فقط ────────────────────────────

  Future<void> _handleSave() async {
    if (!_validate()) return;

    setState(() => _isUploading = true);

    final upRes = await ApiService.uploadLecture(
      courseId:   widget.courseId,
      title:      _titleController.text.trim(),
      fileBytes:  _pickedFile?.bytes?.toList(),
      fileName:   _pickedFile?.name,
      audioBytes: _pickedAudio?.bytes?.toList(),
      audioName:  _pickedAudio?.name,
    );

    if (!mounted) return;
    setState(() => _isUploading = false);

    if (upRes['status'] == 'success') {
      setState(() {
        _savedLectureId    = upRes['data']['lecture_id'].toString();
        _savedLectureTitle = _titleController.text.trim();
      });
      _snack('lecture_saved_successfully'.tr());
    } else {
      _snack(upRes['message'] ?? 'upload_failed'.tr());
    }
  }

  // ─── Step 2: توليد الملخص الذكي (بعد الحفظ) ─────────────

  Future<void> _handleGenerateAI() async {
    if (_savedLectureId == null) return;

    setState(() => _isGenerating = true);

    final aiRes = await ApiService.generateAIContent(_savedLectureId!);

    if (!mounted) return;
    setState(() => _isGenerating = false);

    if (aiRes['status'] == 'success') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => InstructorLectureAIViewScreen(
            lectureId:    _savedLectureId!,
            lectureTitle: _savedLectureTitle ?? '',
            color:        widget.color,
          ),
        ),
      );
    } else {
      _snack(aiRes['message'] ?? 'upload_done_ai_failed'.tr());
    }
  }

  // ─── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isSaved      = _savedLectureId != null;
    final isProcessing = _isUploading || _isGenerating;

    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [

                  // ─── حقول الإدخال (تختفي بعد الحفظ)
                  if (!isSaved) ...[
                    _buildFieldCard(),
                    const SizedBox(height: 18),
                    _buildUploadSection(),
                    const SizedBox(height: 22),
                  ],

                  // ─── مؤشر التحميل
                  if (isProcessing) ...[
                    _buildProgressCard(),
                    const SizedBox(height: 16),
                  ],

                  // ─── قبل الحفظ: زر "حفظ المحاضرة"
                  if (!isSaved && !isProcessing)
                    _buildSaveBtn(),

                  // ─── بعد الحفظ: بطاقة نجاح + زر توليد AI
                  if (isSaved && !isProcessing) ...[
                    _buildSuccessCard(),
                    const SizedBox(height: 16),
                    _buildGenerateBtn(),
                    const SizedBox(height: 12),
                    _buildBackBtn(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Widgets ──────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.color, widget.color.withOpacity(0.7)],
        ),
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'upload_lecture'.tr(),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(widget.courseTitle,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCard() {
    return Container(
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: widget.color.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _titleController,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.title, color: widget.color),
          hintText: 'lecture_title'.tr(),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Column(
      children: [
        _uploadTile(
          icon: Icons.picture_as_pdf,
          iconColor: Colors.red,
          label: _pickedFile != null
              ? _pickedFile!.name
              : 'upload_content'.tr(),
          onTap: _pickFile,
          actionLabel:
              _pickedFile != null ? 'change'.tr() : 'browse'.tr(),
        ),
        const SizedBox(height: 10),
        _uploadTile(
          icon: Icons.mic_rounded,
          iconColor: widget.color,
          label: _pickedAudio != null
              ? _pickedAudio!.name
              : 'upload_audio'.tr(),
          onTap: _pickAudio,
          actionLabel:
              _pickedAudio != null ? 'change'.tr() : 'browse'.tr(),
        ),
      ],
    );
  }

  Widget _uploadTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    required String actionLabel,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: widget.color.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(label,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.color,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(actionLabel,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: widget.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                color: widget.color, strokeWidth: 2.5),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _isUploading
                  ? 'uploading_file'.tr()
                  : 'generating_ai_content'.tr(),
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ بطاقة نجاح الحفظ
  Widget _buildSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.green, size: 52),
          const SizedBox(height: 12),
          Text(
            'lecture_saved_successfully'.tr(),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _savedLectureTitle ?? '',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.green.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'lecture_visible_to_students'.tr(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.green.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ✅ زر توليد الملخص الذكي
  Widget _buildGenerateBtn() {
    return ScaleButton(
      onTap: _handleGenerateAI,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.color, widget.color.withOpacity(0.75)],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'generate_ai_content'.tr(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ زر الرجوع (اختياري بعد الحفظ)
  Widget _buildBackBtn() {
    return ScaleButton(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: Colors.grey.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_back_rounded,
                color: Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(
              'back_to_lectures'.tr(),
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── زر الحفظ الرئيسي ─────────────────────────────────────

  Widget _buildSaveBtn() {
    return ScaleButton(
      onTap: _handleSave,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.color, widget.color.withOpacity(0.75)],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.save_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'save_lecture'.tr(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String s) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(s)));
  }
}