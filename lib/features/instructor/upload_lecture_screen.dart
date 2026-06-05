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
  List<PlatformFile> _pickedFiles = [];
  List<PlatformFile> _pickedAudios = [];
  bool _isProcessing = false;

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

  Future<void> _pickAudio() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      allowMultiple: true,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final audioExts = [
        'mp3',
        'ogg',
        'wav',
        'm4a',
        'aac',
        'mp4',
        'opus',
        'flac',
        'wma',
        'amr',
        'aiff',
        '3gp',
        '3gpp',
        'webm',
        'mkv',
      ];
      final filtered =
          result.files.where((f) {
            if (f.name.isEmpty) return false;
            final ext = f.name.split('.').last.toLowerCase();
            return audioExts.contains(ext);
          }).toList();

      if (filtered.isNotEmpty) {
        setState(() => _pickedAudios = filtered);
      } else {
        setState(() => _pickedAudios = result.files);
      }
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

  Future<void> _handleGenerateAI() async {
    if (!_validate()) return;
    setState(() => _isProcessing = true);

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

    if (upRes['status'] != 'success') {
      setState(() => _isProcessing = false);
      _snack(upRes['message'] ?? 'upload_failed'.tr());
      return;
    }

    final lectureId = upRes['data']['lecture_id'].toString();
    final lectureTitle = _titleController.text.trim();

    final aiRes = await ApiService.generateAIContent(lectureId);
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (aiRes['status'] == 'success') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => InstructorLectureAIViewScreen(
                lectureId: lectureId,
                lectureTitle: lectureTitle,
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
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildFieldCard(),
                  const SizedBox(height: 18),
                  _buildSectionLabel('PDF / Image', [
                    const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.image_rounded,
                      color: Colors.blue,
                      size: 18,
                    ),
                  ]),
                  _uploadBox(
                    label:
                        _pickedFiles.isEmpty
                            ? 'لم يتم اختيار ملفات بعد'
                            : _pickedFiles.length == 1
                            ? _pickedFiles.first.name
                            : '${_pickedFiles.length} ملفات مختارة',
                    onTap: _pickFile,
                    actionLabel: '+ إضافة',
                    isEmpty: _pickedFiles.isEmpty,
                  ),
                  const SizedBox(height: 16),
                  _buildSectionLabel('الملفات الصوتية', [
                    Icon(Icons.mic_rounded, color: widget.color, size: 18),
                  ]),
                  _uploadBox(
                    label:
                        _pickedAudios.isEmpty
                            ? 'لم يتم اختيار صوتيات بعد'
                            : _pickedAudios.length == 1
                            ? _pickedAudios.first.name
                            : '${_pickedAudios.length} ملفات صوتية',
                    onTap: _pickAudio,
                    actionLabel: '+ إضافة',
                    isEmpty: _pickedAudios.isEmpty,
                  ),
                  const SizedBox(height: 28),
                  if (_isProcessing)
                    _buildProgressCard()
                  else
                    _buildGenerateBtn(),
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
                  'Upload New Lecture',
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
          hintText: 'Lecture Title',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, List<Widget> icons) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ...icons,
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _uploadBox({
    required String label,
    required VoidCallback onTap,
    required String actionLabel,
    required bool isEmpty,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isEmpty ? Colors.grey : getTextColor(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
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
              'generating_ai_content'.tr(),
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
              'Generate AI Summary & Quiz',
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
