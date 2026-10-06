import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DocumentScannerApp());
}

class DocumentScannerApp extends StatelessWidget {
  const DocumentScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Document Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // Deep Indigo / Navy
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
        ),
      ),
      home: const ScannerHomeScreen(),
    );
  }
}

enum ScanOutputType { all, pdfOnly, imagesOnly }

class ScannerHomeScreen extends StatefulWidget {
  const ScannerHomeScreen({super.key});

  @override
  State<ScannerHomeScreen> createState() => _ScannerHomeScreenState();
}

class _ScannerHomeScreenState extends State<ScannerHomeScreen> {
  int _maxPages = 10;
  bool _singlePageMode = false;
  ScanOutputType _outputType = ScanOutputType.all;

  bool _isScanning = false;
  String? _scannedPdfPath;
  List<String> _scannedImagePaths = [];
  String? _statusMessage;

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vui lòng cấp quyền Camera trong Cài đặt thiết bị'),
            action: SnackBarAction(
              label: 'Mở Cài đặt',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      return false;
    }
    return false;
  }

  Future<void> _startScan() async {
    final hasPermission = await _requestCameraPermission();
    if (!hasPermission) return;

    setState(() {
      _isScanning = true;
      _statusMessage = 'Đang khởi động Camera Scanner...';
    });

    final targetPages = _singlePageMode ? 1 : _maxPages;

    try {
      dynamic result;
      final scanner = FlutterDocScanner();

      switch (_outputType) {
        case ScanOutputType.pdfOnly:
          result = await scanner.getScannedDocumentAsPdf(page: targetPages);
          break;
        case ScanOutputType.imagesOnly:
          result = await scanner.getScannedDocumentAsImages(page: targetPages);
          break;
        case ScanOutputType.all:
          result = await scanner.getScanDocuments(page: targetPages);
          break;
      }

      _processScanResult(result);
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi hoặc đã hủy quét: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  void _processScanResult(dynamic result) {
    if (result == null) {
      setState(() {
        _statusMessage = 'Đã hủy phiên quét tài liệu.';
      });
      return;
    }

    String? pdfPath;
    List<String> images = [];

    if (result is Map) {
      // Android / iOS payload formats
      if (result.containsKey('pdfUri') && result['pdfUri'] != null) {
        pdfPath = result['pdfUri'].toString().replaceAll('file://', '');
      }

      if (result.containsKey('images') && result['images'] is List) {
        images = (result['images'] as List)
            .map((e) => e.toString().replaceAll('file://', ''))
            .toList();
      } else if (result.containsKey('Uri') && result['Uri'] is List) {
        images = (result['Uri'] as List)
            .map((e) => e.toString().replaceAll('file://', ''))
            .toList();
      }
    } else if (result is String) {
      if (result.endsWith('.pdf')) {
        pdfPath = result.replaceAll('file://', '');
      } else {
        images.add(result.replaceAll('file://', ''));
      }
    }

    setState(() {
      _scannedPdfPath = pdfPath;
      if (images.isNotEmpty) {
        _scannedImagePaths = images;
      }
      _statusMessage = 'Quét thành công! Đã xử lý trực tiếp trên thiết bị.';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF10B981),
          content: Text('✅ Đã quét tài liệu thành công!'),
        ),
      );
    }
  }

  void _openPdf() async {
    if (_scannedPdfPath != null && File(_scannedPdfPath!).existsSync()) {
      await OpenFilex.open(_scannedPdfPath!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy tệp PDF')),
      );
    }
  }

  void _sharePdf() async {
    if (_scannedPdfPath != null && File(_scannedPdfPath!).existsSync()) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(_scannedPdfPath!)],
          text: 'Tài liệu đã quét (PDF)',
        ),
      );
    }
  }

  void _shareImages() async {
    final validImages = _scannedImagePaths
        .where((p) => File(p).existsSync())
        .map((p) => XFile(p))
        .toList();
    if (validImages.isNotEmpty) {
      await SharePlus.instance.share(
        ShareParams(
          files: validImages,
          text: 'Tài liệu đã quét (Hình ảnh)',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.document_scanner, color: Color(0xFF1E3A8A)),
            SizedBox(width: 8),
            Text(
              'Document Scanner',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFeatureBanner(),
            const SizedBox(height: 16),
            _buildConfigurationCard(),
            const SizedBox(height: 16),
            _buildActionScanButton(),
            const SizedBox(height: 20),
            if (_statusMessage != null) ...[
              _buildStatusAlert(),
              const SizedBox(height: 16),
            ],
            if (_scannedPdfPath != null || _scannedImagePaths.isNotEmpty)
              _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Số hóa tài liệu thông minh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '• Tự động nhận diện 4 góc & căn chỉnh phối cảnh\n'
            '• Chỉnh sửa ảnh: xoay, tăng nét, trắng đen\n'
            '• Xử lý hoàn toàn trên thiết bị (Google ML Kit & VisionKit)',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune, color: Color(0xFF1E3A8A)),
                SizedBox(width: 8),
                Text(
                  'Bước 1: Cấu hình phiên quét',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 24),
            // Chế độ quét nhanh 1 ảnh
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Chế độ quét nhanh 1 ảnh'),
              subtitle: const Text('Chụp tài liệu đơn nhanh chóng'),
              value: _singlePageMode,
              activeThumbColor: const Color(0xFF1E3A8A),
              onChanged: (val) {
                setState(() {
                  _singlePageMode = val;
                });
              },
            ),
            if (!_singlePageMode) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Giới hạn số trang tối đa:'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _maxPages > 1
                            ? () => setState(() => _maxPages--)
                            : null,
                      ),
                      Text(
                        '$_maxPages trang',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _maxPages < 50
                            ? () => setState(() => _maxPages++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Định dạng xuất kết quả:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ScanOutputType>(
              segments: const [
                ButtonSegment(
                  value: ScanOutputType.all,
                  label: Text('Tất cả'),
                  icon: Icon(Icons.file_copy_outlined),
                ),
                ButtonSegment(
                  value: ScanOutputType.pdfOnly,
                  label: Text('Chỉ PDF'),
                  icon: Icon(Icons.picture_as_pdf_outlined),
                ),
                ButtonSegment(
                  value: ScanOutputType.imagesOnly,
                  label: Text('Chỉ Ảnh'),
                  icon: Icon(Icons.image_outlined),
                ),
              ],
              selected: {_outputType},
              onSelectionChanged: (Set<ScanOutputType> newSelection) {
                setState(() {
                  _outputType = newSelection.first;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionScanButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 3,
      ),
      onPressed: _isScanning ? null : _startScan,
      icon: _isScanning
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : const Icon(Icons.camera_alt, size: 24),
      label: Text(
        _isScanning ? 'Đang mở máy quét...' : 'Bắt đầu quét tài liệu',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusAlert() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessage ?? '',
              style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text(
              'Bước 5: Kết quả & Xuất tài liệu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_scannedPdfPath != null) ...[
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            elevation: 1,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFEE2E2),
                child: Icon(Icons.picture_as_pdf, color: Color(0xFFDC2626)),
              ),
              title: const Text('Tệp tài liệu PDF', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                _scannedPdfPath!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Color(0xFF1E3A8A)),
                    tooltip: 'Mở PDF',
                    onPressed: _openPdf,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Color(0xFF1E3A8A)),
                    tooltip: 'Chia sẻ / Lưu',
                    onPressed: _sharePdf,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_scannedImagePaths.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hình ảnh đã quét (${_scannedImagePaths.length} trang):',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextButton.icon(
                onPressed: _shareImages,
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Chia sẻ ảnh'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 170,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _scannedImagePaths.length,
              itemBuilder: (context, index) {
                final imagePath = _scannedImagePaths[index];
                final file = File(imagePath);
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: file.existsSync()
                              ? Image.file(file, fit: BoxFit.cover)
                              : const Center(child: Icon(Icons.broken_image)),
                        ),
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Trang ${index + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
