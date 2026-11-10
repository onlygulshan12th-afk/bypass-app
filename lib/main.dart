import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const BypassApp());
}

class BypassApp extends StatelessWidget {
  const BypassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bypass Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090B10),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          surface: Color(0xFF121622),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  final String _telegramChannel = "https://t.me/sterniterspro";
  final String _apiBase = "https://altaf-api-maker.base44.app/functions/lookup?tool=shortner-bypass&key=Bypass&q=";

  bool _isLoading = false;
  bool _hasJoinedChannel = false;
  String _result = "";
  double _latency = 0.0;
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _checkChannelStatus();
    _loadHistory();
  }

  Future<void> _checkChannelStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasJoinedChannel = prefs.getBool('joined_channel') ?? false;
    });

    if (!_hasJoinedChannel) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showJoinDialog());
    }
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('bypass_history') ?? [];
    });
  }

  Future<void> _saveHistory(String item) async {
    final prefs = await SharedPreferences.getInstance();
    _history.remove(item);
    _history.insert(0, item);
    if (_history.length > 10) _history.removeLast();
    await prefs.setStringList('bypass_history', _history);
    setState(() {});
  }

  void _showJoinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: Color(0xFF38BDF8)),
            SizedBox(width: 8),
            Text("Channel Join Required", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Tool use karne ke liye official Telegram channel join karein.",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final uri = Uri.parse(_telegramChannel);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text("Join Channel", style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('joined_channel', true);
              setState(() => _hasJoinedChannel = true);
              Navigator.pop(ctx);
            },
            child: const Text("I Have Joined", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _bypass() async {
    final inputUrl = _urlController.text.trim();
    if (inputUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bhai pehle link paste karo!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = "";
    });

    final stopwatch = Stopwatch()..start();

    try {
      final endpoint = Uri.parse("$_apiBase${Uri.encodeComponent(inputUrl)}");
      final response = await http.get(endpoint).timeout(const Duration(seconds: 20));
      stopwatch.stop();

      if (response.statusCode == 200) {
        String finalUrl = "";
        try {
          final data = jsonDecode(response.body);
          finalUrl = data['result'] ?? data['url'] ?? data['destination'] ?? response.body;
        } catch (_) {
          finalUrl = response.body.trim();
        }

        setState(() {
          _result = finalUrl;
          _latency = stopwatch.elapsedMilliseconds / 1000.0;
        });

        _saveHistory(finalUrl);
      } else {
        throw Exception("Server Error ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bypass Failed: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BYPASS PRO", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.telegram, color: Color(0xFF38BDF8)),
            onPressed: () => launchUrl(Uri.parse(_telegramChannel), mode: LaunchMode.externalApplication),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF121622).withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: "Paste shortener link here...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF090B10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.paste, color: Color(0xFF38BDF8)),
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null) {
                            _urlController.text = data!.text!.trim();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isLoading ? null : _bypass,
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("⚡ Bypass Shortener", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF102A24).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Unlocked Destination", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                        Text("${_latency.toStringAsFixed(2)}s", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SelectableText(_result, style: const TextStyle(fontFamily: 'monospace', color: Colors.white)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF38BDF8),
                              side: const BorderSide(color: Color(0xFF38BDF8)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text("Copy"),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _result));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied!")));
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.open_in_browser, size: 16),
                            label: const Text("Open"),
                            onPressed: () => launchUrl(Uri.parse(_result), mode: LaunchMode.externalApplication),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text("RECENT UNLOCKS", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            ..._history.map((link) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF121622),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(link, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16, color: Colors.white38),
                    onPressed: () => Clipboard.setData(ClipboardData(text: link)),
                  )
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
