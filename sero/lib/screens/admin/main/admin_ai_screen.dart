import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/theme.dart';
import '../../../services/api_service.dart';
import '../../ai_chat/ai_chat_screen.dart';
import '../../../services/auth_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class AdminAIScreen extends StatefulWidget {
  const AdminAIScreen({super.key});

  @override
  State<AdminAIScreen> createState() => _AdminAIScreenState();
}

class _AdminAIScreenState extends State<AdminAIScreen> {
  bool _isUploading = false;
  String? _societyId;

  @override
  void initState() {
    super.initState();
    _loadSocietyId();
  }

  Future<void> _loadSocietyId() async {
    final user = await AuthService.getSavedUser();
    if (mounted) {
      setState(() {
        _societyId = user?['society_id'] ?? 'default_society';
      });
    }
  }

  Future<void> _pickAndUpload() async {
    if (_societyId == null) return;
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result != null) {
      // Show Document Type Selection
      if (!mounted) return;
      final docType = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Document Type',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _docTypeTile(
                context,
                'rules',
                'Society Rules & Bylaws',
                Icons.gavel,
              ),
              _docTypeTile(
                context,
                'notice',
                'Official Notice',
                Icons.campaign,
              ),
              _docTypeTile(
                context,
                'policy',
                'Operational Policy',
                Icons.policy,
              ),
              _docTypeTile(
                context,
                'general',
                'General Document',
                Icons.description,
              ),
            ],
          ),
        ),
      );

      if (docType == null) return;

      setState(() => _isUploading = true);

      final fileName = result.files.single.name;

      try {
        // V3.10: Real Ingestion Request
        final response = await ApiService.post('/ai/upload-document', {
          'fileUrl':
              'https://firebasestorage.googleapis.com/v0/b/sero/o/$fileName', // Replace with real storage upload logic
          'fileName': fileName,
          'fileType': result.files.single.extension,
          'documentType': docType,
          'society_id': _societyId,
        });

        if (!mounted) return;

        setState(() => _isUploading = false);

        if (response.statusCode == 202) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Upload successful. Tracking ingestion in real-time.',
              ),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Widget _docTypeTile(
    BuildContext context,
    String type,
    String label,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: kPrimaryGreen),
      title: Text(label, style: GoogleFonts.outfit(fontSize: 14)),
      onTap: () => Navigator.pop(context, type),
    );
  }

  void _exportAuditLogs() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing Audit Log CSV stream...')),
    );

    try {
      // Phase 5: Hardened Audit Export
      final url = '${ApiService.baseUrl}/ai/audit/export';
      final headers = await AuthService.authHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File(
          '${directory.path}/ai_audit_${DateTime.now().millisecondsSinceEpoch}.csv',
        );
        await file.writeAsBytes(response.bodyBytes);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Audit Logs Downloaded: ${file.path.split('/').last}',
            ),
          ),
        );
      } else {
        throw 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'AI Intelligence Admin',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _exportAuditLogs,
            icon: const Icon(
              Icons.file_download_outlined,
              color: kPrimaryGreen,
            ),
            tooltip: 'Export Audit Logs (CSV)',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Storage Policy Banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryGreen, kPrimaryGreen.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Knowledge Base Policy',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Raw documents are stored for 7-30 days and auto-deleted. Indexed data remains in permanent AI memory.',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Upload Action
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InkWell(
                onTap: _isUploading ? null : _pickAndUpload,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: Center(
                    child: _isUploading
                        ? const CircularProgressIndicator(color: kPrimaryGreen)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.cloud_upload_outlined,
                                color: kPrimaryGreen,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Upload Society Bylaws, Rules, or Notices',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                              Text(
                                'PDF, JPG, PNG up to 10MB',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Document List Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Row(
                children: [
                  Text(
                    'INGESTION QUEUE',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF64748B),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.sync, color: Colors.grey, size: 16),
                ],
              ),
            ),
          ),

          // 4. Document List (Real-Time Firestore Stream)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: _societyId == null
                ? const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('ai_jobs')
                        .where('society_id', isEqualTo: _societyId)
                        .orderBy('updated_at', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return SliverToBoxAdapter(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const SliverToBoxAdapter(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final jobs = snapshot.data!.docs;

                      if (jobs.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Text(
                                'No ingestion tasks yet.',
                                style: GoogleFonts.outfit(color: Colors.grey),
                              ),
                            ),
                          ),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final job =
                              jobs[index].data() as Map<String, dynamic>;
                          final status = job['status'] ?? 'processing';
                          final progress = (job['progress'] ?? 0).toDouble();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        job['document_type'] == 'rules'
                                            ? Icons.gavel
                                            : Icons.description_outlined,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            job['file_name'] ??
                                                'Untitled Document',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            '${job['document_type']?.toString().toUpperCase()} • AI V3.10 Ingestion',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _StatusChip(status: status),
                                  ],
                                ),
                                if (status == 'processing' ||
                                    status == 'uploading') ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(100),
                                    child: LinearProgressIndicator(
                                      value: progress / 100,
                                      backgroundColor: const Color(0xFFF1F5F9),
                                      color: kPrimaryGreen,
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                                if (status == 'failed' &&
                                    job['error'] != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    job['error'],
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }, childCount: jobs.length),
                      );
                    },
                  ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AiChatScreen(
                initialMessage:
                    'Check doc indexing progress and suggest notices',
                initialContext: {'screen': 'admin_ai'},
              ),
            ),
          );
        },
        backgroundColor: kPrimaryGreen,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    Color bg = Colors.grey.shade50;

    switch (status.toLowerCase()) {
      case 'indexed':
        color = kPrimaryGreen;
        bg = const Color(0xFFF0FDF4);
        break;
      case 'processing':
      case 'uploading':
        color = Colors.blue;
        bg = const Color(0xFFEFF6FF);
        break;
      case 'failed':
        color = Colors.red;
        bg = const Color(0xFFFEF2F2);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Text(
        status,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
