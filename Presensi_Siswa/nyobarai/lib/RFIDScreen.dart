import 'package:flutter/material.dart';
import 'package:presensiSiswa/models/rfid_recod.dart';
import 'package:presensiSiswa/services/rfid_service.dart';

class RFIDScreen extends StatefulWidget {
  const RFIDScreen({super.key});

  @override
  State<RFIDScreen> createState() => _RFIDScreenState();
}

class _RFIDScreenState extends State<RFIDScreen> {
  bool _loading = true;
  List<RfidRecord> _records = [];
  String? _selectedDate; // YYYY-MM-DD
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate != null ? DateTime.parse(_selectedDate!) : now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked.toIso8601String().substring(0, 10));
      await _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _records = await RfidService.getAbsenGerbang(
        date: _selectedDate,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'hadir':
        return Colors.green;
      case 'terlambat':
        return Colors.orange;
      case 'tidak hadir':
        return Colors.red;
      case 'pulang':
        return Colors.blue;
      case 'belum pulang':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi RFID'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickDate,
            tooltip: 'Pilih tanggal',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nama atau NIS...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Tanggal: $_selectedDate',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? const Center(child: Text('Tidak ada data'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _records.length,
                          itemBuilder: (_, i) {
                            final r = _records[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade200,
                                  child: Text(r.nama.isNotEmpty
                                      ? r.nama[0].toUpperCase()
                                      : '?'),
                                ),
                                title: Text('${r.nama} (${r.kelas})'),
                                subtitle: Text('NIS: ${r.nis}\nTanggal: ${r.tanggal}'),
                                isThreeLine: true,
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Masuk: ${r.jamMasuk ?? '-'}',
                                      style: TextStyle(
                                        color: _statusColor(r.statusMasuk),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Pulang: ${r.jamPulang ?? '-'}',
                                      style: TextStyle(
                                        color: _statusColor(r.statusPulang),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickDate,
        label: const Text('Pilih Tanggal'),
        icon: const Icon(Icons.event),
      ),
    );
  }
}
