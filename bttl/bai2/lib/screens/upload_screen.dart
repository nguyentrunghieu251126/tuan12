import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

const Color kBlue = Color(0xFF42B4F5);

class UploadItem {
  final String name;
  final int size;
  final Reference ref;
  final File? file;
  UploadTask? task;
  StreamSubscription<TaskSnapshot>? subscription;
  double progress;
  TaskState state;
  String? downloadUrl;

  UploadItem({
    required this.name,
    required this.size,
    required this.ref,
    this.file,
    this.task,
    this.progress = 0,
    this.state = TaskState.running,
  });
}

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  final Logger _logger = Logger();
  final List<UploadItem> _items = [];
  static const String _folder = 'uploads';
  bool _editMode = false;
  bool _loadingList = true;

  @override
  void initState() {
    super.initState();
    _loadUploadedFiles();
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.subscription?.cancel();
    }
    super.dispose();
  }

  Future<void> _loadUploadedFiles() async {
    try {
      final ListResult result = await _firebaseStorage.ref(_folder).listAll();
      final List<UploadItem> loaded = [];
      for (final ref in result.items) {
        final FullMetadata meta = await ref.getMetadata();
        loaded.add(UploadItem(
          name: meta.customMetadata?['originalName'] ?? ref.name,
          size: meta.size ?? 0,
          ref: ref,
          progress: 1,
          state: TaskState.success,
        ));
      }
      if (!mounted) return;
      setState(() => _items.addAll(loaded.reversed));
    } catch (e) {
      _logger.e('Error loading files: $e');
    } finally {
      if (mounted) setState(() => _loadingList = false);
    }
  }

  Future<void> _chooseFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;
    for (final f in result.files) {
      if (f.path != null) _upload(File(f.path!), f.name);
    }
  }

  void _upload(File file, String originalName) {
    String ext = path.extension(file.path);
    final storageRef = _firebaseStorage
        .ref(_folder)
        .child('file-${DateTime.now().microsecondsSinceEpoch}$ext');
    _logger.i('Ref path: ${storageRef.fullPath}');

    final UploadTask task = storageRef.putFile(
      file,
      SettableMetadata(customMetadata: {'originalName': originalName}),
    );

    final item = UploadItem(
      name: originalName,
      size: file.lengthSync(),
      ref: storageRef,
      file: file,
      task: task,
    );
    setState(() => _items.insert(0, item));

    item.subscription = task.snapshotEvents.listen(
      (TaskSnapshot taskSnapshot) async {
        if (!mounted) return;
        final double progress = taskSnapshot.totalBytes > 0
            ? taskSnapshot.bytesTransferred / taskSnapshot.totalBytes
            : 0;
        setState(() {
          item.state = taskSnapshot.state;
          item.progress = progress;
        });

        switch (taskSnapshot.state) {
          case TaskState.running:
            _logger.i(
                'Upload is ${(progress * 100).toStringAsFixed(0)}% complete.');
            break;
          case TaskState.paused:
            _logger.i('Upload is paused.');
            break;
          case TaskState.canceled:
            _logger.i('Upload was canceled');
            break;
          case TaskState.error:
            _logger.e('Upload error');
            break;
          case TaskState.success:
            _logger.i('Upload done');
            final downloadURL = await taskSnapshot.ref.getDownloadURL();
            _logger.i('File uploaded, download URL: $downloadURL');
            if (mounted) setState(() => item.downloadUrl = downloadURL);
            break;
        }
      },
      onError: (Object e) {
        _logger.e('Error uploading file: $e');
        if (!mounted) return;
        setState(() {
          item.state = (e is FirebaseException && e.code == 'canceled')
              ? TaskState.canceled
              : TaskState.error;
        });
      },
    );
  }

  Future<void> _pause(UploadItem item) async {
    final bool paused = await item.task?.pause() ?? false;
    _logger.i('Paused: $paused');
  }

  Future<void> _resume(UploadItem item) async {
    final bool resumed = await item.task?.resume() ?? false;
    _logger.i('Resumed: $resumed');
  }

  Future<void> _cancel(UploadItem item) async {
    final bool canceled = await item.task?.cancel() ?? false;
    _logger.i('Canceled: $canceled');
  }

  void _retry(UploadItem item) {
    item.subscription?.cancel();
    setState(() => _items.remove(item));
    _upload(item.file!, item.name);
  }

  Future<void> _delete(UploadItem item) async {
    if (item.state == TaskState.running || item.state == TaskState.paused) {
      await item.task?.cancel();
    }
    await item.subscription?.cancel();
    if (item.state == TaskState.success) {
      try {
        await item.ref.delete();
        _logger.i('Deleted ${item.ref.fullPath}');
      } catch (e) {
        _logger.e('Error deleting file: $e');
      }
    }
    if (mounted) setState(() => _items.remove(item));
  }

  Future<void> _showUrl(UploadItem item) async {
    if (item.state != TaskState.success) return;
    item.downloadUrl ??= await item.ref.getDownloadURL();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.name),
        content: SelectableText(item.downloadUrl!),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: kBlue),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Upload', style: TextStyle(color: Colors.grey)),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _editMode = !_editMode),
              child: Text(_editMode ? 'Done' : 'Edit',
                  style: const TextStyle(
                      color: kBlue, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _loadingList
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _items.length,
                  itemBuilder: (_, i) => _buildItem(_items[i]),
                ),
      bottomNavigationBar: SafeArea(
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: kBlue,
              shape: const RoundedRectangleBorder(),
            ),
            onPressed: _chooseFile,
            child: const Text('Choose File', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 180,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _paper(-0.4, const Offset(-40, -20), Colors.amber),
                _paper(0.3, const Offset(40, -25), Colors.pinkAccent),
                _paper(0.0, const Offset(0, -40), Colors.lightBlueAccent),
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF7FD3FF), kBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.cloud_upload,
                      color: Colors.white, size: 52),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Chưa có file nào.\nNhấn "Choose File" để tải lên',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _paper(double angle, Offset offset, Color color) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 50,
          height: 60,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(UploadItem item) {
    final String ext =
        path.extension(item.name).replaceFirst('.', '').toUpperCase();
    final Color extColor = _extColor(ext);
    final Color stateColor = _stateColor(item.state);

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showUrl(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: extColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ext.isEmpty
                      ? 'FILE'
                      : (ext.length > 4 ? ext.substring(0, 4) : ext),
                  style: TextStyle(
                      color: extColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Text(_formatSize(item.size),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: item.progress,
                        minHeight: 6,
                        color: stateColor,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_stateText(item.state)} • ${(item.progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 12, color: stateColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              ..._buildActions(item),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions(UploadItem item) {
    if (_editMode) {
      return [
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          tooltip: 'Xóa',
          onPressed: () => _delete(item),
        ),
      ];
    }
    switch (item.state) {
      case TaskState.running:
        return [
          IconButton(
            icon: const Icon(Icons.pause, color: kBlue),
            tooltip: 'Tạm dừng',
            onPressed: () => _pause(item),
          ),
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.red),
            tooltip: 'Dừng',
            onPressed: () => _cancel(item),
          ),
        ];
      case TaskState.paused:
        return [
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.amber),
            tooltip: 'Tiếp tục',
            onPressed: () => _resume(item),
          ),
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.red),
            tooltip: 'Dừng',
            onPressed: () => _cancel(item),
          ),
        ];
      case TaskState.success:
        return [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.check_circle, color: Colors.green),
          ),
        ];
      case TaskState.canceled:
      case TaskState.error:
        return [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Upload lại',
            onPressed: item.file == null ? null : () => _retry(item),
          ),
        ];
    }
  }

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)}KB';
    return '${bytes}B';
  }

  String _stateText(TaskState state) {
    switch (state) {
      case TaskState.running:
        return 'Đang tải';
      case TaskState.paused:
        return 'Tạm dừng';
      case TaskState.success:
        return 'Hoàn tất';
      case TaskState.canceled:
        return 'Đã hủy';
      case TaskState.error:
        return 'Lỗi';
    }
  }

  Color _stateColor(TaskState state) {
    switch (state) {
      case TaskState.running:
        return kBlue;
      case TaskState.paused:
        return Colors.amber;
      case TaskState.success:
        return Colors.green;
      case TaskState.canceled:
      case TaskState.error:
        return Colors.red;
    }
  }

  Color _extColor(String ext) {
    switch (ext) {
      case 'JPG':
      case 'JPEG':
      case 'PNG':
      case 'GIF':
        return Colors.purple;
      case 'PDF':
        return Colors.red;
      case 'DOC':
      case 'DOCX':
        return Colors.blue;
      case 'MP4':
      case 'MP3':
        return Colors.orange;
      default:
        return Colors.indigo;
    }
  }
}
