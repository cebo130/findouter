import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Downloader Files',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const FileListScreen(),
    );
  }
}

class FileListScreen extends StatefulWidget {
  const FileListScreen({super.key});

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  List<FileSystemEntity> _files = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Handle Android runtime permissions
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Storage permission denied.';
          _isLoading = false;
        });
        return;
      }

      // Path to /Download/VideoDownloader
      const targetPath =
          '/storage/emulated/0/Android/media/com.whatsapp/Whatsapp/Media/Whatsapp Images/';
      final directory = Directory(targetPath);

      if (await directory.exists()) {
        final fileList = directory.listSync();
        setState(() {
          _files = fileList;
          _isLoading = false;
        });
      } else {
        // Create directory if it doesn't exist
        await directory.create(recursive: true);
        setState(() {
          _files = [];
          _isLoading = false;
          _errorMessage = 'Folder was empty/created at: $targetPath';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading files: $e';
        _isLoading = false;
      });
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Request permissions depending on Android version
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    var status = await Permission.storage.request();
    if (status.isGranted) return true;

    // For Android 11+ (API level 30+), request Manage External Storage if needed
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }

    // Fallback for Android 13+ specific media formats
    var videoStatus = await Permission.videos.request();
    return videoStatus.isGranted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VideoDownloader Files'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchFiles),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _files.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    if (_files.isEmpty) {
      return const Center(
        child: Text('No files found in Download/VideoDownloader'),
      );
    }

    return ListView.builder(
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final entity = _files[index];
        final name = entity.path.split('/').last;
        final isDir = entity is Directory;

        return ListTile(
          leading: Icon(
            isDir ? Icons.folder : Icons.insert_drive_file,
            color: isDir ? Colors.amber : Colors.blue,
          ),
          title: Text(name),
          subtitle: Text(entity.path),
        );
      },
    );
  }
}
