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
  State<UploadLectureScreen> createState() => _UploadLectureScreenState();
}

class _UploadLectureScreenState extends State<UploadLectureScreen> {
  final _titleController = TextEditingController();

  // ✅ قوائم لدعم ملفات متعددة
  List<PlatformFile> _pickedFiles = [];
  List<PlatformFile> _pickedAudios = [];

  bool _isUploading = false;
  bool _isGenerating = false;

  String? _savedLectureId;
  String? _savedLectureTitle;

  // ✅ اختيار PDF أو صورة (متعدد)
  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFiles = result.files);
    }
  }

  // ✅ اختيار صوت متعدد
  Future<void> _pickAudio() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'ogg', 'wav', 'm4a', 'aac'],
      allowMultiple: true,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedAudios = result.files);
    }
  }

  bool _validate() {
    if (_titleController.text.trim().isEmpty) {
      _snack('please_enter_title'.tr());
      return false;
    }
    if (_pickedFiles.isEmpty && _pickedAudios.isEmpty) {
      _snack('please_upload_first'.tr());
      return false;
    }
    return true;
  }

  Future<void> _handleSave() async {
    if (!_validate()) return;
    setState(() => _isUploading = true);

    final upRes = await ApiService.uploadLecture(
      courseId: widget.courseId,
      title: _titleController.text.trim(),
      fileBytes:
          _pickedFiles.isNotEmpty ? _pickedFiles.first.bytes?.toList() : null,
      fileName: _pickedFiles.isNotEmpty ? _pickedFiles.first.name : null,
      audioBytes:
          _pickedAudios.isNotEmpty ? _pickedAudios.first.bytes?.toList() : null,
      audioName: _pickedAudios.isNotEmpty ? _pickedAudios.first.name : null,
    );

    if (!mounted) return;
    setState(() => _isUploading = false);

    if (upRes['status'] == 'success') {
      setState(() {
        _savedLectureId = upRes['data']['lecture_id'].toString();
        _savedLectureTitle = _titleController.text.trim();
      });
      _snack('lecture_saved_successfully'.tr());
    } else {
      _snack(upRes['message'] ?? 'upload_failed'.tr());
    }
  }

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
          builder:
              (_) => InstructorLectureAIViewScreen(
                lectureId: _savedLectureId!,
                lectureTitle: _savedLectureTitle ?? '',
                color: widget.color,
              ),
        ),
      );
    } else {
      _snack(aiRes['message'] ?? 'upload_done_ai_failed'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaved = _savedLectureId != null;
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
                  if (!isSaved) ...[
                    _buildFieldCard(),
                    const SizedBox(height: 18),
                    _buildUploadSection(),
                    const SizedBox(height: 22),
                  ],
                  if (isProcessing) ...[
                    _buildProgressCard(),
                    const SizedBox(height: 16),
                  ],
                  if (!isSaved && !isProcessing) _buildSaveBtn(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
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
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
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
                Text(
                  widget.courseTitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
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
        // ✅ PDF + صورة مع بعض
        _uploadTile(
          icons: [
            Icon(Icons.picture_as_pdf, color: Colors.red, size: 22),
            const SizedBox(width: 6),
            Icon(Icons.image_rounded, color: Colors.blue, size: 22),
          ],
          label:
              _pickedFiles.isNotEmpty
                  ? _pickedFiles.length == 1
                      ? _pickedFiles.first.name
                      : '${_pickedFiles.length} ملفات مختارة'
                  : 'PDF / Image',
          onTap: _pickFile,
          actionLabel: _pickedFiles.isNotEmpty ? 'change'.tr() : '+ إضافة',
        ),
        const SizedBox(height: 10),
        // ✅ الملفات الصوتية
        _uploadTile(
          icons: [Icon(Icons.mic_rounded, color: widget.color, size: 22)],
          label:
              _pickedAudios.isNotEmpty
                  ? _pickedAudios.length == 1
                      ? _pickedAudios.first.name
                      : '${_pickedAudios.length} ملفات صوتية'
                  : 'الملفات الصوتية',
          onTap: _pickAudio,
          actionLabel: _pickedAudios.isNotEmpty ? 'change'.tr() : '+ إضافة',
        ),
        // ✅ عرض قائمة الملفات المختارة
        if (_pickedFiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          _filesList(_pickedFiles, Colors.red),
        ],
        if (_pickedAudios.isNotEmpty) ...[
          const SizedBox(height: 8),
          _filesList(_pickedAudios, widget.color),
        ],
      ],
    );
  }

  Widget _filesList(List<PlatformFile> files, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children:
            files
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: color, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            f.name,
                            style: TextStyle(fontSize: 11, color: color),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _uploadTile({
    required List<Widget> icons,
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
        leading: Row(mainAxisSize: MainAxisSize.min, children: icons),
        title: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        trailing: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
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
              color: widget.color,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _isUploading
                  ? 'uploading_file'.tr()
                  : 'generating_ai_content'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 52),
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
        ],
      ),
    );
  }

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
            const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 20,
            ),
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

  Widget _buildBackBtn() {
    return ScaleButton(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_back_rounded, color: Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(
              'back_to_lectures'.tr(),
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

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
            const Icon(Icons.save_rounded, color: Colors.white, size: 20),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }
}
