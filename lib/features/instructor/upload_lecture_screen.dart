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

  bool _isUploading = false;
  bool _isGenerating = false;
  String _statusMessage = '';

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFiles = [..._pickedFiles, ...result.files]);
    }
  }

  Future<void> _pickAudios() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      withData: true,
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final audioExts = ['mp3', 'ogg', 'wav', 'm4a', 'aac', 'mp4'];
      final filtered =
          result.files.where((f) {
            final ext = f.name.split('.').last.toLowerCase();
            return audioExts.contains(ext);
          }).toList();
      if (filtered.isNotEmpty) {
        setState(() => _pickedAudios = [..._pickedAudios, ...filtered]);
      }
    }
  }

  void _removeFile(int index) => setState(() => _pickedFiles.removeAt(index));
  void _removeAudio(int index) => setState(() => _pickedAudios.removeAt(index));

  Future<void> _handleProcess() async {
    if (_titleController.text.trim().isEmpty) {
      _snack('please_enter_title'.tr());
      return;
    }
    if (_pickedFiles.isEmpty && _pickedAudios.isEmpty) {
      _snack('please_upload_first'.tr());
      return;
    }

    setState(() {
      _isUploading = true;
      _statusMessage = 'uploading_file'.tr();
    });

    final firstFile = _pickedFiles.isNotEmpty ? _pickedFiles.first : null;
    final firstAudio = _pickedAudios.isNotEmpty ? _pickedAudios.first : null;

    final upRes = await ApiService.uploadLecture(
      courseId: widget.courseId,
      title: _titleController.text.trim(),
      fileBytes: firstFile?.bytes?.toList(),
      fileName: firstFile?.name,
      audioBytes: firstAudio?.bytes?.toList(),
      audioName: firstAudio?.name,
    );

    if (!mounted) return;

    if (upRes['status'] != 'success') {
      setState(() {
        _isUploading = false;
        _statusMessage = '';
      });
      _snack(upRes['message'] ?? 'upload_failed'.tr());
      return;
    }

    final lectureId = upRes['data']['lecture_id'].toString();

    setState(() {
      _isUploading = false;
      _isGenerating = true;
      _statusMessage = 'generating_ai_content'.tr();
    });

    final aiRes = await ApiService.generateAIContent(lectureId);

    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _statusMessage = '';
    });

    if (aiRes['status'] == 'success') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => InstructorLectureAIViewScreen(
                lectureId: lectureId,
                lectureTitle: _titleController.text.trim(),
                color: widget.color,
              ),
        ),
      );
    } else {
      _snack(aiRes['message'] ?? 'upload_done_ai_failed'.tr());
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildFieldCard(),
                  const SizedBox(height: 18),
                  _buildFilesSection(),
                  const SizedBox(height: 18),
                  _buildAudiosSection(),
                  const SizedBox(height: 22),
                  if (isProcessing) _buildProgressCard(),
                  const SizedBox(height: 12),
                  _buildActionBtn(),
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

  Widget _buildFilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.image_rounded, color: Colors.blue, size: 18),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              'PDF / Image',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _pickFiles,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'إضافة',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_pickedFiles.isEmpty)
          _emptyBox('لم يتم اختيار ملفات بعد')
        else
          Column(
            children:
                _pickedFiles
                    .asMap()
                    .entries
                    .map(
                      (e) => _fileTile(
                        e.value.name,
                        () => _removeFile(e.key),
                        Colors.red,
                      ),
                    )
                    .toList(),
          ),
      ],
    );
  }

  Widget _buildAudiosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.mic_rounded, color: widget.color, size: 18),
            const SizedBox(width: 8),
            Text(
              'الملفات الصوتية',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _pickAudios,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'إضافة',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_pickedAudios.isEmpty)
          _emptyBox('لم يتم اختيار صوتيات بعد')
        else
          Column(
            children:
                _pickedAudios
                    .asMap()
                    .entries
                    .map(
                      (e) => _fileTile(
                        e.value.name,
                        () => _removeAudio(e.key),
                        widget.color,
                      ),
                    )
                    .toList(),
          ),
      ],
    );
  }

  Widget _emptyBox(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: getSecondaryTextColor(context), fontSize: 12),
      ),
    );
  }

  Widget _fileTile(String name, VoidCallback onRemove, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file_rounded, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              color: Colors.red.shade400,
              size: 18,
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
              _statusMessage,
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

  Widget _buildActionBtn() {
    final isProcessing = _isUploading || _isGenerating;
    return ScaleButton(
      onTap: isProcessing ? () {} : _handleProcess,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.color, widget.color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            isProcessing ? 'generating'.tr() : 'generate_ai_content'.tr(),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  void _snack(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }
}
