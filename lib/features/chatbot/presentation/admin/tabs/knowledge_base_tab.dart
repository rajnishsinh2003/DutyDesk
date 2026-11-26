import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/auth_provider.dart';
import '../../../models/chatbot_document.dart';
import '../../../providers/chatbot_admin_provider.dart';
import '../../../services/chatbot_api_service.dart';
import '../../../services/document_upload_service.dart';

class KnowledgeBaseTab extends ConsumerStatefulWidget {
  const KnowledgeBaseTab({super.key});

  @override
  ConsumerState<KnowledgeBaseTab> createState() => _KnowledgeBaseTabState();
}

class _KnowledgeBaseTabState extends ConsumerState<KnowledgeBaseTab> {
  String _search = '';
  String _viewMode = 'docs'; // 'docs' | 'faqs'
  double? _uploadProgress;
  String? _uploadError;

  Future<void> _pickAndUploadFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
    );
    if (files.isEmpty) return;
    final picked = files.first;
    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      setState(() => _uploadError = 'Selected file is empty.');
      return;
    }

    if (!mounted) return;
    final meta = await _showMetadataDialog(initialTitle: picked.name);
    if (meta == null) return;

    final ext = (picked.extension ?? 'txt').toLowerCase();
    final mime = ext == 'pdf'
        ? 'application/pdf'
        : ext == 'docx'
            ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
            : 'text/plain';

    setState(() {
      _uploadProgress = 0.01;
      _uploadError = null;
    });

    try {
      final auth = ref.read(authProvider);
      await DocumentUploadService.uploadFileDocument(
        fileName: picked.name,
        bytes: bytes,
        mimeType: mime,
        title: meta['title'] as String,
        description: meta['description'] as String,
        category: meta['category'] as String,
        audience: meta['audience'] as List<String>,
        uploadedBy: auth.userId ?? 'admin',
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );
      if (mounted) {
        setState(() => _uploadProgress = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded! Processing & chunking started.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadProgress = null;
          _uploadError = 'Upload failed: $e';
        });
      }
    }
  }

  Future<void> _showPasteTextDialog() async {
    final titleCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'Guidelines');
    final textCtrl = TextEditingController();
    final audience = <String>{'public', 'invigilator'};

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Paste Text Knowledge'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title *'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: catCtrl,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: ['public', 'invigilator', 'admin'].map((aud) {
                      return FilterChip(
                        label: Text(aud),
                        selected: audience.contains(aud),
                        onSelected: (sel) => setDlg(() {
                          sel ? audience.add(aud) : audience.remove(aud);
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: textCtrl,
                    maxLines: 7,
                    decoration: const InputDecoration(
                      labelText: 'Content *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save & Index')),
          ],
        ),
      ),
    );

    if (ok == true &&
        titleCtrl.text.trim().isNotEmpty &&
        textCtrl.text.trim().isNotEmpty) {
      setState(() => _uploadError = null);
      try {
        await DocumentUploadService.createTextDocument(
          title: titleCtrl.text,
          description: '',
          category: catCtrl.text,
          audience: audience.isEmpty ? ['public'] : audience.toList(),
          rawText: textCtrl.text,
          uploadedBy: ref.read(authProvider).userId ?? 'admin',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document saved & indexed!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) setState(() => _uploadError = 'Save failed: $e');
      }
    }
  }

  Future<void> _showAddFaqDialog() async {
    final qCtrl = TextEditingController();
    final aCtrl = TextEditingController();
    String lang = 'en';
    final audience = <String>{'public', 'invigilator'};

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Add Official FAQ Pair'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: qCtrl,
                    decoration: const InputDecoration(labelText: 'Question *'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: aCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Approved Answer *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: lang,
                    decoration: const InputDecoration(labelText: 'Language'),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                      DropdownMenuItem(value: 'gu', child: Text('Gujarati')),
                    ],
                    onChanged: (v) => setDlg(() => lang = v ?? 'en'),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: ['public', 'invigilator', 'admin'].map((aud) {
                      return FilterChip(
                        label: Text(aud),
                        selected: audience.contains(aud),
                        onSelected: (sel) => setDlg(() {
                          sel ? audience.add(aud) : audience.remove(aud);
                        }),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save FAQ')),
          ],
        ),
      ),
    );

    if (ok == true &&
        qCtrl.text.trim().isNotEmpty &&
        aCtrl.text.trim().isNotEmpty) {
      setState(() => _uploadError = null);
      try {
        await ref.read(chatbotFaqsProvider.notifier).addFaq(
              question: qCtrl.text,
              answer: aCtrl.text,
              audience: audience.isEmpty ? ['public'] : audience.toList(),
              language: lang,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('FAQ saved & embedded!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) setState(() => _uploadError = 'FAQ save failed: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> _showMetadataDialog({
    required String initialTitle,
    String initialDesc = '',
    String initialCat = 'Guidelines',
    List<String> initialAudience = const ['public', 'invigilator'],
  }) async {
    final titleCtrl = TextEditingController(text: initialTitle);
    final descCtrl = TextEditingController(text: initialDesc);
    final catCtrl = TextEditingController(text: initialCat);
    final audience = Set<String>.from(initialAudience);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Document Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title *')),
              const SizedBox(height: 8),
              TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 8),
              TextField(
                  controller: catCtrl,
                  decoration: const InputDecoration(labelText: 'Category')),
              const SizedBox(height: 10),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Audience:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Wrap(
                spacing: 6,
                children: ['public', 'invigilator', 'admin'].map((aud) {
                  return FilterChip(
                    label: Text(aud),
                    selected: audience.contains(aud),
                    onSelected: (sel) => setDlg(() {
                      sel ? audience.add(aud) : audience.remove(aud);
                    }),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Continue')),
          ],
        ),
      ),
    );

    if (ok != true) return null;
    return {
      'title': titleCtrl.text.trim().isEmpty ? initialTitle : titleCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'category': catCtrl.text.trim().isEmpty ? 'General' : catCtrl.text.trim(),
      'audience': audience.isEmpty ? ['public'] : audience.toList(),
    };
  }

  void _viewChunks(ChatbotDocument doc) async {
    final chunks = await fetchDocumentChunks(doc.id);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Chunks: ${doc.title} (${chunks.length})'),
        content: SizedBox(
          width: 520,
          height: 400,
          child: chunks.isEmpty
              ? const Center(child: Text('No chunks generated yet.'))
              : ListView.separated(
                  itemCount: chunks.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) => ListTile(
                    title: Text('Chunk #${chunks[i].index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: SelectableText(chunks[i].text,
                        style: const TextStyle(fontSize: 12)),
                  ),
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(chatbotDocumentsProvider);
    final faqs = ref.watch(chatbotFaqsProvider);
    const brandColor = Color(0xFF007A87);

    final filteredDocs = docs
        .where((d) =>
            d.title.toLowerCase().contains(_search.toLowerCase()) ||
            d.category.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    final filteredFaqs = faqs
        .where((f) =>
            f.question.toLowerCase().contains(_search.toLowerCase()) ||
            f.answer.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        foregroundColor: Colors.white),
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: const Text('Upload PDF/DOCX/TXT'),
                    onPressed: _uploadProgress != null ? null : _pickAndUploadFile,
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.note_add_outlined, size: 18),
                    label: const Text('Paste Text'),
                    onPressed: _showPasteTextDialog,
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.quiz_outlined, size: 18),
                    label: const Text('Add FAQ'),
                    onPressed: _showAddFaqDialog,
                  ),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                          value: 'docs', label: Text('Docs (${docs.length})')),
                      ButtonSegment(
                          value: 'faqs', label: Text('FAQs (${faqs.length})')),
                    ],
                    selected: {_viewMode},
                    onSelectionChanged: (s) =>
                        setState(() => _viewMode = s.first),
                  ),
                ],
              ),
              if (_uploadProgress != null) ...[
                const SizedBox(height: 10),
                LinearProgressIndicator(value: _uploadProgress, color: brandColor),
              ],
              if (_uploadError != null) ...[
                const SizedBox(height: 8),
                Text(_uploadError!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search documents or FAQs...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: _viewMode == 'docs'
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: filteredDocs.length,
                  itemBuilder: (ctx, i) {
                    final doc = filteredDocs[i];
                    final statusColor = doc.status == 'ready'
                        ? Colors.green
                        : doc.status == 'failed'
                            ? Colors.red
                            : Colors.orange;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(doc.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.5)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    doc.status.toUpperCase(),
                                    style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10),
                                  ),
                                ),
                                Switch(
                                  value: doc.enabled,
                                  onChanged: (val) => ref
                                      .read(chatbotDocumentsProvider.notifier)
                                      .toggleEnabled(doc.id, val),
                                ),
                              ],
                            ),
                            Text(
                              '${doc.category} • ${doc.chunkCount} chunks • Audience: ${doc.audience.join(', ')}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            if (doc.error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Error: ${doc.error}',
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 11.5)),
                              ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.visibility_outlined,
                                      size: 15),
                                  label: const Text('Chunks'),
                                  onPressed: () => _viewChunks(doc),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.edit_outlined, size: 15),
                                  label: const Text('Edit'),
                                  onPressed: () async {
                                    final meta = await _showMetadataDialog(
                                      initialTitle: doc.title,
                                      initialDesc: doc.description,
                                      initialCat: doc.category,
                                      initialAudience: doc.audience,
                                    );
                                    if (meta != null) {
                                      await ref
                                          .read(chatbotDocumentsProvider.notifier)
                                          .updateMetadata(
                                            docId: doc.id,
                                            title: meta['title'] as String,
                                            description:
                                                meta['description'] as String,
                                            category: meta['category'] as String,
                                            audience:
                                                meta['audience'] as List<String>,
                                          );
                                    }
                                  },
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.refresh, size: 15),
                                  label: const Text('Re-index'),
                                  onPressed: () async {
                                    await ChatbotApiService.reindexDocument(
                                        doc.id);
                                  },
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 15, color: Colors.red),
                                  label: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                  onPressed: () async {
                                    await ChatbotApiService.deleteDocument(
                                        doc.id);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: filteredFaqs.length,
                  itemBuilder: (ctx, i) {
                    final faq = filteredFaqs[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(faq.question,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${faq.answer}\n[${faq.language.toUpperCase()} • ${faq.audience.join(', ')}]',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: faq.enabled,
                              onChanged: (v) => ref
                                  .read(chatbotFaqsProvider.notifier)
                                  .toggleFaq(faq.id, v),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => ref
                                  .read(chatbotFaqsProvider.notifier)
                                  .deleteFaq(faq.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
